import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    @State private var searchText = ""
    @Environment(\.scenePhase) var scenePhase
    
    let categoryColumns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)
    let productColumns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Barra de Pesquisa Flat
                    NavigationLink(destination: SearchResultsView(initialQuery: searchText)) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Theme.textSecondary)
                            Text("Buscar produtos, categorias...")
                                .foregroundColor(Theme.textSecondary)
                            Spacer()
                        }
                        .padding()
                        .background(Theme.inputBackground)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Banner da Imagem Fornecida
                    Image("banner_home")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(16)
                        .padding(.horizontal)
                    
                    // Categorias em Grid (4x2)
                    LazyVGrid(columns: categoryColumns, spacing: 20) {
                        ForEach(viewModel.categories.prefix(7)) { category in
                            NavigationLink(destination: SearchResultsView(category: category)) {
                                FlatCategoryCard(category: category)
                            }
                        }
                        // Botão "Mais"
                        NavigationLink(destination: CategoriesView()) {
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Theme.inputBackground)
                                        .frame(width: 60, height: 60)
                                    Image(systemName: "ellipsis")
                                        .font(.title2)
                                        .foregroundColor(Theme.primary)
                                }
                                Text("Mais")
                                    .font(.caption)
                                    .foregroundColor(Theme.textPrimary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Indicador Visual (Para o usuário saber que já está filtrado)
                    HStack {
                        Image(systemName: "location.north.circle.fill")
                            .foregroundColor(Theme.primary)
                        Text("Mostrando anúncios próximos a você")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, -8)
                    
                    // Menu Explorar
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Explorar")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(MockData.categories) { category in
                            let catProducts = MockData.products.filter { p in
                                p.categoryId == category.id &&
                                p.location == (authViewModel.currentUser?.location ?? "São Paulo - SP")
                            }
                            
                            if !catProducts.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text(category.name)
                                            .font(.headline)
                                        Spacer()
                                        NavigationLink(destination: SearchResultsView(category: category)) {
                                            Text("Ver tudo")
                                                .font(.subheadline)
                                                .foregroundColor(Theme.primary)
                                        }
                                    }
                                    .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(catProducts) { product in
                                                FlatProductCard(product: product)
                                                    .frame(width: 160)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 80) // Espaço para a tabbar
                }
                .padding(.vertical)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 36)
                        
                        if let user = authViewModel.currentUser {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.primary)
                                Text(user.location)
                                    .font(.caption2)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NotificationsView()) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .font(.title3)
                                .foregroundColor(.primary)
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
            }
            .onAppear {
                viewModel.fetchHomeData()
            }
            .refreshable {
                viewModel.fetchHomeData()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    viewModel.fetchHomeData()
                }
            }
        }
    }
}

