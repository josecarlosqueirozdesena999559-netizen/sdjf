import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var favoritesViewModel = FavoritesViewModel()
    @State private var selectedTab = 0
    @State private var showPublish = false
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

                // Bug 2 fix: tab vazio substituído por placeholder invisível
                // que não compete visualmente com o botão flutuante
                Color.clear
                    .tabItem { Label("", systemImage: "plus") }
                    .tag(2)

                MessagesListView(selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                        Text("Mensagens")
                    }
                    .tag(3)

                UserProfileView()
                    .tabItem {
                        Image(systemName: selectedTab == 4 ? "person.crop.circle.fill" : "person.crop.circle")
                        Text("Perfil")
                    }
                    .tag(4)
            }
            .accentColor(Theme.primary)

            // Não sobrepõe o compositor de mensagens.
            if selectedTab != 3 && !hideFloatingButton {
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
            // Impede que tap no botão ative o tab fantasma
            .simultaneousGesture(TapGesture().onEnded { })
            }
        }
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
        // Bug 5 fix: removida a requestNotificationPermissions() duplicada.
        // OneSignal já gerencia as permissões em MercadoFacilApp.swift
    }
}
