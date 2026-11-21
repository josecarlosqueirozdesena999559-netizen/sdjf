import Foundation

enum SwipeDecision: String, Codable {
    case like
    case reject
    case highlight
}

struct UserLookupPreview: Decodable, Equatable {
    let found: Bool
    let fullName: String?
    let username: String?
    let avatarUrl: String?
}

protocol AuthServiceProtocol {
    func checkUsernameAvailability(_ username: String) async throws -> Bool
    func lookupUserPreview(_ identifier: String) async throws -> UserLookupPreview
    func login(identifier: String, password: String) async throws -> UserProfile
    func registerAccount(
        fullName: String,
        email: String,
        username: String,
        password: String,
        birthDate: Date,
        legalAcceptance: LegalAcceptance
    ) async throws -> UUID
}

protocol StorageServiceProtocol {
    func uploadProfilePhotos(_ photos: [ProfilePhoto], userId: UUID) async throws -> [ProfilePhoto]
}

protocol UserRepositoryProtocol {
    func saveProfile(_ profile: UserProfile) async throws
    func loadCurrentProfile() async throws -> UserProfile?
    func clearLocalSession() async throws
}

protocol VerificationServiceProtocol {
    func requestProfileVerification(userId: UUID) async throws -> Bool
}

protocol DiscoveryServiceProtocol {
    func fetchCandidates(filter: DiscoveryFilter) async throws -> [UserProfile]
    func submitDecision(_ decision: SwipeDecision, targetUserId: UUID) async throws -> Bool
}

protocol MatchServiceProtocol {
    func fetchMatches() async throws -> [MatchItem]
}

protocol ChatServiceProtocol {
    func fetchConversations() async throws -> [Conversation]
    func fetchMessages(for conversationId: UUID) async throws -> [ChatMessage]
    func sendMessage(text: String, conversationId: UUID) async throws -> ChatMessage
}
