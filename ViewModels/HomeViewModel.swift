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
    
    @Published var myStories: [Story] = []
    @Published var followedUsersWithStories: [Profile] = []
    @Published var storiesByUser: [UUID: [Story]] = [:]
    
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
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
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
                

                
            } catch {
                print("Erro ao buscar home data: \(error)")

            }
            self.isLoading = false
        }
    }

    func fetchStories(currentUserId: UUID?) {
        guard let userId = currentUserId else { return }
        Task {
            do {
                // 1. Obter IDs das pessoas que eu sigo
                struct FollowRes: Codable { let following_id: UUID }
                let follows: [FollowRes] = try await supabase.database
                    .from("follows")
                    .select("following_id")
                    .eq("follower_id", value: userId)
                    .execute()
                    .value
                let followingIds = follows.map { $0.following_id }

                // 2. Obter stories não expirados
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let nowString = formatter.string(from: Date())

                struct StoryRes: Codable {
                    let id: UUID
                    let user_id: UUID
                    let media_url: String
                    let media_type: String
                    let created_at: Date
                    let expires_at: Date
                    let profiles: Profile
                }

                let allStories: [StoryRes] = try await supabase.database
                    .from("stories")
                    .select("*, profiles(*)")
                    .gt("expires_at", value: nowString)
                    .execute()
                    .value

                var tempMyStories: [Story] = []
                var tempFollowingUsers: [UUID: Profile] = [:]
                var tempStoriesByUser: [UUID: [Story]] = [:]

                for s in allStories {
                    let story = Story(id: s.id, userId: s.user_id, mediaUrl: s.media_url, mediaType: s.media_type, createdAt: s.created_at, expiresAt: s.expires_at)
                    if s.user_id == userId {
                        tempMyStories.append(story)
                    } else if followingIds.contains(s.user_id) {
                        tempFollowingUsers[s.user_id] = s.profiles
                        tempStoriesByUser[s.user_id, default: []].append(story)
                    }
                }

                // Sort my stories
                tempMyStories.sort { $0.createdAt < $1.createdAt }
                
                // Sort users by who posted most recently
                for key in tempStoriesByUser.keys {
                    tempStoriesByUser[key]?.sort { $0.createdAt < $1.createdAt }
                }
                
                let sortedUsers = tempFollowingUsers.values.sorted { u1, u2 in
                    let last1 = tempStoriesByUser[u1.id]?.last?.createdAt ?? Date.distantPast
                    let last2 = tempStoriesByUser[u2.id]?.last?.createdAt ?? Date.distantPast
                    return last1 > last2
                }

                await MainActor.run {
                    self.myStories = tempMyStories
                    self.followedUsersWithStories = sortedUsers
                    self.storiesByUser = tempStoriesByUser
                }

            } catch {
                print("Erro ao buscar stories: \(error)")
            }
        }
    }
}

