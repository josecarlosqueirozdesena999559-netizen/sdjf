import Foundation
import Combine

class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [Product] = []
    @Published var selectedCategory: Category? = nil
    @Published var isLoading: Bool = false
    
    func search() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var filtered = MockData.products
            
            if !self.query.isEmpty {
                filtered = filtered.filter { $0.title.lowercased().contains(self.query.lowercased()) }
            }
            
            if let category = self.selectedCategory {
                filtered = filtered.filter { $0.categoryId == category.id }
            }
            
            self.results = filtered
            self.isLoading = false
        }
    }
}
