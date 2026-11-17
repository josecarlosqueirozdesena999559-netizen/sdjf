import Foundation
import UIKit

// MARK: - API DTOs

private struct CheckUsernameResponse: Decodable {
    let available: Bool
    let username: String
}

private struct RegisterRequest: Encodable {
    let fullName: String
    let email: String
    let username: String
    let password: String
    let birthDate: Date
    let isAdultConfirmed: Bool
    let termsVersion: String
    let termsAcceptedAt: Date
}

private struct LoginRequest: Encodable {
    let identifier: String
    let password: String
}

private struct UserMeDTO: Decodable {
    let id: UUID
    let fullName: String
    let email: String
    let username: String
    let age: Int
    let bio: String
    let city: String
    let isVerified: Bool
    let isOnline: Bool
    let photos: [UploadPhotoResponse.PhotoDTO]
    let interests: [RemoteInterestDTO]
}

private struct RegisterResponse: Decodable {
    struct UserSummary: Decodable {
        let id: UUID
        let fullName: String
        let email: String
        let username: String
    }
    let user: UserSummary
    let accessToken: String
    let refreshToken: String
}

private struct UploadPhotoResponse: Decodable {
    struct PhotoDTO: Decodable {
        let id: UUID
        let url: String
        let thumbnailUrl: String
        let order: Int
        let isPrimary: Bool
    }
    let photo: PhotoDTO
}

private struct RemoteInterestDTO: Decodable {
    let id: String
    let slug: String
    let name: String
    let icon: String
}

private struct DiscoveryResponse: Decodable {
    struct CandidateDTO: Decodable {
        struct PhotoDTO: Decodable {
            let id: UUID
            let url: String
            let thumbnailUrl: String
            let order: Int
            let isPrimary: Bool
        }
        let id: UUID
        let fullName: String
        let username: String
        let age: Int
        let bio: String
        let approximateLocation: String
        let distanceKm: Int
        let isOnline: Bool
        let isVerified: Bool
        let photos: [PhotoDTO]
        let interests: [RemoteInterestDTO]
    }
    let items: [CandidateDTO]
}

private struct LikeRequest: Encodable {
    let targetUserId: String
    let type: String
}

private struct LikeResponse: Decodable {
    let matched: Bool
}

private struct MatchesResponse: Decodable {
    struct MatchDTO: Decodable {
        struct PartnerDTO: Decodable {
            struct PhotoDTO: Decodable {
                let id: UUID
                let url: String
                let thumbnailUrl: String
                let isPrimary: Bool
            }
            let id: UUID
            let fullName: String
            let username: String
            let age: Int
            let isOnline: Bool
            let isVerified: Bool
            let photos: [PhotoDTO]
        }
        let id: UUID
        let conversationId: UUID?
        let matchedAt: Date
        let partner: PartnerDTO
    }
    let items: [MatchDTO]
}

private struct ConversationsResponse: Decodable {
    struct ConversationDTO: Decodable {
        struct PartnerDTO: Decodable {
            struct PhotoDTO: Decodable {
                let id: UUID
                let url: String
                let thumbnailUrl: String
            }
            let id: UUID
            let fullName: String
            let username: String
            let photos: [PhotoDTO]
        }
        struct MessageDTO: Decodable {
            let id: UUID
            let senderId: UUID
            let content: String
            let createdAt: Date
        }
        let id: UUID
        let unreadCount: Int
        let lastMessage: MessageDTO?
        let partner: PartnerDTO?
    }
    let items: [ConversationDTO]
}

private struct MessagesHistoryResponse: Decodable {
    struct MessageDTO: Decodable {
        let id: UUID
        let senderId: UUID
        let content: String
        let createdAt: Date
    }
    let items: [MessageDTO]
}

// MARK: - Live Implementations

