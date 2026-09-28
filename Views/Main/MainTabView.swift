import SwiftUI
import OneSignalFramework

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var favoritesViewModel = FavoritesViewModel()
    @StateObject private var messagesViewModel = MessagesViewModel()
    @State private var selectedTab = 0
    @State private var showPublish = false
    @StateObject private var locationManager = LocationManager.shared
    @AppStorage("hideFloatingButton") private var hideFloatingButton = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        Text("Início")
                    }
                    .tag(0)

                CategoriesView()
                    .tabItem {
                        Image(systemName: "square.grid.2x2")
                        Text("Categorias")
                    }
                    .tag(1)

                Color.clear
                    .tabItem { Text("") }
                    .tag(2)

                MessagesListView(viewModel: messagesViewModel, selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                        Text("Mensagens")
                    }
                    .badge(messagesViewModel.conversations.reduce(0) { $0 + $1.unreadCount })
                    .tag(3)

                UserProfileView()
                    .tabItem {
                        Image(systemName: selectedTab == 4 ? "person.crop.circle.fill" : "person.crop.circle")
                        Text("Perfil")
                    }
                    .tag(4)
            }
            .accentColor(Theme.primary)
            .onChange(of: selectedTab) { old, new in
                if new == 2 {
                    selectedTab = old
                    showPublish = true
                }
            }

            if !hideFloatingButton {
                Button(action: { showPublish = true }) {
                    ZStack {
                        Circle()
                            .fill(Theme.primary)
                            .frame(width: 56, height: 56)
                            .shadow(color: Theme.primary.opacity(0.3), radius: 5, x: 0, y: 5)
                        Image(systemName: "plus")
                            .typographyScreenTitle()
                            .foregroundColor(.white)
                    }
                }
                .offset(y: -10)
                .simultaneousGesture(TapGesture().onEnded { })
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .environmentObject(favoritesViewModel)
        .fullScreenCover(isPresented: $showPublish) {
            PublishProductView() {
                selectedTab = 4
            }
        }
        .sheet(isPresented: $authViewModel.needsProfileSetup) {
            ProfileSetupSheet()
                .environmentObject(authViewModel)
        }
        .onAppear {
            locationManager.requestLocation()
            if let userId = authViewModel.currentUser?.id {
                OneSignal.login(userId.uuidString)
            }
        }
    }
}