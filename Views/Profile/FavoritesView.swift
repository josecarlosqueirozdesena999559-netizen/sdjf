import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        Group {
            if favoritesViewModel.favoriteProducts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart.slash")
                        .font(.largeTitle)
                        .foregroundColor(Theme.textSecondary)
                    Text("Você ainda não favoritou nenhum produto.")
                        .foregroundColor(Theme.textSecondary)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(favoritesViewModel.favoriteProducts) { product in
                            NavigationLink(destination: ProductDetailView(product: product)) {
                                FlatProductCard(product: product)
                                    
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Meus Favoritos")
        .navigationBarTitleDisplayMode(.inline)
    }
}
