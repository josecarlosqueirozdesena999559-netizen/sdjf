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
    @Published var draftPixKey: String = ""
    @Published var usernameState: UsernameCheckState = .idle

    // Mocks realistas e completos para testar imediatamente
    @Published var friends: [FriendItem] = [
        FriendItem(name: "Pedro Santos", username: "pedro.santos", initials: "PS", balance: 100.00, isOnline: true, lastSeenText: "online", friendsSinceText: "12 de jan. de 2026"),
        FriendItem(name: "Camila Rocha", username: "camila.rocha", initials: "CR", balance: 70.00, isOnline: false, lastSeenText: "visto por último hoje às 19:42", friendsSinceText: "04 de mar. de 2026"),
        FriendItem(name: "Matheus Alves", username: "matheus.alves", initials: "MA", balance: -35.36, isOnline: true, lastSeenText: "online", friendsSinceText: "21 de mai. de 2026"),
        FriendItem(name: "Beatriz Lima", username: "bia.lima", initials: "BL", balance: 0.0, isOnline: false, lastSeenText: "visto por último ontem às 22:15", friendsSinceText: "09 de ago. de 2026")
    ]

    // Despesas pessoais detalhadas por mês (para gráficos redondos e análises)
    @Published var personalExpenses: [PersonalExpenseRecord] = [
        PersonalExpenseRecord(title: "Casa de Praia (Cota)", category: "Viagem", amount: 420.00, dateText: "18 nov", monthKey: "Novembro 2026", groupName: "Viagem Ubatuba"),
        PersonalExpenseRecord(title: "Gasolina + Pedágio", category: "Viagem", amount: 185.00, dateText: "17 nov", monthKey: "Novembro 2026", groupName: "Viagem Ubatuba"),
        PersonalExpenseRecord(title: "Picanha + Bebidas", category: "Churrasco", amount: 240.00, dateText: "15 nov", monthKey: "Novembro 2026", groupName: "Churrasco de Domingo"),
        PersonalExpenseRecord(title: "Carvão e Acompanhamentos", category: "Churrasco", amount: 115.00, dateText: "15 nov", monthKey: "Novembro 2026", groupName: "Churrasco de Domingo"),
        PersonalExpenseRecord(title: "Energia + Condomínio", category: "Casa", amount: 265.00, dateText: "10 nov", monthKey: "Novembro 2026", groupName: "Contas do Apê 402"),
        PersonalExpenseRecord(title: "Internet Fibra 500Mb", category: "Casa", amount: 65.00, dateText: "05 nov", monthKey: "Novembro 2026", groupName: "Contas do Apê 402"),
        PersonalExpenseRecord(title: "Chopp + Petiscos", category: "Bar & Drinks", amount: 145.00, dateText: "02 nov", monthKey: "Novembro 2026", groupName: "Sextou"),
        // Mês anterior (Outubro 2026) para comparativo
        PersonalExpenseRecord(title: "Pousada Serra", category: "Viagem", amount: 520.00, dateText: "24 out", monthKey: "Outubro 2026", groupName: "Feriado Serra"),
        PersonalExpenseRecord(title: "Aluguel + Luz", category: "Casa", amount: 490.00, dateText: "10 out", monthKey: "Outubro 2026", groupName: "Contas do Apê 402"),
        PersonalExpenseRecord(title: "Churrasco Aniversário", category: "Churrasco", amount: 310.00, dateText: "12 out", monthKey: "Outubro 2026", groupName: "Aniversário Pedro"),
        PersonalExpenseRecord(title: "Barzinho de Sexta", category: "Bar & Drinks", amount: 280.00, dateText: "04 out", monthKey: "Outubro 2026", groupName: "Galera")
    ]

    @Published var showMyExpensesScreen: Bool = false

    // Conversas de chat por @username
    @Published var chatMessages: [String: [ChatMessage]] = [
        "pedro.santos": [
            ChatMessage(isFromMe: false, kind: .text("Fala! Já separei os R$ 100 da viagem de Ubatuba."), timeText: "19:12", status: .read),
            ChatMessage(isFromMe: true, kind: .text("Show Pedro, pode mandar por Pix quando puder 👍"), timeText: "19:15", status: .read),
            ChatMessage(
                isFromMe: false,
                kind: .audio(duration: 8, waveform: [0.25, 0.45, 0.72, 0.90, 0.55, 0.35, 0.68, 0.85, 0.95, 0.60, 0.42, 0.78, 0.50, 0.30, 0.64, 0.88, 0.74, 0.48, 0.35, 0.62, 0.80, 0.45, 0.28, 0.20], fileURL: nil),
                timeText: "19:18",
                status: .read
            )
        ],
        "camila.rocha": [
            ChatMessage(isFromMe: false, kind: .text("Oi! Te mando minha parte do churrasco ainda hoje."), timeText: "18:30", status: .read),
            ChatMessage(isFromMe: true, kind: .text("Tranquilo, sem pressa!"), timeText: "18:34", status: .delivered)
        ],
        "matheus.alves": [
            ChatMessage(isFromMe: false, kind: .document("Comanda_Churrasco.pdf", "248 KB"), timeText: "17:45", status: .read),
            ChatMessage(isFromMe: false, kind: .text("Ficou R$ 35,36 a sua parte da carne e do gelo."), timeText: "17:46", status: .read)
        ]
    ]

    @Published var groups: [RoleGroup] = [
        RoleGroup(
            title: "Viagem Ubatuba",
            category: "Viagem",
            coverImageName: "GroupPraia",
            potBalance: 600.00,
            potTarget: 1000.00,
            totalSpent: 1840.00,
            myShare: 0.0,
            members: ["EU", "PS", "MA", "CR", "BL"],
            participants: [
                GroupParticipant(name: "Você", username: "lucas.andrade", quotaAmount: 200.00, hasPaid: true, role: .owner),
                GroupParticipant(name: "Pedro Santos", username: "pedro.santos", quotaAmount: 200.00, hasPaid: true, role: .admin),
                GroupParticipant(name: "Camila Rocha", username: "camila.rocha", quotaAmount: 200.00, hasPaid: true, role: .member),
                GroupParticipant(name: "Matheus Alves", username: "matheus.alves", quotaAmount: 200.00, hasPaid: false, role: .member),
                GroupParticipant(name: "Beatriz Lima", username: "bia.lima", quotaAmount: 200.00, hasPaid: false, role: .member)
            ],
            hasCollectivePot: true,
            comandaItems: [
                ComandaItem(name: "Casa de Praia (Diária)", detail: "1/5 da reserva", price: 110.00, isSelected: true),
                ComandaItem(name: "Gasolina + Pedágio", detail: "Carro do Pedro", price: 40.00, isSelected: true)
            ]
        ),
        RoleGroup(
            title: "Churrasco de Domingo",
            category: "Churrasco",
            coverImageName: "GroupChurrasco",
            potBalance: 150.00,
            potTarget: 300.00,
            totalSpent: 420.00,
            myShare: 35.36,
            members: ["EU", "PS", "MA", "CR"],
            participants: [
                GroupParticipant(name: "Você", username: "lucas.andrade", quotaAmount: 75.00, hasPaid: false, role: .owner),
                GroupParticipant(name: "Pedro Santos", username: "pedro.santos", quotaAmount: 75.00, hasPaid: true, role: .member),
                GroupParticipant(name: "Camila Rocha", username: "camila.rocha", quotaAmount: 75.00, hasPaid: true, role: .member),
                GroupParticipant(name: "Matheus Alves", username: "matheus.alves", quotaAmount: 75.00, hasPaid: false, role: .member)
            ],
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
            participants: [
                GroupParticipant(name: "Você", username: "lucas.andrade", quotaAmount: 0, hasPaid: false, role: .owner),
                GroupParticipant(name: "Matheus Alves", username: "matheus.alves", quotaAmount: 0, hasPaid: false, role: .member),
                GroupParticipant(name: "Beatriz Lima", username: "bia.lima", quotaAmount: 0, hasPaid: false, role: .member)
            ],
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
        let cleanPix = draftPixKey.trimmingCharacters(in: .whitespacesAndNewlines)
        user = UserProfile(
            fullName: cleanName.isEmpty ? "Novo usuário" : cleanName,
            username: draftUsername.replacingOccurrences(of: "@", with: "").lowercased(),
            email: draftEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            country: draftCountry,
            phone: draftPhone,
            pixKey: cleanPix.isEmpty ? draftEmail.trimmingCharacters(in: .whitespacesAndNewlines) : cleanPix
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

    // MARK: - Chat com Amigos (Texto, Foto, Áudio, Documento & Apagar Conversa)
    func messages(for username: String) -> [ChatMessage] {
        chatMessages[username.lowercased()] ?? []
    }

    func lastMessagePreview(for username: String) -> String {
        guard let last = messages(for: username).last else {
            return "Sem mensagens"
        }
        switch last.kind {
        case .text(let txt): return txt
        case .photo(_, let caption): return caption.isEmpty ? "Foto" : "Foto: \(caption)"
        case .audio(let secs, _, _): return "Áudio (0:\(String(format: "%02d", secs)))"
        case .document(let name, _): return "Documento: \(name)"
        }
    }

    private func currentTimeString() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: Date())
    }

    func sendChatMessage(to username: String, kind: ChatMessageKind) {
        let key = username.lowercased()
        let msg = ChatMessage(isFromMe: true, kind: kind, timeText: currentTimeString(), status: .sent)
        let msgId = msg.id
        chatMessages[key, default: []].append(msg)

        // Simulação em tempo real do ciclo de entrega/leitura (no servidor via Socket.IO chat:status)
        let isFriendOnline = friends.first(where: { $0.username.lowercased() == key })?.isOnline ?? false
        if isFriendOnline {
            Task {
                // 1 traço (sent) -> 2 traços (delivered) em 0.6s
                try? await Task.sleep(nanoseconds: 600_000_000)
                updateMessageStatus(username: key, messageId: msgId, status: .delivered)

                // 2 traços (delivered) -> 2 traços coloridos (read) em +1.2s
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                updateMessageStatus(username: key, messageId: msgId, status: .read)

                // Indicador "digitando..." em tempo real por 2s
                setFriendTyping(username: key, typing: true)
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                setFriendTyping(username: key, typing: false)
            }
        }
    }

    func updateMessageStatus(username: String, messageId: UUID, status: MessageDeliveryStatus) {
        let key = username.lowercased()
        guard let idx = chatMessages[key]?.firstIndex(where: { $0.id == messageId }) else { return }
        chatMessages[key]?[idx].status = status
    }

    func setFriendTyping(username: String, typing: Bool) {
        let key = username.lowercased()
        guard let idx = friends.firstIndex(where: { $0.username.lowercased() == key }) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            friends[idx].isTyping = typing
        }
    }

    /// Apaga as mensagens da conversa. Se houver dívida (balance != 0), o amigo continua na lista inicial sem mensagens.
    func clearConversation(for username: String) {
        let key = username.lowercased()
        chatMessages[key] = []
        showToast("Conversa apagada.", icon: "trash")
    }

    /// Desfaz amizade com o usuário
    func unfriend(username raw: String) {
        let clean = raw.lowercased().replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        friends.removeAll { $0.username.lowercased() == clean }
        sentInviteUsernames.remove(clean)
        showToast("Amizade com @\(clean) desfeita.", icon: "person.badge.minus")
    }

    /// Bloqueia o usuário e automaticamente desfaz a amizade
    func blockAndUnfriend(username raw: String) {
        let clean = raw.lowercased().replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        friends.removeAll { $0.username.lowercased() == clean }
        sentInviteUsernames.remove(clean)
        chatMessages[clean] = nil
        if !blockedUsernames.contains(clean) {
            blockedUsernames.insert(clean, at: 0)
        }
        showToast("@\(clean) bloqueado e amizade desfeita.", icon: "hand.raised")
    }

    /// Silencia ou ativa notificações de um amigo
    func toggleMuteFriend(username raw: String) {
        let clean = raw.lowercased()
        guard let idx = friends.firstIndex(where: { $0.username.lowercased() == clean }) else { return }
        friends[idx].isMuted.toggle()
        showToast(
            friends[idx].isMuted ? "Notificações silenciadas." : "Notificações ativadas.",
            icon: friends[idx].isMuted ? "bell.slash" : "bell"
        )
    }

    /// Verifica se o usuário atual é o Dono (responsável) do grupo
    func isCurrentUserOwner(in group: RoleGroup) -> Bool {
        group.participants.first(where: { $0.name == "Você" || $0.username == user.username })?.role == .owner
    }

    /// Saque do Pote Coletivo via EFI direto para a conta/Pix do responsável do grupo
    func withdrawPotViaEfi(groupId: UUID, amount: Double) {
        guard amount > 0, let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }
        guard isCurrentUserOwner(in: groups[idx]) else {
            showToast("Apenas o responsável pelo grupo pode sacar o pote.", icon: "lock")
            return
        }
        let withdrawable = min(amount, groups[idx].potBalance)
        guard withdrawable > 0 else { return }

        groups[idx].potBalance -= withdrawable
        let groupTitle = groups[idx].title

        activities.insert(
            ActivityEvent(
                icon: "arrow.up.right.circle",
                title: "Saque do Pote via Pix (EFI)",
                subtitle: "\(groupTitle) → \(user.pixKey)",
                timeAgo: "Agora",
                amountText: "+ \(Self.formatBRL(withdrawable))",
                isPositive: true
            ),
            at: 0
        )
        showToast("Saque de \(Self.formatBRL(withdrawable)) enviado via Pix EFI para sua conta!", icon: "checkmark.circle")
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

    /// Apenas Dono ou Admin podem lançar novas despesas no grupo
    func canCurrentUserAddExpenses(in group: RoleGroup) -> Bool {
        if let me = group.participants.first(where: { $0.name == "Você" || $0.username == user.username }) {
            return me.role == .owner || me.role == .admin
        }
        return false
    }

    /// Promove ou remove permissão de Admin de um participante
    func toggleParticipantAdmin(groupId: UUID, participantId: UUID) {
        guard let gIdx = groups.firstIndex(where: { $0.id == groupId }),
              let pIdx = groups[gIdx].participants.firstIndex(where: { $0.id == participantId }) else { return }

        guard groups[gIdx].participants[pIdx].role != .owner else { return }

        let name = groups[gIdx].participants[pIdx].name
        if groups[gIdx].participants[pIdx].role == .admin {
            groups[gIdx].participants[pIdx].role = .member
            showToast("\(name) não é mais admin.", icon: "person")
        } else {
            groups[gIdx].participants[pIdx].role = .admin
            showToast("\(name) agora é admin do grupo.", icon: "checkmark.shield")
        }
    }

    /// Remove um participante do grupo e recalcula automaticamente as cotas do Pote
    func removeParticipantFromGroup(groupId: UUID, participantId: UUID) {
        guard let gIdx = groups.firstIndex(where: { $0.id == groupId }),
              let pIdx = groups[gIdx].participants.firstIndex(where: { $0.id == participantId }) else { return }

        guard groups[gIdx].participants[pIdx].role != .owner else {
            showToast("O dono não pode ser removido do grupo.", icon: "exclamationmark.circle")
            return
        }

        let removed = groups[gIdx].participants.remove(at: pIdx)
        if groups[gIdx].hasCollectivePot && groups[gIdx].potTarget > 0 && !groups[gIdx].participants.isEmpty {
            let newQuota = groups[gIdx].potTarget / Double(groups[gIdx].participants.count)
            for i in groups[gIdx].participants.indices {
                groups[gIdx].participants[i].quotaAmount = newQuota
            }
        }
        showToast("\(removed.name) foi removido do grupo.", icon: "person.badge.minus")
    }

    /// Adiciona despesa real dentro de um grupo (restrito ao Dono ou Admins)
    func addExpenseToGroup(groupId: UUID, name: String, totalAmount: Double, payFromPot: Bool) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, totalAmount > 0,
              let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }

        guard canCurrentUserAddExpenses(in: groups[idx]) else {
            showToast("Apenas o dono ou admins podem adicionar despesas.", icon: "lock")
            return
        }

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

    /// Adiciona membro real ao grupo e recalcula as cotas do Pote automaticamente
    func addMemberToGroup(groupId: UUID, memberUsername: String) {
        let clean = memberUsername.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "").lowercased()
        guard clean.count >= 2, let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }

        if groups[idx].participants.contains(where: { $0.username.lowercased() == clean }) {
            showToast("@\(clean) já está no grupo.", icon: "info.circle")
            return
        }

        let displayName = directoryUsers.first(where: { $0.username.lowercased() == clean })?.name
            ?? clean.split(separator: ".").map { $0.capitalized }.joined(separator: " ")

        let initials = String(clean.prefix(2)).uppercased()
        groups[idx].members.append(initials)
        groups[idx].participants.append(
            GroupParticipant(name: displayName, username: clean, quotaAmount: 0, hasPaid: false)
        )

        // Recalcula automaticamente o valor por pessoa do Pote
        if groups[idx].hasCollectivePot && groups[idx].potTarget > 0 {
            let newQuota = groups[idx].potTarget / Double(groups[idx].participants.count)
            for i in groups[idx].participants.indices {
                groups[idx].participants[i].quotaAmount = newQuota
            }
        }

        activities.insert(
            ActivityEvent(
                icon: "person.badge.plus",
                title: "\(displayName) entrou no grupo",
                subtitle: "\(groups[idx].title) • Cotas atualizadas",
                timeAgo: "Agora",
                amountText: nil,
                isPositive: true
            ),
            at: 0
        )
        showToast("@\(clean) adicionado e cotas recalculadas!", icon: "person.badge.plus")
    }

    func createNewGroup(
        title: String,
        category: String,
        hasPot: Bool = true,
        potTarget: Double = 0,
        invitedPeople: [SearchableUser] = [],
        coverImageData: Data? = nil,
        startDate: Date = Date(),
        targetDate: Date = Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date()
    ) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            showToast("Informe o nome do grupo.", icon: "exclamationmark.circle")
            return
        }

        let cover: String
        switch category {
        case "Viagem": cover = "GroupPraia"
        case "Bar & Drinks", "Casal", "Festa": cover = "GroupBar"
        default: cover = "GroupChurrasco"
        }

        let totalPeopleCount = 1 + invitedPeople.count
        let quotaPerPerson = potTarget > 0 ? (potTarget / Double(totalPeopleCount)) : 0

        var participantsList: [GroupParticipant] = [
            GroupParticipant(name: "Você", username: user.username, quotaAmount: quotaPerPerson, hasPaid: false, role: .owner)
        ]
        var memberInitials: [String] = ["EU"]

        for person in invitedPeople {
            participantsList.append(
                GroupParticipant(name: person.name, username: person.username, quotaAmount: quotaPerPerson, hasPaid: false, role: .member)
            )
            let initStr = person.name.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
            memberInitials.append(initStr.isEmpty ? String(person.username.prefix(2)).uppercased() : initStr)
        }

        let newGroup = RoleGroup(
            title: cleanTitle,
            category: category,
            coverImageName: cover,
            coverImageData: coverImageData,
            startDate: startDate,
            targetDate: targetDate,
            potBalance: 0,
            potTarget: potTarget,
            totalSpent: 0,
            myShare: 0,
            members: memberInitials,
            participants: participantsList,
            hasCollectivePot: true,
            comandaItems: []
        )

        groups.insert(newGroup, at: 0)

        let subtitleText = (hasPot && quotaPerPerson > 0)
            ? "\(category) • \(Self.formatBRL(quotaPerPerson)) p/ cada (\(totalPeopleCount) pessoas)"
            : "\(category) • \(totalPeopleCount) participante(s)"

        activities.insert(
            ActivityEvent(
                icon: hasPot ? "dollarsign.circle" : "person.2",
                title: "Grupo \"\(cleanTitle)\" criado",
                subtitle: subtitleText,
                timeAgo: "Agora",
                amountText: (hasPot && potTarget > 0) ? Self.formatBRL(potTarget) : nil,
                isPositive: true
            ),
            at: 0
        )
        showToast("Grupo \"\(cleanTitle)\" criado e cotas distribuídas!", icon: "checkmark.circle")
    }

    /// Paga a cota de um participante no Pote Coletivo (atualiza saldo e status automaticamente)
    func payParticipantPotQuota(groupId: UUID, participantId: UUID, openPix: Bool = true) {
        guard let gIdx = groups.firstIndex(where: { $0.id == groupId }),
              let pIdx = groups[gIdx].participants.firstIndex(where: { $0.id == participantId }) else { return }

        guard !groups[gIdx].participants[pIdx].hasPaid else { return }
        let quota = groups[gIdx].participants[pIdx].quotaAmount
        let personName = groups[gIdx].participants[pIdx].name
        let groupTitle = groups[gIdx].title

        groups[gIdx].participants[pIdx].hasPaid = true
        groups[gIdx].potBalance += quota

        activities.insert(
            ActivityEvent(
                icon: "checkmark.circle",
                title: "\(personName) pagou a cota do Pote",
                subtitle: "\(groupTitle) • Saldo \(Self.formatBRL(groups[gIdx].potBalance))",
                timeAgo: "Agora",
                amountText: "+ \(Self.formatBRL(quota))",
                isPositive: true
            ),
            at: 0
        )

        if openPix && quota > 0 {
            openPixPayment(title: "Cota do Pote • \(groupTitle)", recipient: "Pote \(groupTitle)", amount: quota)
        } else {
            showToast("Cota de \(personName) marcada como paga!", icon: "checkmark.circle")
        }
    }

    func addQuickExpense(description: String, amount: Double, groupTitle: String, category: String = "Outros") {
        let cleanDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanDesc.isEmpty, amount > 0 else {
            showToast("Informe descrição e valor.", icon: "exclamationmark.circle")
            return
        }

        personalExpenses.insert(
            PersonalExpenseRecord(
                title: cleanDesc,
                category: category,
                amount: amount,
                dateText: "Hoje",
                monthKey: "Novembro 2026",
                groupName: groupTitle.isEmpty ? "Pessoal" : groupTitle
            ),
            at: 0
        )

        activities.insert(
            ActivityEvent(
                icon: "list.bullet.rectangle.portrait",
                title: "Você adicionou \"\(cleanDesc)\"",
                subtitle: groupTitle.isEmpty ? category : groupTitle,
                timeAgo: "Agora",
                amountText: Self.formatBRL(amount),
                isPositive: false
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
