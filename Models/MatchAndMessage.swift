import Foundation

struct MatchItem: Identifiable, Hashable, Codable {
    let id: UUID
    let profile: UserProfile
    let matchedAt: Date
    var isHighlighted: Bool
}

enum ChatMessageType: String, Hashable, Codable {
    case text = "TEXT"
    case image = "IMAGE"
    case audio = "AUDIO"
}

struct ChatMessage: Identifiable, Hashable, Codable {
    let id: UUID
    let senderIsCurrentUser: Bool
    var text: String
    let sentAt: Date
    var type: ChatMessageType = .text
    var isViewOnce: Bool = false
    var viewedAt: Date? = nil
    var isEphemeralOnExit: Bool = false
    var editedAt: Date? = nil
    var deletedForEveryoneAt: Date? = nil
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
