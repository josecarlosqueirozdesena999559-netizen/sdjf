import Foundation

struct MatchItem: Identifiable, Hashable, Codable {
    let id: UUID
    let profile: UserProfile
    let matchedAt: Date
    var isHighlighted: Bool
}

struct ChatMessage: Identifiable, Hashable, Codable {
    let id: UUID
    let senderIsCurrentUser: Bool
    let text: String
    let sentAt: Date
}

struct Conversation: Identifiable, Hashable, Codable {
    let id: UUID
    let profile: UserProfile
    var messages: [ChatMessage]
    var unreadCount: Int

    var lastMessage: ChatMessage? {
        messages.last
    }
}