final class RemoteAuthService: AuthServiceProtocol {
    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        let cleaned = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cleaned
        let res: CheckUsernameResponse = try await APIClient.shared.request(
            path: "/auth/check-username/\(encoded)",
            method: "GET",
            requiresAuth: false
        )
        return res.available
    }

    func login(identifier: String, password: String) async throws -> UserProfile {
        let res: RegisterResponse = try await APIClient.shared.request(
            path: "/auth/login",
            method: "POST",
            body: LoginRequest(identifier: identifier, password: password),
            requiresAuth: false
        )
        KeychainHelper.save(res.accessToken, forKey: "access_token")
        KeychainHelper.save(res.refreshToken, forKey: "refresh_token")

        let me: UserMeDTO = try await APIClient.shared.request(path: "/users/me", method: "GET")
        return UserProfile(
            id: me.id,
            fullName: me.fullName,
            email: me.email,
            username: me.username,
            age: me.age,
            photos: me.photos.map { ProfilePhoto(id: $0.id, remoteURL: $0.url) },
            interests: me.interests.map { Interest(id: $0.slug, title: $0.name, sfSymbol: $0.icon) },
            bio: me.bio,
            isVerified: me.isVerified,
            isOnline: me.isOnline,
            distanceKm: 0,
            city: me.city
        )
    }

    func registerAccount(
        fullName: String,
        email: String,
        username: String,
        password: String,
        birthDate: Date,
        legalAcceptance: LegalAcceptance
    ) async throws -> UUID {
        let payload = RegisterRequest(
            fullName: fullName,
            email: email,
            username: username,
            password: password,
            birthDate: birthDate,
            isAdultConfirmed: true,
            termsVersion: legalAcceptance.termsVersion,
            termsAcceptedAt: legalAcceptance.acceptedAt
        )
        let res: RegisterResponse = try await APIClient.shared.request(
            path: "/auth/register",
            method: "POST",
            body: payload,
            requiresAuth: false
        )
        KeychainHelper.save(res.accessToken, forKey: "access_token")
        KeychainHelper.save(res.refreshToken, forKey: "refresh_token")
        return res.user.id
    }
}

final class RemoteStorageService: StorageServiceProtocol {
    func uploadProfilePhotos(_ photos: [ProfilePhoto], userId: UUID) async throws -> [ProfilePhoto] {
        var uploaded: [ProfilePhoto] = []
        for photo in photos {
            guard let rawData = photo.imageData,
                  let image = UIImage(data: rawData),
                  let jpegData = image.jpegData(compressionQuality: 0.85) else {
                uploaded.append(photo)
                continue
            }

            let res: UploadPhotoResponse = try await APIClient.shared.uploadJPEG(
                path: "/photos/upload",
                imageData: jpegData
            )
            uploaded.append(
                ProfilePhoto(
                    id: res.photo.id,
                    imageData: rawData,
                    remoteURL: res.photo.url
                )
            )
        }
        return uploaded
    }
}

final class RemoteUserRepository: UserRepositoryProtocol {
    private let localFallback = LocalUserRepository()

    func saveProfile(_ profile: UserProfile) async throws {
        struct UpdateProfileBody: Encodable {
            let bio: String
            let city: String
            let approximateLocation: String
        }
        try await APIClient.shared.requestVoid(
            path: "/users/profile",
            method: "PUT",
            body: UpdateProfileBody(
                bio: profile.bio,
                city: profile.city,
                approximateLocation: profile.city
            )
        )

        // Sync interests by fetching server interest IDs and matching by slug
        let serverInterests: [RemoteInterestDTO] = try await APIClient.shared.request(
            path: "/interests",
            method: "GET",
            requiresAuth: false
        )
        let slugToUUID = Dictionary(uniqueKeysWithValues: serverInterests.map { ($0.slug, $0.id) })
        let matchedIds = profile.interests.compactMap { slugToUUID[$0.id] }
        if matchedIds.count >= 3 {
            struct UpdateInterestsBody: Encodable {
                let interestIds: [String]
            }
            try await APIClient.shared.requestVoid(
                path: "/users/interests",
                method: "PUT",
                body: UpdateInterestsBody(interestIds: matchedIds)
            )
        }

        try await localFallback.saveProfile(profile)
    }

    func loadCurrentProfile() async throws -> UserProfile? {
        guard KeychainHelper.read(forKey: "access_token") != nil else {
            return nil
        }
        return try await localFallback.loadCurrentProfile()
    }

    func clearLocalSession() async throws {
        if let refreshToken = KeychainHelper.read(forKey: "refresh_token") {
            struct LogoutBody: Encodable {
                let refreshToken: String
            }
            try? await APIClient.shared.requestVoid(
                path: "/auth/logout",
                method: "POST",
                body: LogoutBody(refreshToken: refreshToken),
                requiresAuth: false
            )
        }
        KeychainHelper.clearAllTokens()
        try await localFallback.clearLocalSession()
    }
}

