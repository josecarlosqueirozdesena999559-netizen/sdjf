import Foundation

enum AppRoute {
    case welcomeAuth     // Tela inicial com logo Juntô + Cadastrar-se / Entrar
    case login
    case registerFlow    // Cadastro 1 campo por tela (5 passos fluidos)
    case welcomeSlides   // Carrossel animado de boas-vindas (3 slides inspirados no vídeo)
    case getStarted      // Tela "Vamos começar!" (Criar rolê/viagem, Casa ou Pular)
    case main
}

enum ProPlanType: String, Codable, Hashable {
    case none
    case monthly
    case yearly

    var displayName: String {
        switch self {
        case .none: return "Gratuito"
        case .monthly: return "Mensal"
        case .yearly: return "Anual"
        }
    }
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
        case .activities: return "Lançamentos"
        case .account: return "Conta"
        }
    }

    var icon: String {
        switch self {
        case .friends: return "person"
        case .groups: return "person.2"
        case .activities: return "arrow.up.arrow.down.circle"
        case .account: return "person.crop.circle"
        }
    }
}

// MARK: - Conversa Unificada (WhatsApp Real: amigos e grupos ordenados juntos por atividade mais recente)
enum UnifiedChatItem: Identifiable, Equatable {
    case friend(FriendItem, Date)
    case group(RoleGroup, Date)

    var id: String {
        switch self {
        case .friend(let f, _): return "f_\(f.id.uuidString)"
        case .group(let g, _): return "g_\(g.id.uuidString)"
        }
    }

    var lastActivityDate: Date {
        switch self {
        case .friend(_, let d): return d
        case .group(_, let d): return d
        }
    }

    var title: String {
        switch self {
        case .friend(let f, _): return f.name
        case .group(let g, _): return g.title
        }
    }

    var searchKeywords: String {
        switch self {
        case .friend(let f, _): return "\(f.name) \(f.username)"
        case .group(let g, _): return "\(g.title) \(g.category)"
        }
    }

    static func == (lhs: UnifiedChatItem, rhs: UnifiedChatItem) -> Bool {
        lhs.id == rhs.id && lhs.lastActivityDate == rhs.lastActivityDate
    }
}

enum UsernameCheckState {
    case idle
    case tooShort
    case checking
    case available
    case unavailable
}

struct CountryOption: Identifiable, Hashable, Codable {
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

struct UserProfile: Codable {
    var fullName: String
    var username: String
    var email: String
    var country: CountryOption
    var phone: String
    var pixKey: String
    var timezone: String = "(GMT-03:00) Brasília"
    var currency: String = "BRL"
    var language: String = "Português (Brasil)"
    var allowRecommendations: Bool = true
    var avatarData: Data? = nil
    var isPro: Bool = false
    var proPlanType: ProPlanType = .none
    var proPlanName: String? = nil
    var proExpiresDateText: String? = nil
    var proExpiresAt: Date? = nil

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
    var proPlanType: ProPlanType = .none
}

enum MessageDeliveryStatus: String, Hashable {
    case sent       // Não entregue (1 traço)
    case delivered  // Entregue (2 traços)
    case read       // Lido (2 traços coloridos)
}

struct ChatPollOption: Identifiable, Hashable {
    let id = UUID()
    var text: String
    var voterUsernames: [String] = []
}

struct ChatPollData: Hashable {
    var question: String
    var options: [ChatPollOption]
    var allowMultipleAnswers: Bool = false

    var totalVotes: Int {
        options.reduce(0) { $0 + $1.voterUsernames.count }
    }
}

enum ReceiptStatus: String, Codable, Hashable {
    case pending = "Pendente de conferência"
    case approved = "Confirmado pelo Dono"
    case rejected = "Recusado"
}

enum ChatMessageKind: Hashable {
    case text(String)
    case photo(Data?, String)
    case audio(duration: Int, waveform: [Double], fileURL: URL?)
    case document(String, String)
    case poll(ChatPollData)
    case system(String)
    case receipt(amount: Double, imageData: Data?, fileName: String?, status: ReceiptStatus)
}

struct ChatMessage: Identifiable, Hashable {
    var id: UUID = UUID()
    let isFromMe: Bool
    var kind: ChatMessageKind
    let timeText: String
    var dateLabel: String = "Hoje" // ex: "Ontem", "Hoje", "18 de nov."
    var createdAt: Date = Date()
    var isEdited: Bool = false
    var isListened: Bool = false
    var status: MessageDeliveryStatus = .sent
    var senderName: String? = nil
    var senderUsername: String? = nil
    var senderProPlanType: ProPlanType = .none
    var replyToAuthor: String? = nil
    var replyToPreview: String? = nil

