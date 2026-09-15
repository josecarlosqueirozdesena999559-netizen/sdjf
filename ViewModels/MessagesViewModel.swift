import Foundation
import Combine

class MessagesViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    
    func fetchConversations() {
        // Mock data
        let sampleProduct = MockData.products.first!
        let msg = Message(id: UUID(), senderId: UUID(), receiverId: UUID(), text: "Olá, o produto ainda está disponível?", timestamp: Date(), isRead: false)
        let conv = Conversation(id: UUID(), productId: sampleProduct.id, participantId: MockData.users[1].id, lastMessage: msg, unreadCount: 1)
        
        self.conversations = [conv]
    }
}
