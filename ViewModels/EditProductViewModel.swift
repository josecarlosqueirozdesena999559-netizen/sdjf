import Foundation
import Combine
import UIKit

class EditProductViewModel: ObservableObject {
    @Published var productId: UUID
    @Published var title: String
    @Published var description: String
    @Published var price: String
    @Published var selectedCondition: ProductCondition
    @Published var selectedCategoryId: UUID?
    @Published var location: String
    @Published var acceptsNegotiation: Bool
    @Published var isPublishing: Bool = false
    @Published var publishSuccess: Bool = false
    @Published var publishError: String? = nil
    
    init(product: Product) {
        self.productId = product.id
        self.title = product.title
        self.description = product.description
        self.price = String(format: "%.2f", product.price).replacingOccurrences(of: ".", with: ",")
        self.selectedCondition = product.condition
        self.selectedCategoryId = product.categoryId
        self.location = product.location
        self.acceptsNegotiation = product.acceptsNegotiation
    }
    
    var isFormValid: Bool {
        return !title.isEmpty && !price.isEmpty && selectedCategoryId != nil && !location.isEmpty
    }
    
    func save(images: [UIImage] = []) {
        guard isFormValid else { return }
        isPublishing = true
        publishError = nil
        
        Task {
            do {
                var imageUrls: [String] = []
                for image in images {
                    if let data = image.jpegData(compressionQuality: 0.7) {
                        let fileName = "\(UUID().uuidString).jpg"
                        do {
                            try await supabase.storage.from("products").upload(path: fileName, file: data, options: FileOptions(contentType: "image/jpeg"))
                            let publicUrl = try supabase.storage.from("products").getPublicURL(path: fileName)
                            imageUrls.append(publicUrl.absoluteString)
                        } catch {
                            print("Erro ao fazer upload da imagem: \(error)")
                        }
                    }
                }
                
                let pPrice = Double(price.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                
                struct UpdateProduct: Codable {
                    let title: String
                    let description: String
                    let price: Double
                    let condition: String
                    let category_id: UUID
                    let location: String
                    let accepts_negotiation: Bool
                }
                
                let updateData = UpdateProduct(
                    title: title,
                    description: description,
                    price: pPrice,
                    condition: selectedCondition.rawValue,
                    category_id: selectedCategoryId!,
                    location: location,
                    accepts_negotiation: acceptsNegotiation
                )
                
                try await supabase.database.from("products").update(updateData).eq("id", value: productId).execute()
                
                await MainActor.run {
                    self.isPublishing = false
                    self.publishSuccess = true
                }
            } catch {
                print("Erro ao editar: \(error)")
                await MainActor.run {
                    self.isPublishing = false
                    self.publishError = "Ocorreu um erro ao salvar as alteracoes. Tente novamente."
                }
            }
        }
    }
}
