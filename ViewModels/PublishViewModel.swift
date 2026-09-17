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
    
    func publish(sellerId: UUID) {
        guard isFormValid else { return }
        isPublishing = true
        
        Task {
            do {
                let pPrice = Double(price.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                
                struct InsertProduct: Codable {
                    let title: String
                    let description: String
                    let price: Double
                    let condition: String
                    let category_id: UUID
                    let seller_id: UUID
                    let location: String
                    let accepts_negotiation: Bool
                    let status: String
                    let views: Int
                }
                
                let newProd = InsertProduct(
                    title: title,
                    description: description,
                    price: pPrice,
                    condition: selectedCondition.rawValue,
                    category_id: selectedCategoryId!,
                    seller_id: sellerId,
                    location: location,
                    accepts_negotiation: acceptsNegotiation,
                    status: "active",
                    views: 0
                )
                
                try await supabase.database.from("products").insert(newProd).execute()
                
                await MainActor.run {
                    self.isPublishing = false
                    self.publishSuccess = true
                    self.resetForm()
                }
            } catch {
                print("Erro ao publicar: \(error)")
                await MainActor.run {
                    self.isPublishing = false
                }
            }
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
