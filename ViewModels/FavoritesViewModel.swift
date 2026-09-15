import Foundation
import Combine

class FavoritesViewModel: ObservableObject {
    @Published var favoriteProducts: [Product] = []
    
    func toggleFavorite(product: Product) {
        if let index = favoriteProducts.firstIndex(where: { $0.id == product.id }) {
            favoriteProducts.remove(at: index)
        } else {
            favoriteProducts.append(product)
        }
    }
    
    func isFavorite(_ product: Product) -> Bool {
        return favoriteProducts.contains(where: { $0.id == product.id })
    }
}
