import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var featuredProducts: [Product] = []
    @Published var categories: [Category] = []
    @Published var isLoading: Bool = false
    
    func fetchHomeData() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.categories = MockData.categories
            // Just picking a few random products for featured
            self.featuredProducts = Array(MockData.products.shuffled().prefix(6))
            self.isLoading = false
        }
    }
}
