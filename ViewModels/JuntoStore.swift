import SwiftUI
import Combine

@MainActor
final class JuntoStore: ObservableObject {
    @Published var route: AppRoute = .welcomeAuth
    @Published var selectedTab: MainTab = .friends
    @Published var openCreateGroupWithCategory: String? = nil

    @Published var user = UserProfile(
        fullName: "Lucas Andrade",
        username: "lucas.andrade",
        email: "lucas.andrade@exemplo.com",
        country: CountryOption.all[0],
        phone: "(11) 91234-5678",
        pixKey: "lucas.andrade@exemplo.com"
    )

    // Cadastro temporário (1 campo por tela)
    @Published var draftEmail: String = ""
    @Published var draftUsername: String = ""
    @Published var draftPassword: String = ""
    @Published var draftFullName: String = ""
    @Published var draftCountry: CountryOption = CountryOption.all[0]
    @Published var draftPhone: String = ""
    @Published var usernameState: UsernameCheckState = .idle

    // Mocks realistas e completos para testar imediatamente
    @Published var friends: [FriendItem] = [
        FriendItem(name: "Pedro Santos", username: "pedro.santos", initials: "PS", balance: 100.00),
        FriendItem(name: "Camila Rocha", username: "camila.rocha", initials: "CR", balance: 70.00),
        FriendItem(name: "Matheus Alves", username: "matheus.alves", initials: "MA", balance: -35.36),
        FriendItem(name: "Beatriz Lima", username: "bia.lima", initials: "BL", balance: 0.0)
    ]

    @Published var groups: [RoleGroup] = [
        RoleGroup(
            title: "Viagem Ubatuba",
            category: "Viagem",
            coverImageName: "GroupPraia",
            potBalance: 640.00,
            potTarget: 1000.00,
            totalSpent: 1840.00,
            myShare: 0.0,
            members: ["EU", "PS", "MA", "CR", "BL"],
            hasCollectivePot: true,
            comandaItems: [
                ComandaItem(name: "Casa de Praia (Diária)", detail: "1/5 da reserva", price: 110.00, isSelected: true),
                ComandaItem(name: "Gasolina + Pedágio", detail: "Carro do Pedro", price: 40.00, isSelected: true)
            ]
        ),
        RoleGroup(
            title: "Churrasco de Domingo",
            category: "Outros",
            coverImageName: "GroupChurrasco",
            potBalance: 180.00,
            potTarget: 300.00,
            totalSpent: 420.00,
            myShare: 35.36,
            members: ["EU", "PS", "MA", "CR"],
            hasCollectivePot: true,
            comandaItems: [
                ComandaItem(name: "Picanha Premium (Rateio)", detail: "Dividido por 4", price: 24.00, isSelected: true),
                ComandaItem(name: "Carvão, Gelo & Pão de Alho", detail: "Rateio geral", price: 11.36, isSelected: true),
                ComandaItem(name: "Pack Cerveja Artesanal", detail: "Quem bebe álcool", price: 28.00, isSelected: false)
            ]
        ),
        RoleGroup(
            title: "Contas do Apê 402",
            category: "Casa",
            coverImageName: "GroupBar",
            potBalance: 0.0,
            potTarget: 0.0,
            totalSpent: 980.00,
            myShare: 145.00,
            members: ["EU", "MA", "BL"],
            hasCollectivePot: false,
            comandaItems: [
                ComandaItem(name: "Internet Fibra 500Mb", detail: "Dividido por 3", price: 45.00, isSelected: true),
                ComandaItem(name: "Energia + Condomínio", detail: "Rateio mensal", price: 100.00, isSelected: true)
            ]
        )
    ]

    @Published var activities: [ActivityEvent] = [
        ActivityEvent(icon: "checkmark.circle", title: "Pedro Santos pagou via Pix", subtitle: "Viagem Ubatuba • Baixa automática", timeAgo: "Há 8 min", amountText: "+ R$ 100,00", isPositive: true),
        ActivityEvent(icon: "list.bullet.rectangle.portrait", title: "Comanda dividida com IA", subtitle: "Churrasco de Domingo • 3 itens", timeAgo: "Há 1 hora", amountText: "R$ 63,36", isPositive: true),
        ActivityEvent(icon: "dollarsign.circle", title: "Camila contribuiu no Pote", subtitle: "Viagem Ubatuba • Saldo R$ 640,00", timeAgo: "Ontem", amountText: "+ R$ 150,00", isPositive: true),
        ActivityEvent(icon: "house", title: "Matheus adicionou \"Internet Fibra\"", subtitle: "Contas do Apê 402", timeAgo: "Há 2 dias", amountText: "R$ 135,00", isPositive: false)
    ]

