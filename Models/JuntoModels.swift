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
    var isPro: Bool = false
    var proPlanName: String? = nil
    var proExpiresDateText: String? = nil

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

struct BlockedUserEntry: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let username: String
}

struct ConnectedDeviceSession: Identifiable, Hashable {
    let id = UUID()
    let deviceName: String
    let systemInfo: String
    let locationText: String
    let lastActiveText: String
    let isCurrentDevice: Bool
}

struct SearchableUser: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let username: String
}

enum MessageDeliveryStatus: String, Hashable {
    case sent       // Não entregue (1 traço)
    case delivered  // Entregue (2 traços)
    case read       // Lido (2 traços coloridos)
}

enum ChatMessageKind: Hashable {
    case text(String)
    case photo(Data?, String)
    case audio(duration: Int, waveform: [Double], fileURL: URL?)
    case document(String, String)
    case system(String)
}

struct ChatMessage: Identifiable, Hashable {
    let id = UUID()
    let isFromMe: Bool
    var kind: ChatMessageKind
    let timeText: String
    var dateLabel: String = "Hoje" // ex: "Ontem", "Hoje", "18 de nov."
    var isEdited: Bool = false
    var isListened: Bool = false
    var status: MessageDeliveryStatus = .sent
    var senderName: String? = nil
    var senderUsername: String? = nil
    var replyToAuthor: String? = nil
    var replyToPreview: String? = nil

    var previewText: String {
        switch kind {
        case .text(let txt): return txt
        case .photo(_, let caption): return caption.isEmpty ? "Foto" : "Foto: \(caption)"
        case .audio(let secs, _, _): return "Áudio (0:\(String(format: "%02d", secs)))"
        case .document(let name, _): return "Documento: \(name)"
        case .system(let info): return info
        }
    }
}

struct FriendItem: Identifiable {
    let id = UUID()
    let name: String
    let username: String
    let initials: String
    var balance: Double
    var isPendingInvite: Bool = false
    var isOnline: Bool = false
    var isTyping: Bool = false
    var lastSeenText: String = "visto por último hoje às 18:10"
    var friendsSinceText: String = "14 de mar. de 2026"
    var isMuted: Bool = false
}

struct PersonalExpenseRecord: Identifiable {
    let id = UUID()
    let title: String
    let category: String
    let amount: Double
    let dateText: String
    let monthKey: String // ex: "Novembro 2026", "Outubro 2026"
    let groupName: String
    var isPaid: Bool = false
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

enum PotRecurrenceMode: String, CaseIterable, Hashable {
    case single = "Meta única"
    case monthly = "Mensal (Excursão)"
}

struct PotMonthCycle: Identifiable, Hashable {
    let id = UUID()
    let monthNumber: Int
    let label: String // ex: "Mês 1 • Nov/26"
    var paidUsernames: Set<String> = []
    var markedPaidUsernames: Set<String> = []
}

struct GroupParticipant: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let username: String
    var quotaAmount: Double
    var hasPaid: Bool
    var markedPaidByMember: Bool = false
    var role: GroupParticipantRole = .member
}

struct RoleGroup: Identifiable {
    let id = UUID()
    var title: String
    var category: String
    var coverImageName: String
    var coverImageData: Data? = nil
    var startDate: Date = Date()
    var targetDate: Date = Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date()
    var potBalance: Double
    var potTarget: Double
    var totalSpent: Double
    var myShare: Double
    var members: [String]
    var participants: [GroupParticipant]
    var hasCollectivePot: Bool
    var comandaItems: [ComandaItem]

    // Pote Mensal (Excursões / Viagens parceladas mês a mês)
    var potMode: PotRecurrenceMode = .single
    var totalMonths: Int = 1
    var selectedMonthIndex: Int = 0
    var monthlyCycles: [PotMonthCycle] = []

