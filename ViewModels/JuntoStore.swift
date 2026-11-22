import SwiftUI
import Combine

@MainActor
final class JuntoStore: ObservableObject {
    @Published var route: AppRoute = .login
    @Published var selectedTab: MainTab = .groups

    // Usuário atual
    @Published var user = UserProfile(
        fullName: "Lucas Ferreira Silva",
        username: "lucas.silva",
        email: "lucas@junto.app",
        country: CountryOption.all[0],
        phone: "(11) 98765-4321",
        pixKey: "lucas@junto.app"
    )

    // Cadastro temporário
    @Published var draftEmail: String = ""
    @Published var draftUsername: String = ""
    @Published var draftPassword: String = ""
    @Published var draftFullName: String = ""
    @Published var draftCountry: CountryOption = CountryOption.all[0]
    @Published var draftPhone: String = ""
    @Published var usernameState: UsernameCheckState = .idle

    // Dados do App
    @Published var friends: [FriendItem] = [
        FriendItem(name: "Pedro Santos", username: "pedro.santos", initials: "PS", balance: 45.00),
        FriendItem(name: "Matheus Alves", username: "matheus.alves", initials: "MA", balance: -38.50),
        FriendItem(name: "Camila Rocha", username: "camila.rocha", initials: "CR", balance: 100.00),
        FriendItem(name: "Rafael Costa", username: "rafa.costa", initials: "RC", balance: 0.0)
    ]

    @Published var groups: [RoleGroup] = [
        RoleGroup(
            title: "Churras na Casa do Pedro",
            category: "Churrasco",
            coverImageName: "GroupChurrasco",
            potBalance: 180.00,
            potTarget: 300.00,
            totalSpent: 420.00,
            myShare: 0.0,
            members: ["EU", "PS", "MA", "CR", "RC"],
            hasCollectivePot: true,
            comandaItems: [
                ComandaItem(name: "Picanha Premium (Rateio)", detail: "Dividido por 5", price: 32.00, isSelected: true),
                ComandaItem(name: "Pack Cerveja Artesanal", detail: "Quem bebe álcool", price: 24.00, isSelected: true),
                ComandaItem(name: "Carvão, Gelo & Pão de Alho", detail: "Rateio geral", price: 11.50, isSelected: true)
            ]
        ),
        RoleGroup(
            title: "Sextou no Bar do Zé",
            category: "Bar & Drinks",
            coverImageName: "GroupBar",
            potBalance: 0.0,
            potTarget: 0.0,
            totalSpent: 285.00,
            myShare: 38.50,
            members: ["EU", "MA", "CR"],
            hasCollectivePot: false,
            comandaItems: [
                ComandaItem(name: "Chopp IPA (2x)", detail: "Consumo individual", price: 24.00, isSelected: true),
                ComandaItem(name: "Porção Batata Trufada (1/3)", detail: "Compartilhado", price: 11.00, isSelected: true),
                ComandaItem(name: "Taxa 10% Garçom", detail: "Proporcional ao consumo", price: 3.50, isSelected: true),
                ComandaItem(name: "Caipirinha Morango", detail: "Outro amigo", price: 22.00, isSelected: false)
            ]
        ),
        RoleGroup(
            title: "Viagem Ubatuba 2026",
            category: "Viagem Praia",
            coverImageName: "GroupPraia",
            potBalance: 640.00,
            potTarget: 1000.00,
            totalSpent: 1840.00,
            myShare: 150.00,
            members: ["EU", "PS", "MA", "CR", "RC", "AN"],
            hasCollectivePot: true,
            comandaItems: [
                ComandaItem(name: "Casa de Praia (Diária)", detail: "1/6 da reserva", price: 110.00, isSelected: true),
                ComandaItem(name: "Gasolina + Pedágio", detail: "Carro do Pedro", price: 40.00, isSelected: true)
            ]
        )
    ]

    @Published var activities: [ActivityEvent] = [
        ActivityEvent(icon: "bolt.fill", title: "Pedro pagou o Pote via Pix", subtitle: "Churras na Casa do Pedro • Baixa automática", timeAgo: "Há 8 min", amountText: "+ R$ 50,00", isPositive: true),
        ActivityEvent(icon: "flame.fill", title: "Matheus lançou Picanha e Carvão", subtitle: "Debitado do Pote Coletivo", timeAgo: "Há 1 hora", amountText: "- R$ 140,00", isPositive: false),
        ActivityEvent(icon: "doc.text.viewfinder", title: "Comanda escaneada com IA", subtitle: "Sextou no Bar do Zé • 4 itens separados", timeAgo: "Ontem", amountText: "R$ 285,00", isPositive: true),
        ActivityEvent(icon: "person.badge.plus", title: "Camila entrou no rolê", subtitle: "Via convite @camila.rocha", timeAgo: "Há 2 dias", amountText: nil, isPositive: true)
    ]

