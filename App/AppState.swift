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
    @Published var isPremium: Bool = false
    @Published var onlineUsers: [String: Bool] = [:]
    @Published var lastActiveByUser: [String: Date] = [:]
    @Published var typingConversations: Set<String> = []
    @Published var pendingOpenConversationId: UUID? = nil

    let services: ServiceContainer
    let permissionService = PermissionService()
    let socketClient = RealtimeSocketClient()

    init(services: ServiceContainer = .live) {
        self.services = services
        let hasTokens = KeychainHelper.read(forKey: "access_token") != nil || KeychainHelper.read(forKey: "refresh_token") != nil
        if hasTokens,
           let data = UserDefaults.standard.data(forKey: "stored_user_profile"),
           let cached = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.currentUser = cached
            self.route = .main
            (services.chatService as? RemoteChatService)?.setCurrentUserId(cached.id)
        } else {
            self.route = .welcome
        }
        setupSocketListeners()
        Task {
            await bootstrap()
        }
    }

    private func setupSocketListeners() {
        socketClient.onNewMessage = { [weak self] conversationId, messageId, senderId, content, type, isViewOnce, isEphemeralOnExit, createdAt in
            guard let self, let convUUID = UUID(uuidString: conversationId), let msgUUID = UUID(uuidString: messageId) else { return }
            let isCurrentUser = senderId.lowercased() == self.currentUser?.id.uuidString.lowercased()
            let newMessage = ChatMessage(
                id: msgUUID,
                senderIsCurrentUser: isCurrentUser,
                text: content,
                sentAt: createdAt,
                type: ChatMessageType(rawValue: type) ?? .text,
                isViewOnce: isViewOnce,
                isEphemeralOnExit: isEphemeralOnExit,
                isDelivered: true,
                isRead: false
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

        socketClient.onMessageSent = { [weak self] conversationId, messageId, clientMessageId, content, type, isViewOnce, isEphemeralOnExit, createdAt in
            guard let self, let convUUID = UUID(uuidString: conversationId), let msgUUID = UUID(uuidString: messageId) else { return }
            if let idx = self.conversations.firstIndex(where: { $0.id == convUUID }) {
                if let optIdx = self.conversations[idx].messages.firstIndex(where: {
                    $0.senderIsCurrentUser && ($0.id == msgUUID || ($0.text == content && $0.type.rawValue == type))
                }) {
                    self.conversations[idx].messages[optIdx] = ChatMessage(
                        id: msgUUID,
                        senderIsCurrentUser: true,
                        text: content,
                        sentAt: createdAt,
                        type: ChatMessageType(rawValue: type) ?? .text,
                        isViewOnce: isViewOnce,
                        isEphemeralOnExit: isEphemeralOnExit,
                        isDelivered: false,
                        isRead: false
                    )
                } else if !self.conversations[idx].messages.contains(where: { $0.id == msgUUID }) {
                    let sentMsg = ChatMessage(
                        id: msgUUID,
                        senderIsCurrentUser: true,
                        text: content,
                        sentAt: createdAt,
                        type: ChatMessageType(rawValue: type) ?? .text,
                        isViewOnce: isViewOnce,
                        isEphemeralOnExit: isEphemeralOnExit,
                        isDelivered: false,
                        isRead: false
                    )
                    self.conversations[idx].messages.append(sentMsg)
                }
            }
        }

        socketClient.onMessageDelivered = { [weak self] conversationId, messageId in
            guard let self,
                  let convUUID = UUID(uuidString: conversationId),
                  let msgUUID = UUID(uuidString: messageId),
                  let cIdx = self.conversations.firstIndex(where: { $0.id == convUUID }),
                  let mIdx = self.conversations[cIdx].messages.firstIndex(where: { $0.id == msgUUID }) else { return }
            self.conversations[cIdx].messages[mIdx].isDelivered = true
        }

        socketClient.onMessageRead = { [weak self] conversationId, messageIds in
            guard let self,
                  let convUUID = UUID(uuidString: conversationId),
                  let cIdx = self.conversations.firstIndex(where: { $0.id == convUUID }) else { return }
            let idSet = Set(messageIds.compactMap { UUID(uuidString: $0) })
            for idx in self.conversations[cIdx].messages.indices {
                if idSet.contains(self.conversations[cIdx].messages[idx].id) || messageIds.isEmpty {
                    self.conversations[cIdx].messages[idx].isDelivered = true
                    self.conversations[cIdx].messages[idx].isRead = true
                }
            }
        }

        socketClient.onMessageEdited = { [weak self] conversationId, messageId, content, editedAt in
            guard let self,
                  let convUUID = UUID(uuidString: conversationId),
                  let msgUUID = UUID(uuidString: messageId),
                  let cIdx = self.conversations.firstIndex(where: { $0.id == convUUID }),
                  let mIdx = self.conversations[cIdx].messages.firstIndex(where: { $0.id == msgUUID }) else { return }
            self.conversations[cIdx].messages[mIdx].text = content
            self.conversations[cIdx].messages[mIdx].editedAt = editedAt
        }

        socketClient.onMessageDeleted = { [weak self] conversationId, messageId in
            guard let self,
                  let convUUID = UUID(uuidString: conversationId),
                  let msgUUID = UUID(uuidString: messageId),
                  let cIdx = self.conversations.firstIndex(where: { $0.id == convUUID }),
                  let mIdx = self.conversations[cIdx].messages.firstIndex(where: { $0.id == msgUUID }) else { return }
            self.conversations[cIdx].messages[mIdx].text = "Mensagem apagada para todos"
            self.conversations[cIdx].messages[mIdx].deletedForEveryoneAt = Date()
        }

        socketClient.onMessageConsumed = { [weak self] conversationId, messageId in
            guard let self,
                  let convUUID = UUID(uuidString: conversationId),
                  let msgUUID = UUID(uuidString: messageId),
                  let cIdx = self.conversations.firstIndex(where: { $0.id == convUUID }),
                  let mIdx = self.conversations[cIdx].messages.firstIndex(where: { $0.id == msgUUID }) else { return }
            self.conversations[cIdx].messages[mIdx].viewedAt = Date()
            self.conversations[cIdx].messages[mIdx].text = "Visualização única aberta"
        }

        socketClient.onChatCleared = { [weak self] conversationId in
            guard let self,
                  let convUUID = UUID(uuidString: conversationId),
                  let cIdx = self.conversations.firstIndex(where: { $0.id == convUUID }) else { return }
            self.conversations[cIdx].messages.removeAll()
            self.conversations[cIdx].unreadCount = 0
        }

        socketClient.onEphemeralPurged = { [weak self] conversationId, messageIds in
            guard let self,
                  let convUUID = UUID(uuidString: conversationId),
                  let cIdx = self.conversations.firstIndex(where: { $0.id == convUUID }) else { return }
            let purgedSet = Set(messageIds.map { $0.lowercased() })
            self.conversations[cIdx].messages.removeAll { purgedSet.contains($0.id.uuidString.lowercased()) }
        }

        socketClient.onNewMatch = { [weak self] _, _, _ in
            guard let self else { return }
            Task { await self.loadSocialData() }
        }

        socketClient.onNewNotification = { [weak self] in
            guard let self else { return }
            self.unreadNotificationCount += 1
        }

        socketClient.onPresenceChanged = { [weak self] userId, isOnline, lastActiveAt in
            guard let self else { return }
            let key = userId.lowercased()
            self.onlineUsers[key] = isOnline
            self.lastActiveByUser[key] = lastActiveAt
        }

        socketClient.onTypingChanged = { [weak self] conversationId, _, isTyping in
            guard let self else { return }
            let key = conversationId.lowercased()
            if isTyping {
                self.typingConversations.insert(key)
            } else {
                self.typingConversations.remove(key)
            }
        }
    }

    func bootstrap() async {
        if let savedProfile = try? await services.userRepository.loadCurrentProfile() {
            currentUser = savedProfile
            (services.chatService as? RemoteChatService)?.setCurrentUserId(savedProfile.id)
            await loadSocialData()
            socketClient.connect()
            if route != .main {
                withAnimation(.easeInOut(duration: 0.25)) {
                    route = .main
                }
            }
        } else if currentUser == nil {
            withAnimation(.easeInOut(duration: 0.25)) {
                route = .welcome
            }
        }
    }

    func completeOnboarding(with profile: UserProfile) async {
        currentUser = profile
        try? await services.userRepository.saveProfile(profile)
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
        await refreshSubscriptionStatus()
    }

    func openDirectChat(with targetUserId: UUID) async {
        struct OpenChatBody: Encodable {
            let targetUserId: String
        }
        struct OpenChatResponse: Decodable {
            let matchId: UUID
            let conversationId: UUID
        }
        if let res: OpenChatResponse = try? await APIClient.shared.request(
            path: "/likes/open-chat",
            method: "POST",
            body: OpenChatBody(targetUserId: targetUserId.uuidString.lowercased())
        ) {
            await loadSocialData()
            pendingOpenConversationId = res.conversationId
        }
    }

    func refreshSubscriptionStatus() async {
        struct SubStatusDTO: Decodable {
            let isPremium: Bool
            let isVerified: Bool
        }
        if let status: SubStatusDTO = try? await APIClient.shared.request(
            path: "/subscriptions/status",
            method: "GET"
        ) {
            isPremium = status.isPremium
            if var user = currentUser {
                user.isVerified = status.isVerified
                currentUser = user
            }
        }
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