final class RemoteVerificationService: VerificationServiceProtocol {
    func requestProfileVerification(userId: UUID) async throws -> Bool {
        true
    }
}

final class RemoteDiscoveryService: DiscoveryServiceProtocol {
    func fetchCandidates(filter: DiscoveryFilter) async throws -> [UserProfile] {
        let query = "/discovery?maxDistanceKm=\(Int(filter.maxDistanceKm))&minAge=\(filter.minAge)&maxAge=\(filter.maxAge)&onlyVerified=\(filter.onlyVerified)&onlyOnline=\(filter.onlyOnline)&page=1&limit=20"
        let res: DiscoveryResponse = try await APIClient.shared.request(path: query, method: "GET")

        return res.items.map { item in
            UserProfile(
                id: item.id,
                fullName: item.fullName,
                username: item.username,
                age: item.age,
                photos: item.photos.map {
                    ProfilePhoto(id: $0.id, remoteURL: $0.url)
                },
                interests: item.interests.map {
                    Interest(id: $0.slug, title: $0.name, sfSymbol: $0.icon)
                },
                bio: item.bio,
                isVerified: item.isVerified,
                isOnline: item.isOnline,
                distanceKm: item.distanceKm,
                city: item.approximateLocation
            )
        }
    }

    func submitDecision(_ decision: SwipeDecision, targetUserId: UUID) async throws -> Bool {
        let typeString: String
        switch decision {
        case .like: typeString = "LIKE"
        case .reject: typeString = "PASS"
        case .highlight: typeString = "SUPERLIKE"
        }

        let res: LikeResponse = try await APIClient.shared.request(
            path: "/likes",
            method: "POST",
            body: LikeRequest(targetUserId: targetUserId.uuidString.lowercased(), type: typeString)
        )
        return res.matched
    }
}

final class RemoteMatchService: MatchServiceProtocol {
    func fetchMatches() async throws -> [MatchItem] {
        let res: MatchesResponse = try await APIClient.shared.request(path: "/matches", method: "GET")
        return res.items.map { item in
            let profile = UserProfile(
                id: item.partner.id,
                fullName: item.partner.fullName,
                username: item.partner.username,
                age: item.partner.age,
                photos: item.partner.photos.map { ProfilePhoto(id: $0.id, remoteURL: $0.url) },
                interests: [],
                bio: "",
                isVerified: item.partner.isVerified,
                isOnline: item.partner.isOnline
            )
            return MatchItem(
                id: item.id,
                profile: profile,
                matchedAt: item.matchedAt,
                isHighlighted: false
            )
        }
    }
}

final class RemoteChatService: ChatServiceProtocol {
    private var currentUserId: UUID?

    func setCurrentUserId(_ id: UUID?) {
        currentUserId = id
    }

    func fetchConversations() async throws -> [Conversation] {
        let res: ConversationsResponse = try await APIClient.shared.request(path: "/conversations", method: "GET")
        var conversations: [Conversation] = []

        for item in res.items {
            guard let partner = item.partner else { continue }
            let history: MessagesHistoryResponse = try await APIClient.shared.request(
                path: "/conversations/\(item.id.uuidString.lowercased())/messages?limit=30",
                method: "GET"
            )

            let profile = UserProfile(
                id: partner.id,
                fullName: partner.fullName,
                username: partner.username,
                age: 25,
                photos: partner.photos.map { ProfilePhoto(id: $0.id, remoteURL: $0.url) },
                interests: [],
                bio: ""
            )

            let messages = history.items.map { m in
                ChatMessage(
                    id: m.id,
                    senderIsCurrentUser: m.senderId == currentUserId,
                    text: m.content,
                    sentAt: m.createdAt
                )
            }

            conversations.append(
                Conversation(
                    id: item.id,
                    profile: profile,
                    messages: messages,
                    unreadCount: item.unreadCount
                )
            )
        }

        return conversations
    }

    func sendMessage(text: String, conversationId: UUID) async throws -> ChatMessage {
        ChatMessage(id: UUID(), senderIsCurrentUser: true, text: text, sentAt: Date())
    }
}