    // Diretório de usuários para busca em tempo real letra por letra
    let directoryUsers: [SearchableUser] = [
        SearchableUser(name: "Ana Paula Silva", username: "ana.paula"),
        SearchableUser(name: "Bruno Mendes", username: "bruno.mendes"),
        SearchableUser(name: "Carla Teixeira", username: "carla.teixeira"),
        SearchableUser(name: "Daniela Souza", username: "dani.souza"),
        SearchableUser(name: "Eduardo Martins", username: "edu.martins"),
        SearchableUser(name: "Felipe Rocha", username: "felipe.rocha"),
        SearchableUser(name: "Gabriela Costa", username: "gabi.costa"),
        SearchableUser(name: "Henrique Dias", username: "henrique.dias"),
        SearchableUser(name: "Juliana Ferreira", username: "ju.ferreira"),
        SearchableUser(name: "Mariana Alves", username: "mari.alves"),
        SearchableUser(name: "Rafael Nunes", username: "rafa.nunes"),
        SearchableUser(name: "Thiago Oliveira", username: "thiago.oliveira"),
        SearchableUser(name: "Vitória Lima", username: "vitoria.lima")
    ]

    @Published var sentInviteUsernames: Set<String> = []

    @Published var notifications: [AppNotification] = [
        AppNotification(icon: "bolt", title: "Pix recebido na hora", message: "Pedro Santos quitou R$ 100,00 com baixa automática.", timeAgo: "8 min", isUnread: true),
        AppNotification(icon: "person.2", title: "Pote Coletivo atualizado", message: "Camila adicionou R$ 150,00 na Viagem Ubatuba.", timeAgo: "1h", isUnread: true),
        AppNotification(icon: "doc.text.viewfinder", title: "Comanda pronta", message: "Toque para marcar o que você consumiu no Churrasco.", timeAgo: "3h", isUnread: false)
    ]

    @Published var blockedUsernames: [String] = []
    @Published var activePixSheet: PixChargeSheetData? = nil
    @Published var showAddExpenseSheet: Bool = false

    @Published var toastMessage: String? = nil
    @Published var toastIcon: String = "checkmark.circle"
    private var toastTask: Task<Void, Never>? = nil
    private var usernameCheckTask: Task<Void, Never>? = nil

    private let takenUsernames: Set<String> = ["admin", "pedro", "matheus", "camila", "junto", "teste", "suporte"]

    var unreadNotificationsCount: Int {
        notifications.filter { $0.isUnread }.count
    }

    var netBalance: Double {
        friends.reduce(0) { $0 + $1.balance }
    }

