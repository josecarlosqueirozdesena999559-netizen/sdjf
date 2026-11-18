import SwiftUI

struct MainContainerView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var discoverViewModel: DiscoverViewModel
    @State private var selectedTab: MainTab = .discover
    @State private var showFiltersSheet: Bool = false
    @State private var showNotificationsSheet: Bool = false

    init(discoveryService: DiscoveryServiceProtocol) {
        _discoverViewModel = StateObject(wrappedValue: DiscoverViewModel(discoveryService: discoveryService))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 10) {
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                Group {
                    switch selectedTab {
                    case .discover:
                        DiscoverView(viewModel: discoverViewModel)
                    case .matches:
                        MatchesView(selectedTab: $selectedTab)
                    case .conversations:
                        ConversationsView()
                    case .profile:
                        MyProfileView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.bottom, 76)

            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 8)
        }
        .task {
            if discoverViewModel.candidates.isEmpty {
                await discoverViewModel.loadCandidates()
            }
        }
        .sheet(isPresented: $showFiltersSheet) {
            SettingsView(currentFilter: discoverViewModel.filter) { updated in
                discoverViewModel.applyFilter(updated)
            }
            .environmentObject(appState)
        }
        .sheet(isPresented: $showNotificationsSheet) {
            NotificationsSheet {
                selectedTab = .conversations
            }
            .environmentObject(appState)
        }
        .overlay {
            if let matchedProfile = discoverViewModel.matchedProfile {
                MatchOverlayView(
                    profile: matchedProfile,
                    onSendMessage: {
                        discoverViewModel.matchedProfile = nil
                        selectedTab = .conversations
                    },
                    onKeepDiscovering: {
                        discoverViewModel.matchedProfile = nil
                    }
                )
            }
        }
    }

    private var headerBar: some View {
        HStack {
            HStack(spacing: 6) {
                ReservedLogoSlot()
                if appState.isPremium || appState.currentUser?.isVerified == true {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: "3B82F6"))
                        .accessibilityLabel("Perfil verificado")
                }
            }

            Spacer()

            ReservedAppNameSlot()

            Spacer()

            HStack(spacing: 10) {
                if appState.unreadNotificationCount > 0 {
                    Button {
                        showNotificationsSheet = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.darkGray)
                                .frame(width: 38, height: 38)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(
                                    Circle()
                                        .strokeBorder(AppTheme.Colors.glassBorder, lineWidth: 1)
                                )

                            Circle()
                                .fill(AppTheme.Colors.primaryRed)
                                .frame(width: 10, height: 10)
                                .offset(x: -2, y: 2)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Notificações")
                }

                Button {
                    showFiltersSheet = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.darkGray)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(AppTheme.Colors.glassBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Configurações")
            }
        }
    }
}

private struct NotificationActorPhotoDTO: Decodable {
    let id: String
    let url: String
    let thumbnailUrl: String?
}

private struct NotificationActorProfileDTO: Identifiable, Decodable {
    let id: String
    let fullName: String
    let username: String
    let age: Int
    let bio: String
    let approximateLocation: String
    let isVerified: Bool
    let isOnline: Bool
    let photos: [NotificationActorPhotoDTO]
    let alreadyMatched: Bool
    let matchId: String?
    let conversationId: String?
}

private struct NotificationDTO: Identifiable, Decodable {
    let id: String
    let type: String
    let title: String
    let body: String
    let isRead: Bool
    let createdAt: Date
    let actorProfile: NotificationActorProfileDTO?
}

private struct NotificationsListResponse: Decodable {
    let items: [NotificationDTO]
}

