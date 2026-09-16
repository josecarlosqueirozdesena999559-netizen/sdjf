import SwiftUI

struct MainTabView: View {
    @StateObject private var favoritesViewModel = FavoritesViewModel()
    @State private var selectedTab = 0
    @State private var showPublish = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Image(systemName: "house")
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
                    .tabItem {
                        Text("")
                    }
                    .tag(2)
                
                MessagesListView()
                    .tabItem {
                        Image(systemName: "bubble.left.and.bubble.right")
                        Text("Mensagens")
                    }
                    .tag(3)
                
                UserProfileView()
                    .tabItem {
                        Image(systemName: "person.crop.circle")
                        Text("Perfil")
                    }
                    .tag(4)
            }
            .accentColor(Theme.primary)
            
            // Botão central flutuante
            Button(action: {
                showPublish = true
            }) {
                ZStack {
                    Circle()
                        .fill(Theme.primary)
                        .frame(width: 56, height: 56)
                        .shadow(color: Theme.primary.opacity(0.3), radius: 5, x: 0, y: 5)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -10)
        }
        .environmentObject(favoritesViewModel)
        .fullScreenCover(isPresented: $showPublish) {
            PublishProductView()
        }
    }
}
