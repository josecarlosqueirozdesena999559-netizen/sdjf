import SwiftUI

struct MainContainerView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var discoverViewModel: DiscoverViewModel
    @State private var selectedTab: MainTab = .discover
    @State private var showFiltersSheet: Bool = false

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
            ReservedLogoSlot()

            Spacer()

            ReservedAppNameSlot()

            Spacer()

            Button {
                showFiltersSheet = true
            } label: {
                Image(systemName: "slider.horizontal.3")
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
            .accessibilityLabel("Filtros de descoberta")
        }
    }
}