private struct NotificationsSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let onOpenConversations: () -> Void
    @State private var items: [NotificationDTO] = []
    @State private var isLoading = true
    @State private var selectedActor: NotificationActorProfileDTO?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(AppTheme.Colors.primaryRed)
                } else if items.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 32))
                            .foregroundStyle(AppTheme.Colors.primaryRed)
                        Text("Nenhuma notificação no momento.")
                            .font(AppTheme.Typography.subheadline())
                            .foregroundStyle(AppTheme.Colors.textGray)
                    }
                } else {
                    List(items) { item in
                        Button {
                            if let actor = item.actorProfile {
                                selectedActor = actor
                            }
                        } label: {
                            HStack(spacing: 12) {
                                avatarView(for: item)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(AppTheme.Typography.headline())
                                        .foregroundStyle(AppTheme.Colors.darkGray)
                                    Text(item.body)
                                        .font(AppTheme.Typography.subheadline())
                                        .foregroundStyle(AppTheme.Colors.textGray)
                                        .lineLimit(2)
                                }

                                Spacer(minLength: 0)

                                if item.actorProfile != nil {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(AppTheme.Colors.textGray.opacity(0.6))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(AppTheme.Colors.white)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("Notificações")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                        .foregroundStyle(AppTheme.Colors.primaryRed)
                }
            }
            .sheet(item: $selectedActor) { actor in
                NotificationActorProfileSheet(actor: actor) {
                    selectedActor = nil
                    dismiss()
                    onOpenConversations()
                }
            }
            .task {
                if let res: NotificationsListResponse = try? await APIClient.shared.request(
                    path: "/notifications?page=1&limit=30",
                    method: "GET"
                ) {
                    items = res.items
                }
                isLoading = false
                try? await APIClient.shared.requestVoid(path: "/notifications/read-all", method: "PUT")
                appState.unreadNotificationCount = 0
            }
        }
    }

    @ViewBuilder
    private func avatarView(for item: NotificationDTO) -> some View {
        if let urlStr = item.actorProfile?.photos.first?.thumbnailUrl ?? item.actorProfile?.photos.first?.url,
           let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    Circle().fill(AppTheme.Colors.chipUnselected)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(AppTheme.Colors.primaryRed.opacity(0.14))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: item.type == "NEW_MATCH" ? "heart.fill" : "bell.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.primaryRed)
                )
        }
    }
}

private struct NotificationActorProfileSheet: View {
    let actor: NotificationActorProfileDTO
    let onGoToMessages: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isMatched: Bool = false
    @State private var isSendingLike = false

    private struct LikeBody: Encodable {
        let targetUserId: String
        let type: String
    }

    private struct LikeResponse: Decodable {
        let matched: Bool?
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let urlStr = actor.photos.first?.url, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().scaledToFill()
                            } else {
                                Rectangle().fill(AppTheme.Colors.chipUnselected)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .aspectRatio(3.0 / 4.0, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text("\(actor.fullName), \(actor.age)")
                                .font(AppTheme.Typography.title())
                                .foregroundStyle(AppTheme.Colors.darkGray)
                            if actor.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Color.blue)
                            }
                        }

                        if !actor.approximateLocation.isEmpty {
                            Label(actor.approximateLocation, systemImage: "mappin.and.ellipse")
                                .font(AppTheme.Typography.caption())
                                .foregroundStyle(AppTheme.Colors.textGray)
                        }

                        if !actor.bio.isEmpty {
                            Text(actor.bio)
                                .font(AppTheme.Typography.body())
                                .foregroundStyle(AppTheme.Colors.darkGray)
                                .padding(.top, 4)
                        }
                    }

                    if isMatched || actor.alreadyMatched {
                        PrimaryButton(title: "Enviar mensagem") {
                            onGoToMessages()
                        }
                    } else {
                        PrimaryButton(title: "Dar Match de volta", isLoading: isSendingLike) {
                            Task { await likeBack() }
                        }
                    }
                }
                .padding(20)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle(actor.fullName.split(separator: " ").first.map(String.init) ?? actor.fullName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                        .foregroundStyle(AppTheme.Colors.primaryRed)
                }
            }
            .onAppear {
                isMatched = actor.alreadyMatched
            }
        }
    }

    private func likeBack() async {
        isSendingLike = true
        defer { isSendingLike = false }
        if let res: LikeResponse = try? await APIClient.shared.request(
            path: "/likes",
            method: "POST",
            body: LikeBody(targetUserId: actor.id, type: "LIKE")
        ) {
            if res.matched == true {
                isMatched = true
                onGoToMessages()
            } else {
                isMatched = true
            }
        }
    }
}
