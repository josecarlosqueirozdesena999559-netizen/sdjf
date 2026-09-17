import Foundation
import Combine

@MainActor
class MessagesViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    
    func fetchConversations(for userId: UUID) async {
        do {
            struct SupabaseMessage: Codable {
                let id: UUID
                let sender_id: UUID
                let text: String
                let media_url: String?
                let is_read: Bool
                let created_at: Date
            }
            
            struct SupabaseConversation: Codable {
                let id: UUID
                let buyer_id: UUID
                let seller_id: UUID
                let product_id: UUID
                let created_at: Date
                let messages: [SupabaseMessage]
            }
            
            let response: [SupabaseConversation] = try await supabase.database
                .from("conversations")
                .select("*, messages(*)")
                .or("buyer_id.eq.\(userId.uuidString),seller_id.eq.\(userId.uuidString)")
                .execute()
                .value
            
            self.conversations = response.compactMap { conv in
                let sortedMessages = conv.messages.sorted(by: { $0.created_at < $1.created_at })
                guard let lastMsg = sortedMessages.last else { return nil }
                
                let unreadCount = conv.messages.filter { !$0.is_read && $0.sender_id != userId }.count
                let participantId = conv.buyer_id == userId ? conv.seller_id : conv.buyer_id
                
                let swiftLastMessage = Message(
                    id: lastMsg.id,
                    senderId: lastMsg.sender_id,
                    receiverId: lastMsg.sender_id == participantId ? userId : participantId,
                    text: lastMsg.text,
                    imageName: lastMsg.media_url,
                    timestamp: lastMsg.created_at,
                    isRead: lastMsg.is_read
                )
                
                return Conversation(
                    id: conv.id,
                    productId: conv.product_id,
                    participantId: participantId,
                    lastMessage: swiftLastMessage,
                    unreadCount: unreadCount
                )
            }.sorted(by: { $0.lastMessage.timestamp > $1.lastMessage.timestamp })
            
        } catch {
            print("Error fetching conversations: \(error)")
        }
    }
}
