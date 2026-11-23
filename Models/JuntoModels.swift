import Foundation

enum AppRoute {
    case welcomeAuth     // Tela inicial com logo Juntô + Cadastrar-se / Entrar
    case login
    case registerFlow    // Cadastro 1 campo por tela (5 passos fluidos)
    case welcomeSlides   // Carrossel animado de boas-vindas (3 slides inspirados no vídeo)
    case getStarted      // Tela "Vamos começar!" (Criar rolê/viagem, Casa ou Pular)
    case main
}

enum MainTab: Int, CaseIterable {
    case friends = 0
    case groups = 1
    case activities = 2
    case account = 3

    var title: String {
        switch self {
        case .friends: return "Amigos"
        case .groups: return "Grupos"
        case .activities: return "Atividade"
        case .account: return "Conta"
        }
    }

    var icon: String {
        switch self {
        case .friends: return "person"
        case .groups: return "person.2"
        case .activities: return "arrow.left.arrow.right.circle"
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
    var timezone: String = "(GMT-03:00) Brasília"
    let currency: String = "BRL"
    var language: String = "Português (Brasil)"
    var allowRecommendations: Bool = true
    var avatarData: Data? = nil

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

struct SearchableUser: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let username: String
}

enum ChatMessageKind: Hashable {
    case text(String)
    case photo(Data?, String) // imagem opcional + legenda
    case audio(Int)           // duração em segundos
    case document(String, String) // nome do arquivo + tamanho
}

struct ChatMessage: Identifiable, Hashable {
    let id = UUID()
    let isFromMe: Bool
    let kind: ChatMessageKind
    let timeText: String
}

struct FriendItem: Identifiable {
    let id = UUID()
    let name: String
    let username: String
    let initials: String
    var balance: Double
    var isPendingInvite: Bool = false
    var isOnline: Bool = false
    var lastSeenText: String = "visto por último hoje às 18:10"
}

struct ComandaItem: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let price: Double
    var isSelected: Bool
}

enum GroupParticipantRole: String, Hashable {
    case owner = "Dono"
    case admin = "Admin"
    case member = "Membro"
}

struct GroupParticipant: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let username: String
    var quotaAmount: Double
    var hasPaid: Bool
    var role: GroupParticipantRole = .member
}

struct RoleGroup: Identifiable {
    let id = UUID()
    var title: String
    var category: String
    var coverImageName: String
    var coverImageData: Data? = nil
    var potBalance: Double
    var potTarget: Double
    var totalSpent: Double
    var myShare: Double
    var members: [String]
    var participants: [GroupParticipant]
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
