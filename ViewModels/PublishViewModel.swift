import Foundation
import Combine

class PublishViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var price: String = ""
    @Published var selectedCondition: ProductCondition = .used
    @Published var selectedCategoryId: UUID? = nil
    @Published var location: String = ""
    @Published var deliveryMethod: String = "Retirada em mãos"
    @Published var acceptsNegotiation: Bool = true
    @Published var isPublishing: Bool = false
    @Published var publishSuccess: Bool = false
    
    var isFormValid: Bool {
        return !title.isEmpty && !price.isEmpty && selectedCategoryId != nil && !location.isEmpty
    }
    
    func publish() {
        guard isFormValid else { return }
        isPublishing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isPublishing = false
            self.publishSuccess = true
            self.resetForm()
        }
    }
    
    private func resetForm() {
        title = ""
        description = ""
        price = ""
        selectedCategoryId = nil
        location = ""
    }
}
