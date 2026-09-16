import Foundation
import Combine

struct SupabaseProduct: Codable {
    let id: UUID
    let title: String
    let description: String?
    let price: Double
    let condition: String
    let category_id: UUID?
    let seller_id: UUID
    let location: String?
    let accepts_negotiation: Bool?
    let status: String?
    let images: [String]?
    let created_at: Date?
}

struct SupabaseCategory: Codable {
    let id: UUID
    let name: String
    let icon: String?
    let color: String?
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var featuredProducts: [Product] = []
    @Published var categories: [Category] = []
    @Published var isLoading: Bool = false
    
    // Configura polling real-time básico (ou realtime SDK)
    private var timer: Timer?
    
    init() {
        fetchHomeData()
        startPolling()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func startPolling() {
        // Atualiza o feed a cada 30 segundos
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchHomeData()
            }
        }
    }
    
    func fetchHomeData() {
        Task {
            self.isLoading = true
            do {
                // Fetch Categories
                let sbCategories: [SupabaseCategory] = try await supabase.database
                    .from("categories")
                    .select()
                    .execute()
                    .value
                
                self.categories = sbCategories.map { sb in
                    Category(id: sb.id, name: sb.name, description: "", iconName: sb.icon ?? "tag")
                }
                
                // Fallback local se estiver vazio no banco
                if self.categories.isEmpty {
                    self.categories = MockData.categories
                }
                
                // Fetch Products
                let sbProducts: [SupabaseProduct] = try await supabase.database
                    .from("products")
                    .select()
                    .order("created_at", ascending: false)
                    .limit(20)
                    .execute()
                    .value
                
                let mappedProducts = sbProducts.map { sb in
                    Product(
                        id: sb.id,
                        title: sb.title,
                        description: sb.description ?? "",
                        price: sb.price,
                        condition: ProductCondition(rawValue: sb.condition) ?? .used,
                        categoryId: sb.category_id ?? UUID(),
                        sellerId: sb.seller_id,
                        location: sb.location ?? "Desconhecido",
                        images: sb.images ?? [],
                        createdAt: sb.created_at ?? Date(),
                        views: 0,
                        isActive: sb.status == "active",
                        deliveryMethod: "Em mãos",
                        acceptsNegotiation: sb.accepts_negotiation ?? false
                    )
                }
                
                self.featuredProducts = mappedProducts
                
                // Fallback mock se estiver vazio (apenas para o app não ficar pelado nos primeiros testes)
                if self.featuredProducts.isEmpty {
                    self.featuredProducts = Array(MockData.products.shuffled().prefix(6))
                }
                
            } catch {
                print("Erro ao buscar home data: \(error)")
                // Fallback mock em caso de erro
                if self.featuredProducts.isEmpty {
                    self.categories = MockData.categories
                    self.featuredProducts = Array(MockData.products.shuffled().prefix(6))
                }
            }
            self.isLoading = false
        }
    }
}