    var previewText: String {
        switch kind {
        case .text(let txt): return txt
        case .photo(_, let caption): return caption.isEmpty ? "Foto" : "Foto: \(caption)"
        case .audio(let secs, _, _): return "Áudio (0:\(String(format: "%02d", secs)))"
        case .document(let name, _): return "Documento: \(name)"
        case .poll(let poll): return "Enquete: \(poll.question)"
        case .system(let info): return info
        case .receipt(let amt, _, _, let status): return "Comprovante Pix (R$ \(String(format: "%.2f", amt))) • \(status.rawValue)"
        }
    }
}

struct FriendItem: Identifiable {
    let id = UUID()
    let name: String
    let username: String
    let initials: String
    var balance: Double
    var proPlanType: ProPlanType = .none
    var isPendingInvite: Bool = false
    var isOnline: Bool = false
    var isTyping: Bool = false
    var lastSeenText: String = "visto por último hoje às 18:10"
    var friendsSinceText: String = "14 de mar. de 2026"
    var isMuted: Bool = false
}

struct PersonalExpenseRecord: Identifiable {
    var id: UUID = UUID()
    let title: String
    let category: String
    let amount: Double
    let dateText: String
    let monthKey: String // ex: "Novembro 2026", "Outubro 2026"
    let groupName: String
    var isPaid: Bool = false
}

struct ComandaItem: Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var detail: String = ""
    var price: Double               // Preço total do item
    var isSelected: Bool = true     // Se está ativo no checklist de inclusão
    var quantity: Int = 1           // Quantidade
    var unitPrice: Double = 0.0     // Preço unitário
    var isPaid: Bool = false        // Se já foi conferido/quitado
    var assignedUsernames: Set<String> = [] // Quem consumiu (se vazio, divide por todos)

    init(
        id: UUID = UUID(),
        name: String,
        detail: String = "",
        price: Double,
        isSelected: Bool = true,
        quantity: Int = 1,
        unitPrice: Double? = nil,
        isPaid: Bool = false,
        assignedUsernames: Set<String> = []
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.price = price
        self.isSelected = isSelected
        let q = max(1, quantity)
        self.quantity = q
        self.unitPrice = unitPrice ?? (price / Double(q))
        self.isPaid = isPaid
        self.assignedUsernames = assignedUsernames
    }

    /// Valor por consumidor deste item
    func sharePerConsumer(totalMembersCount: Int) -> Double {
        let consumers = assignedUsernames.isEmpty ? max(1, totalMembersCount) : assignedUsernames.count
        return price / Double(max(1, consumers))
    }
}

enum GroupParticipantRole: String, Hashable {
    case owner = "Dono"
    case admin = "Admin"
    case member = "Membro"
}

enum PotRecurrenceMode: String, CaseIterable, Hashable {
    case single = "Meta única"
    case monthly = "Mensal"
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
    var proPlanType: ProPlanType = .none
}

struct RoleGroup: Identifiable {
    var id: UUID = UUID()
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
    var ownerUsername: String = "lucas.andrade"
    var ownerName: String = "Lucas Andrade"
    var ownerPixKey: String = "lucas.andrade@exemplo.com"

    // Pote Mensal (Excursões / Viagens parceladas mês a mês)
    var potMode: PotRecurrenceMode = .single
    var totalMonths: Int = 1
    var selectedMonthIndex: Int = 0
    var monthlyCycles: [PotMonthCycle] = []

    // Grupo Público (Descoberta na aba Próximos)
    var isPublic: Bool = false
    var maxParticipants: Int = 100
    var publicUntilDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    var locationText: String = "São Paulo, SP"
    var distanceKm: Double = 1.8

    /// Grupo lotado (atingiu a capacidade máxima definida pelo admin de até 100 participantes)
    var isFull: Bool {
        participants.count >= maxParticipants
    }

    /// Visível na aba de Próximos:
    /// 1. Deve ser público
    /// 2. NÃO pode estar lotado (ao preencher as vagas ele não aparece para entrarem; saiu um fica disponível novamente!)
    /// 3. Não pode ter expirado o prazo definido pelo admin
    var isPublicActive: Bool {
        isPublic && !isFull && Date() <= publicUntilDate
    }

    /// Quantidade de vagas restantes no grupo
    var remainingSlots: Int {
        max(0, maxParticipants - participants.count)
    }

    /// Cota recalculada dinamicamente conforme novas pessoas entram
    var dynamicQuotaPerPerson: Double {
        guard potTarget > 0 else { return 0 }
        let months = potMode == .monthly ? max(1, totalMonths) : 1
        let count = max(1, participants.count)
        return (potTarget / Double(months)) / Double(count)
    }

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

/// Usuário descoberto pelo algoritmo de proximidade (raio de km e bairro)
struct NearbyUserItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let username: String
    var distanceMeters: Int
    let neighborhood: String
    let mutualFriendsCount: Int
    let interests: [String]
    var proPlanType: ProPlanType = .none
    var isInvited: Bool = false
    var isFriend: Bool = false

    var distanceText: String {
        if distanceMeters < 1000 {
            return "\(distanceMeters) m"
        } else {
            let km = Double(distanceMeters) / 1000.0
            return String(format: "%.1f km", km)
        }
    }
}
