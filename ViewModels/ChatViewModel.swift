import Foundation
import Supabase
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
    private var typingTimer: Timer?
    
    init(conversation: Conversation, currentUser: User) {
        self.conversation = conversation
        self.currentUser = currentUser
        
        Task {
            await fetchMessages()
            await setupRealtime()
        }
    }
    
    deinit {
        let chan = self.channel
        Task {
            await chan?.unsubscribe()
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
                .eq("conversation_id", value: conversation.id)
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
        let roomName = "room_\(conversation.id.uuidString)"
        self.channel = supabase.realtimeV2.channel(roomName)
        
        guard let channel = self.channel else { return }
        
        // Listen for new messages via Postgres Changes
        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages",
            filter: "conversation_id=eq.\(conversation.id.uuidString)"
        )
        
        // Listen for updates (e.g. is_read)
        let updates = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "messages",
            filter: "conversation_id=eq.\(conversation.id.uuidString)"
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
            
            for await action in channel.presenceChange() {
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
            let typingEvents = channel.broadcast(event: "typing")
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
            let media_type: String?
            let is_read: Bool
            let created_at: Date
        }
        let insertData = MsgInsert(
            id: msgId,
            conversation_id: conversation.id,
            sender_id: currentUser.id,
            text: text,
            media_url: mediaUrl,
            media_type: mediaType,
            is_read: false,
            created_at: Date()
        )
        
        do {
            try await supabase.database
                .from("messages")
                .insert(insertData)
                .execute()
        } catch {
            print("Error sending message: \(error)")
            self.messages.removeAll(where: { $0.id == msgId })
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
                .eq("conversation_id", value: conversation.id)
                .eq("sender_id", value: conversation.participantId)
                .eq("is_read", value: false)
                .execute()
        } catch {
            print("Error marking as read: \(error)")
        }
    }
}
