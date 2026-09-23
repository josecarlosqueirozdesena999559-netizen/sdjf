import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    var name: String
    var cpf: String?
    var birthDate: Date?
    var email: String
    var phone: String
    var username: String?
    var visibleName: String?
    var avatarURL: String?
    var location: String
    var latitude: Double?
    var longitude: Double?
    var memberSince: Date
    var isProfessional: Bool
    var rating: Double?
    var responseTime: String?
    var bio: String?
    var isOnline: Bool?
    var lastSeen: Date?
}

struct Seller: Identifiable, Codable {
    let id: UUID
    var user: User
    var isVerified: Bool
    var rating: Double
    var reviewCount: Int
    var salesCount: Int
    var averageResponseTime: String
    var bio: String
}

enum ProductCondition: String, Codable, CaseIterable {
    case new = "Novo"
    case likeNew = "Semi-novo"
    case used = "Usado"
}

struct Product: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var price: Double
    var condition: ProductCondition
    var categoryId: UUID
    var sellerId: UUID
    var location: String
    var whatsappNumber: String?
    var images: [String]
    var createdAt: Date
    var views: Int
    var isActive: Bool
    var deliveryMethod: String
    var acceptsNegotiation: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, description, price, condition, location, images, views
        case categoryId = "category_id"
        case sellerId = "seller_id"
        case whatsappNumber = "whatsapp_number"
        case createdAt = "created_at"
        case isActive = "is_active"
        case deliveryMethod = "delivery_method"
        case acceptsNegotiation = "accepts_negotiation"
    }
}

struct Category: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var iconName: String
}

struct Message: Identifiable, Codable {
    let id: UUID
    let senderId: UUID
    let receiverId: UUID
    let text: String
    var imageName: String? = nil // Support for sending images
    let timestamp: Date
    var isRead: Bool
}

struct Conversation: Identifiable, Codable {
    let id: UUID
    let productId: UUID
    let participantId: UUID
    var lastMessage: Message
    var unreadCount: Int
}

enum NotificationType: String, Codable {
    case message, sale, purchase, favorite, system
}

struct AppNotification: Identifiable, Codable {
    let id: UUID
    let user_id: UUID
    let type: String
    let title: String
    let body: String
    let created_at: Date
    var is_read: Bool
}

struct Story: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let mediaUrl: String
    let mediaType: String
    let createdAt: Date
    let expiresAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mediaUrl = "media_url"
        case mediaType = "media_type"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }
}

struct Follow: Codable {
    let follower_id: UUID
    let following_id: UUID
    let created_at: Date
}