    /// Porcentagem concluída de um mês específico (só chega a 100% quando TODOS os participantes pagam aquele mês)
    func monthCompletionPercent(at index: Int) -> Int {
        guard !participants.isEmpty else { return 0 }
        if potMode == .single {
            let paid = participants.filter { $0.hasPaid }.count
            return paid == participants.count ? 100 : min(99, Int((Double(paid) / Double(participants.count)) * 100))
        }
        guard monthlyCycles.indices.contains(index) else { return 0 }
        let paidCount = participants.filter { monthlyCycles[index].paidUsernames.contains($0.username.lowercased()) }.count
        if paidCount == participants.count { return 100 }
        return min(99, Int((Double(paidCount) / Double(participants.count)) * 100))
    }

    /// Quantos participantes pagaram no mês selecionado
    func paidParticipantsCount(at index: Int) -> Int {
        if potMode == .single {
            return participants.filter { $0.hasPaid }.count
        }
        guard monthlyCycles.indices.contains(index) else { return 0 }
        return participants.filter { monthlyCycles[index].paidUsernames.contains($0.username.lowercased()) }.count
    }

    /// Porcentagem total da meta geral (só chega a 100% quando TODOS pagam TODOS os meses)
    var overallGoalPercent: Int {
        guard !participants.isEmpty else { return 0 }
        if potMode == .single {
            let paid = participants.filter { $0.hasPaid }.count
            if paid == participants.count { return 100 }
            if potTarget > 0 {
                return min(99, Int((potBalance / potTarget) * 100))
            }
            return min(99, Int((Double(paid) / Double(participants.count)) * 100))
        }
        let totalSlots = max(1, participants.count * max(1, monthlyCycles.count))
        let paidSlots = monthlyCycles.reduce(0) { acc, cycle in
            acc + participants.filter { cycle.paidUsernames.contains($0.username.lowercased()) }.count
        }
        if paidSlots >= totalSlots { return 100 }
        return min(99, Int((Double(paidSlots) / Double(totalSlots)) * 100))
    }

    /// Quantos meses já estão 100% quitados por todos
    var completedMonthsCount: Int {
        guard !participants.isEmpty else { return 0 }
        return monthlyCycles.indices.filter { monthCompletionPercent(at: $0) == 100 }.count
    }

    /// Valor da mensalidade de 1 mês por pessoa
    var monthlyQuotaPerPerson: Double {
        guard !participants.isEmpty, potTarget > 0 else { return 0 }
        let months = potMode == .monthly ? max(1, totalMonths) : 1
        return (potTarget / Double(months)) / Double(participants.count)
    }

    /// Meta de arrecadação de 1 mês (soma de todos os membros naquele mês)
    var monthlyTargetAmount: Double {
        let months = potMode == .monthly ? max(1, totalMonths) : 1
        return potTarget / Double(months)
    }
}

/// Pote Pessoal ("Caixinha" individual para guardar dinheiro para uma ocasião especial — Recurso Juntô Pro)
struct PersonalSavingsPot: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var occasion: String // ex: "Viagem", "Show / Festival", "Reserva", "Presente"
    var icon: String     // SF Symbol nativo
    var currentAmount: Double
    var targetAmount: Double
    var targetDateText: String
    var deposits: [PersonalPotDeposit] = []

    var percentCompleted: Int {
        guard targetAmount > 0 else { return 0 }
        if currentAmount >= targetAmount { return 100 }
        return min(99, Int((currentAmount / targetAmount) * 100))
    }

    var remainingAmount: Double {
        max(0, targetAmount - currentAmount)
    }
}

struct PersonalPotDeposit: Identifiable, Hashable {
    let id = UUID()
    let amount: Double
    let note: String
    let dateText: String
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
    var isFriendRequest: Bool = false
    var requestUserName: String? = nil
    var requestUsername: String? = nil
}

struct PixChargeSheetData: Identifiable {
    let id = UUID()
    let title: String
    let recipientName: String
    let amount: Double
    let pixPayload: String
}
