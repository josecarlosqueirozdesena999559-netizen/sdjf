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
        await fetchParticipantStatus()
        await fetchMessages()
        await setupRealtime()
        startPollingFallback()
    }
    
    private func startPollingFallback() {
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if Task.isCancelled { break }
                await smartFetchMessages()
                await fetchParticipantStatus()
            }
        }
    }
    
    private func smartFetchMessages() async {
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
            
            await MainActor.run {
                for sb in sbMessages {
                    if let index = self.messages.firstIndex(where: { $0.id == sb.id }) {
                        self.messages[index].isRead = sb.is_read
                    } else {
                        let message = Message(
                            id: sb.id,
                            senderId: sb.sender_id,
                            receiverId: sb.sender_id == self.conversation.participantId ? self.currentUser.id : self.conversation.participantId,
                            text: sb.text,
                            imageName: sb.media_url,
                            timestamp: sb.created_at,
                            isRead: sb.is_read
                        )
                        self.messages.append(message)
                        if message.senderId != self.currentUser.id {
                            Task { await self.markAsRead() }
                        }
                    }
                }
            }
        } catch {
            print("Erro no smartFetchMessages: \(error)")
        }
    }
    
    private func fetchParticipantStatus() async {
        do {
            struct ProfileStatus: Codable {
                let is_online: Bool?
                let last_seen: String?
            }
            let status: ProfileStatus = try await supabase.database
                .from("profiles")
                .select("is_online, last_seen")
                .eq("id", value: conversation.participantId.uuidString)
                .single()
                .execute()
                .value
            
            await MainActor.run {
                self.otherUserOnline = status.is_online ?? false
                if let lastSeenStr = status.last_seen {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    self.lastSeen = formatter.date(from: lastSeenStr)
                }
            }
        } catch {
            print("Erro status participante: $error")
        }
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
            // MantÃƒÂ©m o identificador recebido para nÃƒÂ£o bloquear a tela caso a rede falhe.
            print("Erro ao preparar conversa: \(error)")
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
        guard let channel else { return }

        let insertions = await channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages",
            filter: "conversation_id=eq.\(conversationID.uuidString)"
        )
        let updates = await channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "messages",
            filter: "conversation_id=eq.\(conversationID.uuidString)"
        )

        // Registra todos os listeners antes da assinatura para nÃƒÂ£o perder o estado inicial.
        _ = await channel.presenceChange()
        let typingEvents = await channel.broadcast(event: "typing")

                let profilesUpdate = await channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "profiles",
            filter: "id=eq.\(conversation.participantId.uuidString)"
        )
        
        Task {
            for await update in profilesUpdate {
                do {
                    struct ProfileUpdate: Codable {
                        let is_online: Bool?
                        let last_seen: String?
                    }
                    let record = try update.decodeRecord(decoder: JSONDecoder()) as ProfileUpdate
                    if let isOnline = record.is_online {
                        await MainActor.run { self.otherUserOnline = isOnline }
                    }
                    if let lastSeenStr = record.last_seen {
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        if let date = formatter.date(from: lastSeenStr) {
                            await MainActor.run { self.lastSeen = date }
                        }
                    }
                } catch {
                    print("Erro ao ler update do profile: \(error)")
                }
            }

        }
        Task {
            for await payload in typingEvents {
                if let userID = payload["user_id"]?.stringValue, userID != currentUser.id.uuidString {
                    isTyping = true
                    typingTimer?.invalidate()
                    typingTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
                        Task { @MainActor in self.isTyping = false }
                    }
                }
            }
        }

        Task {
            for await insert in insertions {
                do {
                    struct Payload: Codable {
                        let id: UUID
                        let sender_id: UUID
                        let text: String
                        let media_url: String?
                        let is_read: Bool
                        let created_at: String
                    }
                    let record = try insert.decodeRecord(decoder: JSONDecoder()) as Payload
                    let dateFormatter = ISO8601DateFormatter()
                    dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    let createdAt = dateFormatter.date(from: record.created_at) ?? Date()
                    let message = Message(
                        id: record.id,
                        senderId: record.sender_id,
                        receiverId: record.sender_id == conversation.participantId ? currentUser.id : conversation.participantId,
                        text: record.text,
                        imageName: record.media_url,
                        timestamp: createdAt,
                        isRead: record.is_read
                    )
                    if !messages.contains(where: { $0.id == message.id }) {
                        messages.append(message)
                        if message.senderId != currentUser.id { await markAsRead() }
                    }
                } catch {
                    print("Erro ao receber mensagem: \(error)")
                }
            }
        }

        Task {
            for await update in updates {
                do {
                    struct Payload: Codable { let id: UUID; let is_read: Bool }
                    let record = try update.decodeRecord(decoder: JSONDecoder()) as Payload
                    await MainActor.run {
                        if let index = self.messages.firstIndex(where: { $0.id == record.id }) {
                            self.messages[index].isRead = record.is_read
                        }
                    }
                } catch {
                    print("Erro ao atualizar leitura: \(error)")
                }
            }
        }

        await channel.subscribe()
        do {
            try await channel.track(["user_id": currentUser.id.uuidString])
        } catch {
            print("Erro ao registrar presenÃƒÂ§a: \(error)")
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
        let msgId = UUID()
        let newMsg = Message(id: msgId, senderId: currentUser.id, receiverId: conversation.participantId, text: "Ã°Å¸Å½Â¤ Mensagem de voz (enviando...)", imageName: path, timestamp: Date(), isRead: false)
        await MainActor.run { self.messages.append(newMsg) }
        
        do {
            try await supabase.storage.from("chat-media").upload(path: path, file: data, options: FileOptions(contentType: "audio/mp4"))
            
            struct MsgInsert: Codable {
                let id: UUID
                let conversation_id: UUID
                let sender_id: UUID
                let text: String
                let media_url: String?
                let is_read: Bool
            }
            let insertData = MsgInsert(id: msgId, conversation_id: conversationID, sender_id: currentUser.id, text: "Ã°Å¸Å½Â¤ Mensagem de voz", media_url: path, is_read: false)
            try await supabase.database.from("messages").insert(insertData).execute()
            
            await MainActor.run {
                if let idx = self.messages.firstIndex(where: { $0.id == msgId }) {
                    self.messages[idx].text = "Ã°Å¸Å½Â¤ Mensagem de voz"
                }
            }
        } catch {
            print("Error uploading audio: \(error)")
        }
    }
    
    func sendMedia(data: Data, isVideo: Bool = false) async {
        let ext = isVideo ? "mp4" : "jpg"
        let path = "\(currentUser.id.uuidString)/\(UUID().uuidString).\(ext)"
        let contentType = isVideo ? "video/mp4" : "image/jpeg"
        let text = isVideo ? "Ã°Å¸â€œÂ¹ VÃƒÂ­deo" : "Ã°Å¸â€“Â¼Ã¯Â¸Â Imagem"
        
        let msgId = UUID()
        let newMsg = Message(id: msgId, senderId: currentUser.id, receiverId: conversation.participantId, text: "\(text) (enviando...)", imageName: path, timestamp: Date(), isRead: false)
        await MainActor.run { self.messages.append(newMsg) }
        
        do {
            try await supabase.storage.from("chat-media").upload(path: path, file: data, options: FileOptions(contentType: contentType))
            
            struct MsgInsert: Codable {
                let id: UUID
                let conversation_id: UUID
                let sender_id: UUID
                let text: String
                let media_url: String?
                let is_read: Bool
            }
            let insertData = MsgInsert(id: msgId, conversation_id: conversationID, sender_id: currentUser.id, text: text, media_url: path, is_read: false)
            try await supabase.database.from("messages").insert(insertData).execute()
            
            await MainActor.run {
                if let idx = self.messages.firstIndex(where: { $0.id == msgId }) {
                    self.messages[idx].text = text
                }
            }
        } catch {
            print("Error uploading media: \(error)")
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
        // Atualiza o estado local imediatamente
        await MainActor.run {
            for i in 0..<self.messages.count {
                if self.messages[i].senderId == self.conversation.participantId && !self.messages[i].isRead {
                    self.messages[i].isRead = true
                }
            }
        }
        
        // Sincroniza com o Supabase
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
