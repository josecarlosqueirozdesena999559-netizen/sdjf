import Foundation
import Combine
import UIKit

class PublishViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var price: String = ""
    @Published var selectedCondition: ProductCondition = .used
    @Published var selectedCategoryId: UUID? = nil
    @Published var location: String = ""
    @Published var whatsappNumber: String = ""
    @Published var deliveryMethod: String = "Retirada em mãos"
    @Published var acceptsNegotiation: Bool = true
    @Published var isPublishing: Bool = false
    @Published var publishSuccess: Bool = false
    @Published var publishError: String? = nil
    
    var isFormValid: Bool {
        return !title.isEmpty && !price.isEmpty && selectedCategoryId != nil && !location.isEmpty
    }
    
    func publish(sellerId: UUID, images: [UIImage] = []) {
        guard isFormValid else { return }
        isPublishing = true
        publishError = nil
        
        Task {
            do {
                // Pequeno delay para exibir a animação de carregamento (feedback visual)
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                
                var imageUrls: [String] = []
                for image in images {
                    if let data = image.jpegData(compressionQuality: 0.7) {
                        let fileName = "\(UUID().uuidString).jpg"
                        do {
                            try await supabase.storage.from("products").upload(path: fileName, file: data)
                            let publicUrl = try supabase.storage.from("products").getPublicURL(path: fileName)
                            imageUrls.append(publicUrl.absoluteString)
                        } catch {
                            print("Erro ao fazer upload da imagem: \(error)")
                        }
                    }
                }
                
                let pPrice = Double(price.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                
                struct InsertProduct: Codable {
                    let title: String
                    let description: String
                    let price: Double
                    let condition: String
                    let category_id: UUID
                    let seller_id: UUID
                    let location: String
                    let whatsapp_number: String
                    let accepts_negotiation: Bool
                    let status: String
                    let views: Int
                    let images: [String]
                }
                
                let newProd = InsertProduct(
                    title: title,
                    description: description,
                    price: pPrice,
                    condition: selectedCondition.rawValue,
                    category_id: selectedCategoryId!,
                    seller_id: sellerId,
                    location: location,
                    whatsapp_number: whatsappNumber,
                    accepts_negotiation: acceptsNegotiation,
                    status: "active",
                    views: 0,
                    images: imageUrls
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
                    self.publishError = "Ocorreu um erro ao publicar. Tente novamente."
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