    @Published var notifications: [AppNotification] = [
        AppNotification(icon: "bolt.circle.fill", title: "Pix recebido na hora!", message: "Pedro Santos quitou R$ 45,00 com baixa automática.", timeAgo: "5 min", isUnread: true),
        AppNotification(icon: "sparkles", title: "Convite de Rolê", message: "Você foi adicionado em 'Churras na Casa do Pedro'.", timeAgo: "1h", isUnread: true),
        AppNotification(icon: "arrow.uturn.left.circle.fill", title: "Pote Coletivo atualizado", message: "Saldo atual disponível: R$ 180,00.", timeAgo: "3h", isUnread: false)
    ]

    @Published var blockedUsernames: [String] = ["chato.do.role"]
    @Published var activePixSheet: PixChargeSheetData? = nil
    @Published var activeComandaGroupId: UUID? = nil

    // Toast Feedback
    @Published var toastMessage: String? = nil
    @Published var toastIcon: String = "checkmark.circle.fill"
    private var toastTask: Task<Void, Never>? = nil
    private var usernameCheckTask: Task<Void, Never>? = nil

    private let takenUsernames: Set<String> = ["admin", "pedro", "matheus", "camila", "junto", "teste", "joao"]

    // MARK: - Totais
    var totalToReceive: Double {
        friends.filter { $0.balance > 0 }.reduce(0) { $0 + $1.balance }
    }

    var totalToPay: Double {
        friends.filter { $0.balance < 0 }.reduce(0) { $0 + abs($1.balance) }
    }

    var unreadNotificationsCount: Int {
        notifications.filter { $0.isUnread }.count
    }

