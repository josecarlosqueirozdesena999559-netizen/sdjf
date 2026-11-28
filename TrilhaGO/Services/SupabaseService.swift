import Foundation
import CoreLocation

struct ChestClaimResponse: Codable {
    let ok: Bool
    let rarity: ChestRarity?
    let rewardTitle: String?
    let qrToken: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case ok
        case rarity
        case rewardTitle = "reward_title"
        case qrToken = "qr_token"
        case error
    }
}

final class SupabaseService {
    static let shared = SupabaseService()

    private let baseURL: String
    private let anonKey: String

    var isConfigured: Bool {
        !baseURL.isEmpty && !baseURL.contains("SEU-PROJETO") && !anonKey.isEmpty
    }

    private init() {
        let info = Bundle.main.infoDictionary ?? [:]
        self.baseURL = (info["SUPABASE_URL"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        self.anonKey = (info["SUPABASE_ANON_KEY"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func claimChestReward(
        userId: UUID,
        store: StoreLocation,
        userCoordinate: CLLocationCoordinate2D,
        keyCost: Int = 1
    ) async -> ChestClaimResponse {
        guard isConfigured,
              let url = URL(string: "\(baseURL)/rest/v1/rpc/claim_chest_reward") else {
            return simulateAtomicClaim(store: store)
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "p_user_id": userId.uuidString,
            "p_store_id": store.id.uuidString,
            "p_user_lat": userCoordinate.latitude,
            "p_user_lng": userCoordinate.longitude,
            "p_key_cost": keyCost
        ]

        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, _) = try await URLSession.shared.data(for: req)
            return try JSONDecoder().decode(ChestClaimResponse.self, from: data)
        } catch {
            return simulateAtomicClaim(store: store)
        }
    }

    private func simulateAtomicClaim(store: StoreLocation) -> ChestClaimResponse {
        let roll = Double.random(in: 0..<1)
        let rarity: ChestRarity
        if roll < 0.05 && store.hasPremiumChest && store.premiumAvailableToday {
            rarity = .premium
        } else if roll < 0.30 {
            rarity = .rare
        } else {
            rarity = .common
        }

        let title: String
        switch rarity {
        case .common: title = "+50 Moedas TrilhaGO"
        case .rare: title = "20% OFF em \(store.name)"
        case .premium: title = "Vale-Brinde Premium — \(store.name)"
        }

        let prefix = rarity == .premium ? "PREM" : (rarity == .rare ? "RARE" : "COM")
        let token = "TRILHA-\(prefix)-\(UUID().uuidString.prefix(6).uppercased())"
        return ChestClaimResponse(ok: true, rarity: rarity, rewardTitle: title, qrToken: token, error: nil)
    }
}
