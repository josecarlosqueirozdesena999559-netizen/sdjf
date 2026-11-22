import Foundation

enum AppRoute {
    case login
    case registerStep1
    case registerStep2
    case welcome
    case main
}

enum MainTab: Int, CaseIterable {
    case groups = 0
    case friends = 1
    case activities = 2
    case account = 3

    var title: String {
        switch self {
        case .groups: return "Grupos"
        case .friends: return "Amigos"
        case .activities: return "Atividades"
        case .account: return "Conta"
        }
    }

    var icon: String {
        switch self {
        case .groups: return "sparkles.rectangle.stack"
        case .friends: return "person.2"
        case .activities: return "bolt.horizontal.circle"
        case .account: return "person.crop.circle"
        }
    }
}

enum UsernameCheckState {
    case idle
    case tooShort
    case checking
    case available
    case unavailable
}

struct CountryOption: Identifiable, Hashable {
    let id: String
    let name: String
    let flag: String
    let dialCode: String

    static let all: [CountryOption] = [
        CountryOption(id: "BR", name: "Brasil", flag: "🇧🇷", dialCode: "+55"),
        CountryOption(id: "PT", name: "Portugal", flag: "🇵🇹", dialCode: "+351"),
        CountryOption(id: "US", name: "Estados Unidos", flag: "🇺🇸", dialCode: "+1"),
        CountryOption(id: "AR", name: "Argentina", flag: "🇦🇷", dialCode: "+54")
    ]
}

struct UserProfile {
    var fullName: String
    var username: String
    var email: String
    var country: CountryOption
    var phone: String
    var pixKey: String
    let currency: String = "BRL"
    var avatarData: Data? = nil
    var avatarEmoji: String? = nil

    var firstName: String {
        fullName.split(separator: " ").first.map(String.init) ?? "Amigo"
    }

    var initials: String {
        let parts = fullName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(fullName.prefix(2)).uppercased()
    }
}

struct FriendItem: Identifiable {
    let id = UUID()
    let name: String
    let username: String
    let initials: String
    var balance: Double // > 0 te deve, < 0 você deve, 0 zerado
    var isPendingInvite: Bool = false
}

struct ComandaItem: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let price: Double
    var isSelected: Bool
}

struct RoleGroup: Identifiable {
    let id = UUID()
    var title: String
    var category: String
    var coverImageName: String
    var potBalance: Double
    var potTarget: Double
    var totalSpent: Double
    var myShare: Double
    var members: [String]
    var hasCollectivePot: Bool
    var comandaItems: [ComandaItem]
}

struct ActivityEvent: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let timeAgo: String
    let amountText: String?
    let isPositive: Bool
}

struct AppNotification: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let message: String
    let timeAgo: String
    var isUnread: Bool
}

struct PixChargeSheetData: Identifiable {
    let id = UUID()
    let title: String
    let recipientName: String
    let amount: Double
    let pixPayload: String
}
