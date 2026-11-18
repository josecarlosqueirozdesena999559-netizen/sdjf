import Foundation
import SwiftUI

struct ServiceContainer {
    let authService: AuthServiceProtocol
    let storageService: StorageServiceProtocol
    let userRepository: UserRepositoryProtocol
    let verificationService: VerificationServiceProtocol
    let discoveryService: DiscoveryServiceProtocol
    let matchService: MatchServiceProtocol
    let chatService: ChatServiceProtocol

    static let live = ServiceContainer(
        authService: RemoteAuthService(),
        storageService: RemoteStorageService(),
        userRepository: RemoteUserRepository(),
        verificationService: RemoteVerificationService(),
        discoveryService: RemoteDiscoveryService(),
        matchService: RemoteMatchService(),
        chatService: RemoteChatService()
    )
}

enum RootRoute {
    case welcome
    case login
    case onboarding
    case main
}

@MainActor
final class AppState: ObservableObject {
    @Published var route: RootRoute = .welcome
    @Published var currentUser: UserProfile?
    @Published var matches: [MatchItem] = []
    @Published var conversations: [Conversation] = []
    @Published var unreadNotificationCount: Int = 0

    let services: ServiceContainer
    let permissionService = PermissionService()
    let socketClient = RealtimeSocketClient()

    init(services: ServiceContainer = .live) {
        self.services = services
        setupSocketListeners()
        Task {
            await bootstrap()
        }
    }

    private func setupSocketListeners() {
        socketClient.onNewMessage = { [weak self] conversationId, messageId, senderId, content, createdAt in
            guard let self, let convUUID = UUID(uuidString: conversationId), let msgUUID = UUID(uuidString: messageId) else { return }
            let isCurrentUser = senderId.lowercased() == self.currentUser?.id.uuidString.lowercased()
            let newMessage = ChatMessage(
                id: msgUUID,
                senderIsCurrentUser: isCurrentUser,
                text: content,
                sentAt: createdAt
            )
            if let idx = self.conversations.firstIndex(where: { $0.id == convUUID }) {
                if !self.conversations[idx].messages.contains(where: { $0.id == msgUUID }) {
                    self.conversations[idx].messages.append(newMessage)
                    if !isCurrentUser {
                        self.conversations[idx].unreadCount += 1
                    }
                }
            } else {
                Task { await self.loadSocialData() }
            }
        }

        socketClient.onNewMatch = { [weak self] _, _, _ in
            guard let self else { return }
            Task { await self.loadSocialData() }
        }

        socketClient.onNewNotification = { [weak self] in
            guard let self else { return }
            self.unreadNotificationCount += 1
        }
    }

    func bootstrap() async {
        if let savedProfile = try? await services.userRepository.loadCurrentProfile() {
            currentUser = savedProfile
            (services.chatService as? RemoteChatService)?.setCurrentUserId(savedProfile.id)
            await loadSocialData()
            socketClient.connect()
            route = .main
        } else {
            route = .welcome
        }
    }

    func completeOnboarding(with profile: UserProfile) async {
        currentUser = profile
        (services.chatService as? RemoteChatService)?.setCurrentUserId(profile.id)
        await loadSocialData()
        socketClient.connect()
        withAnimation(.easeInOut(duration: 0.35)) {
            route = .main
        }
    }

    func loadSocialData() async {
        if let loadedMatches = try? await services.matchService.fetchMatches() {
            matches = loadedMatches
        }
        if let loadedConversations = try? await services.chatService.fetchConversations() {
            conversations = loadedConversations
        }
        await refreshUnreadNotifications()
    }

    func refreshUnreadNotifications() async {
        struct NotificationsSummary: Decodable {
            let unreadCount: Int
        }
        if let summary: NotificationsSummary = try? await APIClient.shared.request(
            path: "/notifications?page=1&limit=1",
            method: "GET"
        ) {
            unreadNotificationCount = summary.unreadCount
        }
    }

    func registerMatch(with profile: UserProfile, isHighlighted: Bool) {
        if !matches.contains(where: { $0.profile.id == profile.id }) {
            let newMatch = MatchItem(
                id: UUID(),
                profile: profile,
                matchedAt: Date(),
                isHighlighted: isHighlighted
            )
            matches.insert(newMatch, at: 0)
        }

        if !conversations.contains(where: { $0.profile.id == profile.id }) {
            let newConversation = Conversation(
                id: UUID(),
                profile: profile,
                messages: [],
                unreadCount: 0
            )
            conversations.insert(newConversation, at: 0)
        }
    }

    func signOut() {
        socketClient.disconnect()
        Task {
            try? await services.userRepository.clearLocalSession()
            currentUser = nil
            matches = []
            conversations = []
            withAnimation(.easeInOut(duration: 0.3)) {
                route = .welcome
            }
        }
    }
}
