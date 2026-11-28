import Foundation
import CoreLocation
import SwiftUI

enum TrilhaTeam: String, CaseIterable, Identifiable, Codable {
    case esmeralda
    case horizonte
    case solar

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .esmeralda: return "Esmeralda"
        case .horizonte: return "Horizonte"
        case .solar: return "Solar"
        }
    }

    var color: Color {
        switch self {
        case .esmeralda: return TrilhaColors.emerald
        case .horizonte: return Color(hex: "#0EA5E9")
        case .solar: return Color(hex: "#F59E0B")
        }
    }
}

enum SportMode: String, CaseIterable, Identifiable, Codable {
    case walk
    case run
    case bike

    var id: String { rawValue }

    var title: String {
        switch self {
        case .walk: return "Caminhada"
        case .run: return "Corrida"
        case .bike: return "Ciclismo"
        }
    }

    var iconName: String {
        switch self {
        case .walk: return "icon_walk"
        case .run: return "icon_run"
        case .bike: return "icon_bike"
        }
    }

    var maxSpeedKmh: Double {
        switch self {
        case .walk, .run: return 20.0
        case .bike: return 35.0
        }
    }

    var kcalPerKm: Double {
        switch self {
        case .walk: return 55
        case .run: return 75
        case .bike: return 34
        }
    }
}

enum ChestRarity: String, Codable {
    case common
    case rare
    case premium

    var title: String {
        switch self {
        case .common: return "Baú Comum"
        case .rare: return "Baú Raro"
        case .premium: return "Baú Premium"
        }
    }

    var assetName: String {
        self == .premium ? "obj_chest_premium" : "obj_chest_common"
    }
}

struct StoreLocation: Identifiable, Hashable {
    let id: UUID
    let name: String
    let category: String
    let coordinate: CLLocationCoordinate2D
    let hasPremiumChest: Bool
    let premiumWindowLabel: String
    let promoTitle: String
    var premiumAvailableToday: Bool

    static func == (lhs: StoreLocation, rhs: StoreLocation) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct TerritoryHex: Identifiable, Hashable {
    let id: String // H3 index simulado res 9/10
    let center: CLLocationCoordinate2D
    let vertices: [CLLocationCoordinate2D]
    var ownerTeam: TrilhaTeam?
    var points: Int

    static func == (lhs: TerritoryHex, rhs: TerritoryHex) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct CouponQR: Identifiable, Codable {
    let id: UUID
    let storeName: String
    let rarity: ChestRarity
    let rewardTitle: String
    let qrToken: String
    let createdAt: Date
    var redeemedAt: Date?
}

struct WorkoutSummary: Identifiable {
    let id = UUID()
    let mode: SportMode
    let distanceMeters: Double
    let durationSeconds: Int
    let calories: Int
    let avgPaceMinPerKm: Double
    let keysEarned: Int
    let xpEarned: Int
    let territoriesConquered: Int
    let route: [CLLocationCoordinate2D]
}

struct RankingEntry: Identifiable {
    let id = UUID()
    let position: Int
    let playerName: String
    let team: TrilhaTeam
    let territoriesCount: Int
    let distanceKm: Double
}