    // MARK: - Formatação BRL
    static func formatBRL(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.currencyCode = "BRL"
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "R$ %.2f", value)
    }

    // MARK: - Verificação de @username em tempo real
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
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            if takenUsernames.contains(cleaned) {
                usernameState = .unavailable
            } else {
                usernameState = .available
            }
        }
    }

    // MARK: - Fluxo de Autenticação
    func login(identifier: String) {
        let clean = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.isEmpty {
            if !clean.contains("@") {
                user.username = clean.lowercased()
            } else {
                user.email = clean
            }
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            route = .main
        }
        showToast("Que bom te ter de volta, \(user.firstName)!", icon: "sparkles")
    }

    func advanceToRegisterStep2() {
        let cleanUser = draftUsername.replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !draftEmail.trimmingCharacters(in: .whitespaces).isEmpty else {
            showToast("Informe seu e-mail para continuar.", icon: "exclamationmark.triangle.fill")
            return
        }
        guard cleanUser.count >= 3, usernameState != .unavailable else {
            showToast("Escolha um nome de usuário disponível.", icon: "exclamationmark.triangle.fill")
            return
        }
        guard draftPassword.count >= 6 else {
            showToast("A senha precisa ter pelo menos 6 caracteres.", icon: "lock.fill")
            return
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            route = .registerStep2
        }
    }

    func completeRegistration() {
        let cleanName = draftFullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            showToast("Digite seu nome completo.", icon: "person.fill")
            return
        }
        guard draftPhone.filter({ $0.isNumber }).count >= 10 else {
            showToast("Digite um número de telefone válido.", icon: "phone.fill")
            return
        }

        user = UserProfile(
            fullName: cleanName,
            username: draftUsername.replacingOccurrences(of: "@", with: "").lowercased(),
            email: draftEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            country: draftCountry,
            phone: draftPhone,
            pixKey: draftEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        withAnimation(.easeInOut(duration: 0.3)) {
            route = .welcome
        }
    }

    func finishWelcome() {
        withAnimation(.easeInOut(duration: 0.3)) {
            route = .main
        }
        showToast("Bem-vindo ao Juntô, \(user.firstName)!", icon: "party.popper.fill")
    }

    // MARK: - Convite rápido por @username
    func sendFriendInvite(username raw: String) {
        let clean = raw
            .lowercased()
            .replacingOccurrences(of: "@", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard clean.count >= 3 else {
            showToast("Digite um @usuário válido.", icon: "exclamationmark.circle.fill")
            return
        }

        if blockedUsernames.contains(clean) {
            showToast("@\(clean) está na sua lista de bloqueados.", icon: "hand.raised.fill")
            return
        }

        let displayName = clean
            .split(separator: ".")
            .map { $0.capitalized }
            .joined(separator: " ")

        let initials = String(clean.prefix(2)).uppercased()
        let newFriend = FriendItem(
            name: displayName,
            username: clean,
            initials: initials,
            balance: 0,
            isPendingInvite: true
        )
        friends.insert(newFriend, at: 0)
        activities.insert(
            ActivityEvent(
                icon: "paperplane.fill",
                title: "Convite enviado para @\(clean)",
                subtitle: "Aguardando aceitar para entrar no rolê",
                timeAgo: "Agora",
                amountText: nil,
                isPositive: true
            ),
            at: 0
        )
        showToast("Convite enviado para @\(clean)!", icon: "paperplane.fill")
    }

    // MARK: - Grupos / Rolês / Pix
    func createNewRole(title: String, category: String, hasPot: Bool, initialPotTarget: Double) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }

        let cover: String
        switch category {
        case "Churrasco": cover = "GroupChurrasco"
        case "Bar & Drinks": cover = "GroupBar"
        default: cover = "GroupPraia"
        }

        let newGroup = RoleGroup(
            title: cleanTitle,
            category: category,
            coverImageName: cover,
            potBalance: hasPot ? 0 : 0,
            potTarget: hasPot ? max(initialPotTarget, 100) : 0,
            totalSpent: 0,
            myShare: 0,
            members: ["EU"],
            hasCollectivePot: hasPot,
            comandaItems: [
                ComandaItem(name: "Item inicial do rolê", detail: "Dividido igualmente", price: 25.00, isSelected: true)
            ]
        )

        groups.insert(newGroup, at: 0)
        activities.insert(
            ActivityEvent(
                icon: "sparkles",
                title: "Novo rolê criado: \(cleanTitle)",
                subtitle: hasPot ? "Com Pote Coletivo ativado" : "Modo divisão tradicional",
                timeAgo: "Agora",
                amountText: nil,
                isPositive: true
            ),
            at: 0
        )
        showToast("Rolê '\(cleanTitle)' criado!", icon: "sparkles")
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
            showToast("Não há saldo restante no pote.", icon: "info.circle.fill")
            return
        }
        let perPerson = remainder / Double(max(groups[idx].members.count, 1))
        groups[idx].potBalance = 0
        activities.insert(
            ActivityEvent(
                icon: "arrow.uturn.left.circle.fill",
                title: "Sobra devolvida por Pix!",
                subtitle: "\(groups[idx].title) • \(Self.formatBRL(perPerson)) p/ cada",
                timeAgo: "Agora",
                amountText: "+ \(Self.formatBRL(perPerson))",
                isPositive: true
            ),
            at: 0
        )
        showToast("Sobra de \(Self.formatBRL(perPerson)) devolvida por Pix para cada amigo!", icon: "bolt.fill")
    }

    func markAllNotificationsRead() {
        for i in notifications.indices {
            notifications[i].isUnread = false
        }
    }

    // MARK: - Segurança & Conta
    func blockUser(_ raw: String) {
        let clean = raw.lowercased().replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count >= 2 else { return }
        if !blockedUsernames.contains(clean) {
            blockedUsernames.insert(clean, at: 0)
            showToast("@\(clean) adicionado aos bloqueados.", icon: "hand.raised.fill")
        }
    }

    func unblockUser(_ username: String) {
        blockedUsernames.removeAll { $0 == username }
        showToast("@\(username) desbloqueado.", icon: "checkmark.circle.fill")
    }

    func disconnectAllDevices() {
        showToast("Todas as outras sessões foram encerradas com segurança.", icon: "lock.shield.fill")
    }

    func deleteAccountPermanently() {
        draftEmail = ""
        draftUsername = ""
        draftPassword = ""
        draftFullName = ""
        draftPhone = ""
        withAnimation(.easeInOut(duration: 0.3)) {
            route = .login
        }
        showToast("Sua conta e dados foram excluídos permanentemente.", icon: "trash.fill")
    }

    func logout() {
        withAnimation(.easeInOut(duration: 0.3)) {
            route = .login
        }
        showToast("Você saiu da sua conta.", icon: "rectangle.portrait.and.arrow.right")
    }

    // MARK: - Toast
    func showToast(_ message: String, icon: String = "checkmark.circle.fill") {
        toastTask?.cancel()
        toastIcon = icon
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            toastMessage = message
        }
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 2_800_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                toastMessage = nil
            }
        }
    }
}
