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

            VStack(spacing: 12) {
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                if selectedTab != .profile {
                    TopSegmentedNav(selectedTab: $selectedTab)
                        .padding(.horizontal, 20)
                }

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
            FiltersSheet(currentFilter: discoverViewModel.filter) { updated in
                discoverViewModel.applyFilter(updated)
            }
        }
        .sheet(isPresented: $showNotificationsSheet) {
            NotificationsSheet()
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
                    Image(systemName: selectedTab == .profile ? "gearshape.fill" : "slider.horizontal.3")
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
                .accessibilityLabel(selectedTab == .profile ? "Configurações" : "Filtros de descoberta")
            }
        }
    }
}

private struct NotificationDTO: Identifiable, Decodable {
    let id: String
    let type: String
    let title: String
    let body: String
    let isRead: Bool
    let createdAt: Date
}

private struct NotificationsListResponse: Decodable {
    let items: [NotificationDTO]
}

private struct NotificationsSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var items: [NotificationDTO] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(AppTheme.Colors.primaryRed)
                } else if items.isEmpty {
                    Text("Nenhuma notificação no momento.")
                        .font(AppTheme.Typography.subheadline())
                        .foregroundStyle(AppTheme.Colors.textGray)
                } else {
                    List(items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(AppTheme.Typography.headline())
                                .foregroundStyle(AppTheme.Colors.darkGray)
                            Text(item.body)
                                .font(AppTheme.Typography.subheadline())
                                .foregroundStyle(AppTheme.Colors.textGray)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Notificações")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                        .foregroundStyle(AppTheme.Colors.primaryRed)
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
}