    static func formatBRL(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.currencyCode = "BRL"
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "R$ %.2f", value)
    }

    func checkUsername(_ raw: String) {
        let cleaned = raw
            .lowercased()
            .replacingOccurrences(of: "@", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        usernameCheckTask?.cancel()

        if cleaned.isEmpty {
            usernameState = .idle
            return
        }
        if cleaned.count < 3 {
            usernameState = .tooShort
            return
        }

        usernameState = .checking
        usernameCheckTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            usernameState = takenUsernames.contains(cleaned) ? .unavailable : .available
        }
    }

    func login(identifier: String) {
        let clean = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.isEmpty {
            if clean.contains("@") { user.email = clean } else { user.username = clean.lowercased() }
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            route = .main
        }
    }

    func completeRegistration() {
        let cleanName = draftFullName.trimmingCharacters(in: .whitespacesAndNewlines)
        user = UserProfile(
            fullName: cleanName.isEmpty ? "Novo usuário" : cleanName,
            username: draftUsername.replacingOccurrences(of: "@", with: "").lowercased(),
            email: draftEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            country: draftCountry,
            phone: draftPhone,
            pixKey: draftEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        withAnimation(.easeInOut(duration: 0.28)) {
            route = .welcomeSlides
        }
    }

    func finishSlidesToGetStarted() {
        withAnimation(.easeInOut(duration: 0.28)) {
            route = .getStarted
        }
    }

    func startApp(openingGroupCategory: String? = nil) {
        if let cat = openingGroupCategory {
            selectedTab = .groups
            openCreateGroupWithCategory = cat
        } else {
            selectedTab = .friends
        }
        withAnimation(.easeInOut(duration: 0.28)) {
            route = .main
        }
    }

    func isInviteSent(for username: String) -> Bool {
        let clean = username.lowercased().replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        return sentInviteUsernames.contains(clean) || friends.contains(where: { $0.username.lowercased() == clean })
    }

    func sendFriendInvite(username raw: String, displayName customName: String? = nil) {
        let clean = raw
            .lowercased()
            .replacingOccurrences(of: "@", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard clean.count >= 3 else {
            showToast("Digite um nome de usuário válido.", icon: "exclamationmark.circle")
            return
        }

        // Impede reenvio duplicado ao clicar novamente
        if isInviteSent(for: clean) {
            return
        }

        if blockedUsernames.contains(clean) {
            showToast("Este usuário está bloqueado.", icon: "hand.raised")
            return
        }

        sentInviteUsernames.insert(clean)

        let displayName = customName ?? clean
            .split(separator: ".")
            .map { $0.capitalized }
            .joined(separator: " ")

        let initials = String(clean.prefix(2)).uppercased()
        friends.insert(
            FriendItem(name: displayName, username: clean, initials: initials, balance: 0, isPendingInvite: true),
            at: 0
        )
        activities.insert(
            ActivityEvent(
                icon: "person.badge.plus",
                title: "Convite enviado para \(displayName)",
                subtitle: "@\(clean) • Aguardando confirmação",
                timeAgo: "Agora",
                amountText: nil,
                isPositive: true
            ),
            at: 0
        )
        showToast("Convite enviado para @\(clean).", icon: "paperplane")
    }

    /// Cancela / desfaz o convite enviado (comportamento toggle igual Instagram Seguir / Solicitado)
    func cancelFriendInvite(username raw: String) {
        let clean = raw
            .lowercased()
            .replacingOccurrences(of: "@", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        sentInviteUsernames.remove(clean)
        friends.removeAll { $0.username.lowercased() == clean && $0.isPendingInvite }
        showToast("Convite para @\(clean) cancelado.", icon: "xmark.circle")
    }

    /// Contribuição real no Pote Coletivo do grupo (atualiza saldo + registra atividade + abre Pix)
    func contributeToPot(groupId: UUID, amount: Double) {
        guard amount > 0, let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[idx].potBalance += amount
        let groupTitle = groups[idx].title

        activities.insert(
            ActivityEvent(
                icon: "dollarsign.circle",
                title: "Você contribuiu no Pote",
                subtitle: "\(groupTitle) • Saldo \(Self.formatBRL(groups[idx].potBalance))",
                timeAgo: "Agora",
                amountText: "+ \(Self.formatBRL(amount))",
                isPositive: true
            ),
            at: 0
        )

        openPixPayment(title: "Pote • \(groupTitle)", recipient: "Pote Coletivo \(groupTitle)", amount: amount)
    }

    /// Adiciona despesa real dentro de um grupo (atualiza comanda, total e sua cota)
    func addExpenseToGroup(groupId: UUID, name: String, totalAmount: Double, payFromPot: Bool) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, totalAmount > 0,
              let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }

        let memberCount = max(groups[idx].members.count, 1)
        let perPerson = totalAmount / Double(memberCount)

        if payFromPot && groups[idx].hasCollectivePot {
            groups[idx].potBalance = max(0, groups[idx].potBalance - totalAmount)
        } else {
            groups[idx].myShare += perPerson
        }

        groups[idx].totalSpent += totalAmount
        groups[idx].comandaItems.insert(
            ComandaItem(
                name: cleanName,
                detail: payFromPot ? "Pago com o Pote" : "Dividido por \(memberCount)",
                price: perPerson,
                isSelected: !payFromPot
            ),
            at: 0
        )

        activities.insert(
            ActivityEvent(
                icon: "list.bullet.rectangle.portrait",
                title: "Você adicionou \"\(cleanName)\"",
                subtitle: groups[idx].title,
                timeAgo: "Agora",
                amountText: Self.formatBRL(totalAmount),
                isPositive: false
            ),
            at: 0
        )
        showToast("Despesa \"\(cleanName)\" adicionada.", icon: "checkmark.circle")
    }

    /// Adiciona membro real ao grupo
    func addMemberToGroup(groupId: UUID, memberUsername: String) {
        let clean = memberUsername.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "").lowercased()
        guard clean.count >= 2, let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }

        let initials = String(clean.prefix(2)).uppercased()
        if !groups[idx].members.contains(initials) {
            groups[idx].members.append(initials)
            activities.insert(
                ActivityEvent(
                    icon: "person.badge.plus",
                    title: "@\(clean) entrou no grupo",
                    subtitle: groups[idx].title,
                    timeAgo: "Agora",
                    amountText: nil,
                    isPositive: true
                ),
                at: 0
            )
            showToast("@\(clean) adicionado ao grupo.", icon: "person.badge.plus")
        }
    }

    func createNewGroup(title: String, category: String, hasPot: Bool) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            showToast("Informe o nome do grupo.", icon: "exclamationmark.circle")
            return
        }

        let cover: String
        switch category {
        case "Viagem": cover = "GroupPraia"
        case "Casal": cover = "GroupBar"
        default: cover = "GroupChurrasco"
        }

        let newGroup = RoleGroup(
            title: cleanTitle,
            category: category,
            coverImageName: cover,
            potBalance: 0,
            potTarget: hasPot ? 300 : 0,
            totalSpent: 0,
            myShare: 0,
            members: ["EU"],
            hasCollectivePot: hasPot,
            comandaItems: []
        )

        groups.insert(newGroup, at: 0)
        activities.insert(
            ActivityEvent(
                icon: "person.2",
                title: "Você criou o grupo \"\(cleanTitle)\"",
                subtitle: category,
                timeAgo: "Agora",
                amountText: nil,
                isPositive: true
            ),
            at: 0
        )
        showToast("Grupo \"\(cleanTitle)\" criado.", icon: "checkmark.circle")
    }

    func addQuickExpense(description: String, amount: Double, groupTitle: String) {
        let cleanDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanDesc.isEmpty, amount > 0 else {
            showToast("Informe descrição e valor.", icon: "exclamationmark.circle")
            return
        }

        activities.insert(
            ActivityEvent(
                icon: "receipt",
                title: "Você adicionou \"\(cleanDesc)\"",
                subtitle: groupTitle.isEmpty ? "Despesa dividida igualmente" : groupTitle,
                timeAgo: "Agora",
                amountText: Self.formatBRL(amount),
                isPositive: true
            ),
            at: 0
        )
        showToast("Despesa adicionada.", icon: "checkmark.circle")
    }

    func openPixPayment(title: String, recipient: String, amount: Double) {
        let formattedValue = String(format: "%.2f", amount)
        let payload = "00020126420014br.gov.bcb.pix0120\(user.pixKey)520400005303986540\(formattedValue.count)\(formattedValue)5802BR5910JUNTO APP6009SAO PAULO62070503***6304E1F9"
        activePixSheet = PixChargeSheetData(
            title: title,
            recipientName: recipient,
            amount: amount,
            pixPayload: payload
        )
    }

    func refundPotRemainder(for groupId: UUID) {
        guard let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }
        let remainder = groups[idx].potBalance
        guard remainder > 0 else {
            showToast("Sem saldo restante no pote.", icon: "info.circle")
            return
        }
        let perPerson = remainder / Double(max(groups[idx].members.count, 1))
        groups[idx].potBalance = 0
        activities.insert(
            ActivityEvent(
                icon: "arrow.uturn.left",
                title: "Sobra devolvida por Pix",
                subtitle: "\(groups[idx].title) • \(Self.formatBRL(perPerson)) por pessoa",
                timeAgo: "Agora",
                amountText: "+ \(Self.formatBRL(perPerson))",
                isPositive: true
            ),
            at: 0
        )
        showToast("Sobra de \(Self.formatBRL(perPerson)) devolvida via Pix.", icon: "bolt")
    }

    func markAllNotificationsRead() {
        for i in notifications.indices { notifications[i].isUnread = false }
    }

    func blockUser(_ raw: String) {
        let clean = raw.lowercased().replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count >= 2 else { return }
        if !blockedUsernames.contains(clean) {
            blockedUsernames.insert(clean, at: 0)
            showToast("@\(clean) adicionado à lista de bloqueios.", icon: "hand.raised")
        }
    }

    func unblockUser(_ username: String) {
        blockedUsernames.removeAll { $0 == username }
        showToast("@\(username) removido dos bloqueios.", icon: "checkmark.circle")
    }

    func disconnectAllDevices() {
        showToast("Todas as outras sessões foram desconectadas.", icon: "lock.shield")
    }

    func deleteAccountPermanently() {
        draftEmail = ""
        draftUsername = ""
        draftPassword = ""
        draftFullName = ""
        draftPhone = ""
        withAnimation(.easeInOut(duration: 0.25)) {
            route = .welcomeAuth
        }
        showToast("Conta desativada. Dados retidos por 90 dias (LGPD).", icon: "trash")
    }

    func logout() {
        withAnimation(.easeInOut(duration: 0.25)) {
            route = .welcomeAuth
        }
    }

    func showToast(_ message: String, icon: String = "checkmark.circle") {
        toastTask?.cancel()
        toastIcon = icon
        withAnimation(.easeOut(duration: 0.2)) {
            toastMessage = message
        }
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                toastMessage = nil
            }
        }
    }
}
