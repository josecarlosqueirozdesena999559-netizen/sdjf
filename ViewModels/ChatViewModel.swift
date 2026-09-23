import Foundation
import Supabase
import Storage
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isTyping: Bool = false
    @Published var otherUserOnline: Bool = false
    @Published var lastSeen: Date? = nil
    
    let conversation: Conversation
    let currentUser: User
    private var channel: RealtimeChannelV2?
    private var pollingTask: Task<Void, Never>?
    private var activeConversationID: UUID?
    private var typingTimer: Timer?
    
    init(conversation: Conversation, currentUser: User) {
        self.conversation = conversation
        self.currentUser = currentUser
        
        Task { await prepareChat() }
    }
    
    deinit {
        pollingTask?.cancel()
        let chan = self.channel
        Task {
            await chan?.unsubscribe()
        }
    }
    
    private var conversationID: UUID { activeConversationID ?? conversation.id }

    private func prepareChat() async {
        await resolveConversation()
        await fetchMessages()
        await setupRealtime()
        startPollingFallback()
    }

    private func resolveConversation() async {
        struct ProductOwner: Decodable { let seller_id: UUID }
        struct ExistingConversation: Decodable { let id: UUID }
        struct NewConversation: Encodable {
            let id: UUID
            let buyer_id: UUID
            let seller_id: UUID
            let product_id: UUID
        }

        do {
            let owner: ProductOwner = try await supabase.database.from("products")
                .select("seller_id").eq("id", value: conversation.productId).single().execute().value
            let buyerID = owner.seller_id == currentUser.id ? conversation.participantId : currentUser.id
            let existing: [ExistingConversation] = try await supabase.database.from("conversations")
                .select("id")
                .eq("product_id", value: conversation.productId)
                .eq("buyer_id", value: buyerID)
                .eq("seller_id", value: owner.seller_id)
                .limit(1)
                .execute()
                .value

            if let found = existing.first {
                activeConversationID = found.id
            } else {
                let newID = UUID()
                try await supabase.database.from("conversations")
                    .insert(NewConversation(id: newID, buyer_id: buyerID, seller_id: owner.seller_id, product_id: conversation.productId))
                    .execute()
                activeConversationID = newID
            }
        } catch {
            // Mantém o identificador recebido para não bloquear a tela caso a rede falhe.
            print("Erro ao preparar conversa: \(error)")
        }
    }

    private func startPollingFallback() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard let self, !Task.isCancelled else { return }
                await self.fetchMessages()
            }
        }
    }
    func fetchMessages() async {
        do {
            struct SupabaseMessage: Codable {
                let id: UUID
                let sender_id: UUID
                let text: String
                let media_url: String?
                let is_read: Bool
                let created_at: Date
            }
            let sbMessages: [SupabaseMessage] = try await supabase.database
                .from("messages")
                .select()
                .eq("conversation_id", value: conversationID)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            self.messages = sbMessages.map { sb in
                Message(
                    id: sb.id,
                    senderId: sb.sender_id,
                    receiverId: sb.sender_id == conversation.participantId ? self.currentUser.id : conversation.participantId,
                    text: sb.text,
                    imageName: sb.media_url,
                    timestamp: sb.created_at,
                    isRead: sb.is_read
                )
            }
            
            // Mark unread messages as read
            await markAsRead()
            
        } catch {
            print("Error fetching messages: \(error)")
        }
    }
    
    func setupRealtime() async {
        let roomName = "room_\(conversationID.uuidString)"
        self.channel = await supabase.realtimeV2.channel(roomName) { config in
            config.presence.key = currentUser.id.uuidString
            config.broadcast.acknowledgeBroadcasts = true
        }
        
        guard let channel = self.channel else { return }
        
        // Listen for new messages via Postgres Changes
        let insertions = await channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages",
            filter: "conversation_id=eq.\(conversationID.uuidString)"
        )
        
        // Listen for updates (e.g. is_read)
        let updates = await channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "messages",
            filter: "conversation_id=eq.\(conversationID.uuidString)"
        )
        
        await channel.subscribe()
        
        // Track presence
        do {
            try await channel.track(["user_id": currentUser.id.uuidString, "status": "online"])
        } catch {
            print("Error tracking presence: \(error)")
        }
        
        // Listen for presence changes
        Task {
            struct PresencePayload: Codable {
                let user_id: String
                let status: String
            }
            var onlineUsers: Set<String> = []
            
            for await action in await channel.presenceChange() {
                do {
                    let joins = try action.decodeJoins(as: PresencePayload.self)
                    let leaves = try action.decodeLeaves(as: PresencePayload.self)
                    
                    for p in joins {
                        onlineUsers.insert(p.user_id)
                    }
                    for p in leaves {
                        onlineUsers.remove(p.user_id)
                    }
                    
                    Task { @MainActor in
                        self.otherUserOnline = onlineUsers.contains(self.conversation.participantId.uuidString)
                        if !self.otherUserOnline {
                            self.lastSeen = Date() // Approximate
                        }
                    }
                } catch {
                    print("Error decoding presence: \(error)")
                }
            }
        }
        
        // Listen for typing broadcast
        Task {
            let typingEvents = await channel.broadcast(event: "typing")
            for await payload in typingEvents {
                if let userId = payload["user_id"]?.stringValue, userId != self.currentUser.id.uuidString {
                    self.isTyping = true
                    
                    self.typingTimer?.invalidate()
                    self.typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                        Task { @MainActor in self.isTyping = false }
                    }
                }
            }
        }
        
        Task {
            for await insert in insertions {
                do {
                    struct MsgPayload: Codable {
                        let id: UUID
                        let sender_id: UUID
                        let text: String
                        let media_url: String?
                        let is_read: Bool
                        let created_at: String
                    }
                    let decoded = try insert.decodeRecord(decoder: JSONDecoder()) as MsgPayload
                    
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    let date = formatter.date(from: decoded.created_at) ?? Date()
                    
                    let newMsg = Message(
                        id: decoded.id,
                        senderId: decoded.sender_id,
                        receiverId: decoded.sender_id == self.conversation.participantId ? self.currentUser.id : self.conversation.participantId,
                        text: decoded.text,
                        imageName: decoded.media_url,
                        timestamp: date,
                        isRead: decoded.is_read
                    )
                    
                    if !self.messages.contains(where: { $0.id == newMsg.id }) {
                        self.messages.append(newMsg)
                        // If we are receiving, mark as read
                        if newMsg.senderId != self.currentUser.id {
                            await self.markAsRead()
                        }
                    }
                } catch {
                    print("Error decoding insert: \(error)")
                }
            }
        }
        
        Task {
            for await update in updates {
                do {
                    struct MsgPayload: Codable {
                        let id: UUID
                        let is_read: Bool
                    }
                    let decoded = try update.decodeRecord(decoder: JSONDecoder()) as MsgPayload
                    if let idx = self.messages.firstIndex(where: { $0.id == decoded.id }) {
                        self.messages[idx].isRead = decoded.is_read
                    }
                } catch {
                    print("Error decoding update: \(error)")
                }
            }
        }
    }
    
    func sendMessage(text: String, mediaUrl: String? = nil, mediaType: String? = nil) async {
        let msgId = UUID()
        let newMsg = Message(
            id: msgId,
            senderId: currentUser.id,
            receiverId: conversation.participantId,
            text: text,
            imageName: mediaUrl,
            timestamp: Date(),
            isRead: false
        )
        self.messages.append(newMsg) // Optimistic UI
        
        struct MsgInsert: Codable {
            let id: UUID
            let conversation_id: UUID
            let sender_id: UUID
            let text: String
            let media_url: String?
            let is_read: Bool
        }
        let insertData = MsgInsert(
            id: msgId,
            conversation_id: conversationID,
            sender_id: currentUser.id,
            text: text,
            media_url: mediaUrl,
            is_read: false
        )
        
        do {
            struct ProductOwner: Codable { let seller_id: UUID }
            struct ConversationInsert: Codable { let id: UUID; let buyer_id: UUID; let seller_id: UUID; let product_id: UUID }
            let owner: ProductOwner = try await supabase.database.from("products")
                .select("seller_id").eq("id", value: conversation.productId).single().execute().value
            let buyerId = owner.seller_id == currentUser.id ? conversation.participantId : currentUser.id
            try await supabase.database.from("conversations")
                .upsert(ConversationInsert(id: conversationID, buyer_id: buyerId, seller_id: owner.seller_id, product_id: conversation.productId), onConflict: "id")
                .execute()
            try await supabase.database
                .from("messages")
                .insert(insertData)
                .execute()
        } catch {
            print("Error sending message: \(error)")
            self.messages.removeAll(where: { $0.id == msgId })
        }
    }
    
    func sendAudio(fileURL: URL) async {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let path = "\(currentUser.id.uuidString)/\(UUID().uuidString).m4a"
        do {
            try await supabase.storage.from("chat-media").upload(path: path, file: data, options: FileOptions(contentType: "audio/mp4"))
            await sendMessage(text: "🎤 Mensagem de voz", mediaUrl: path, mediaType: "audio")
        } catch {
            print("Error uploading audio: \(error)")
        }
    }
    func sendTypingEvent() {
        guard let channel = self.channel else { return }
        Task {
            do {
                try await channel.broadcast(event: "typing", message: ["user_id": currentUser.id.uuidString])
            } catch {
                print("Broadcast error: \(error)")
            }
        }
    }
    
    func markAsRead() async {
        do {

            try await supabase.database
                .from("messages")
                .update(["is_read": true])
                .eq("conversation_id", value: conversationID)
                .eq("sender_id", value: conversation.participantId)
                .eq("is_read", value: false)
                .execute()
        } catch {
            print("Error marking as read: \(error)")
        }
    }
}
