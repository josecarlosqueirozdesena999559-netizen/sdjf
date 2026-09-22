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
    let views: Int?
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
    
    func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2)*sin(dLat/2) + cos(lat1 * .pi/180)*cos(lat2 * .pi/180)*sin(dLon/2)*sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return R * c
    }

    func fetchHomeData(currentUserLat: Double? = nil, currentUserLon: Double? = nil) {
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
                
                // Fetch Products — mostra todos os produtos ativos ou sem status (novos cadastros)
                let sbProducts: [SupabaseProduct] = try await supabase.database
                    .from("products")
                    .select()
                    .or("status.eq.active,status.is.null")
                    .order("created_at", ascending: false)
                    .limit(60)
                    .execute()
                    .value
                
                var mappedProducts = sbProducts.map { sb in
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
                        views: sb.views ?? 0,
                        isActive: sb.status == "active",
                        deliveryMethod: "Em mãos",
                        acceptsNegotiation: sb.accepts_negotiation ?? false
                    )
                }

                // Geo-filter: if current user has lat/lon, filter to 60km radius
                if let userLat = currentUserLat, let userLon = currentUserLon {
                    // Collect unique seller IDs
                    let sellerIDs = Array(Set(sbProducts.map { $0.seller_id }))

                    // Fetch seller profiles (lat/lon) in one batch
                    struct SellerLocation: Codable {
                        let id: UUID
                        let latitude: Double?
                        let longitude: Double?
                    }
                    var sellerLocations: [SellerLocation] = []
                    for sellerId in sellerIDs {
                        if let profile = try? await supabase.database
                            .from("profiles")
                            .select("id,latitude,longitude")
                            .eq("id", value: sellerId)
                            .single()
                            .execute()
                            .value as SellerLocation {
                            sellerLocations.append(profile)
                        }
                    }

                    // Build a dict for fast lookup
                    var sellerLatLon: [UUID: (Double, Double)] = [:]
                    for sl in sellerLocations {
                        if let lat = sl.latitude, let lon = sl.longitude {
                            sellerLatLon[sl.id] = (lat, lon)
                        }
                    }

                    // Filter products whose seller is within 60km
                    mappedProducts = mappedProducts.filter { product in
                        if let (sellerLat, sellerLon) = sellerLatLon[product.sellerId] {
                            return haversineDistance(lat1: userLat, lon1: userLon, lat2: sellerLat, lon2: sellerLon) <= 60.0
                        }
                        // If seller has no location data, include the product
                        return true
                    }
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

