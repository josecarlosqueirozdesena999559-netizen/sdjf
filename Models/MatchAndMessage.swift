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
    var isDelivered: Bool = false
    var isRead: Bool = false
    var localImageData: Data? = nil

    init(
        id: UUID = UUID(),
        senderIsCurrentUser: Bool,
        text: String,
        sentAt: Date = Date(),
        type: ChatMessageType = .text,
        isViewOnce: Bool = false,
        viewedAt: Date? = nil,
        isEphemeralOnExit: Bool = false,
        editedAt: Date? = nil,
        deletedForEveryoneAt: Date? = nil,
        isDelivered: Bool = false,
        isRead: Bool = false,
        localImageData: Data? = nil
    ) {
        self.id = id
        self.senderIsCurrentUser = senderIsCurrentUser
        self.text = text
        self.sentAt = sentAt
        self.type = type
        self.isViewOnce = isViewOnce
        self.viewedAt = viewedAt
        self.isEphemeralOnExit = isEphemeralOnExit
        self.editedAt = editedAt
        self.deletedForEveryoneAt = deletedForEveryoneAt
        self.isDelivered = isDelivered
        self.isRead = isRead
        self.localImageData = localImageData
    }

    enum CodingKeys: String, CodingKey {
        case id, senderIsCurrentUser, text, sentAt, type, isViewOnce, viewedAt, isEphemeralOnExit, editedAt, deletedForEveryoneAt, isDelivered, isRead
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        senderIsCurrentUser = try container.decode(Bool.self, forKey: .senderIsCurrentUser)
        text = try container.decode(String.self, forKey: .text)
        sentAt = try container.decode(Date.self, forKey: .sentAt)
        type = try container.decodeIfPresent(ChatMessageType.self, forKey: .type) ?? .text
        isViewOnce = try container.decodeIfPresent(Bool.self, forKey: .isViewOnce) ?? false
        viewedAt = try container.decodeIfPresent(Date.self, forKey: .viewedAt)
        isEphemeralOnExit = try container.decodeIfPresent(Bool.self, forKey: .isEphemeralOnExit) ?? false
        editedAt = try container.decodeIfPresent(Date.self, forKey: .editedAt)
        deletedForEveryoneAt = try container.decodeIfPresent(Date.self, forKey: .deletedForEveryoneAt)
        isDelivered = try container.decodeIfPresent(Bool.self, forKey: .isDelivered) ?? false
        isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
        localImageData = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(senderIsCurrentUser, forKey: .senderIsCurrentUser)
        try container.encode(text, forKey: .text)
        try container.encode(sentAt, forKey: .sentAt)
        try container.encode(type, forKey: .type)
        try container.encode(isViewOnce, forKey: .isViewOnce)
        try container.encodeIfPresent(viewedAt, forKey: .viewedAt)
        try container.encode(isEphemeralOnExit, forKey: .isEphemeralOnExit)
        try container.encodeIfPresent(editedAt, forKey: .editedAt)
        try container.encodeIfPresent(deletedForEveryoneAt, forKey: .deletedForEveryoneAt)
        try container.encode(isDelivered, forKey: .isDelivered)
        try container.encode(isRead, forKey: .isRead)
    }
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
