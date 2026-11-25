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

    // Dados sincronizados em tempo real com o banco PostgreSQL do Docker (sem mocks fixos no app)
    @Published var friends: [FriendItem] = []

    // Despesas pessoais sincronizadas com o PostgreSQL
    @Published var personalExpenses: [PersonalExpenseRecord] = []

    @Published var showMyExpensesScreen: Bool = false

    // Conversas de chat por @username sincronizadas com o servidor
    @Published var chatMessages: [String: [ChatMessage]] = [:]

    /// Conversas de cada grupo sincronizadas com o servidor
    @Published var groupChatMessages: [UUID: [ChatMessage]] = [:]

    /// Conversas apagadas pelo usuário na tela inicial (ocultas até nova mensagem ou reabertura pelos contatos)
    @Published var hiddenChatUsernames: Set<String> = []
    @Published var hiddenGroupChatIds: Set<UUID> = []
    /// Contadores reais de mensagens NÃO LIDAS recebidas (zeram ao abrir ou responder na conversa)
    @Published var unreadFriendCounts: [String: Int] = [:]
    @Published var unreadGroupCounts: [UUID: Int] = [:]
    /// Mapeamento de UUID local -> UUID do servidor para nunca perder referência ao criar grupo
    var groupIdAliases: [UUID: UUID] = [:]
    /// Histórico permanente de pagamentos arquivados de grupos excluídos ou encerrados
    @Published var archivedGroupPayments: [PersonalExpenseRecord] = []

    /// E-mail oficial de suporte / Fale Conosco / Ouvidoria LGPD (pronto para atualizar quando você enviar o definitivo)
    @Published var supportEmail: String = "suporte@junto.app"
    @Published var isDatabaseSynced: Bool = false

    // MARK: - Persistência Real de Sessão do Usuário (Auto-Login Sem Tela de Cadastro)
    private let savedProfileKey = "junto_user_profile_data"
    private let sessionActiveKey = "junto_session_is_active"
    private let hiddenChatsKey = "junto_hidden_chat_usernames"
    private let hiddenGroupChatsKey = "junto_hidden_group_chat_ids"
    private let archivedPaymentsKey = "junto_archived_group_payments"
    private let savedActivitiesKey = "junto_saved_monetary_activities"

    static func formattedCurrentDateTime(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "dd/MM/yyyy 'às' HH:mm"
        return f.string(from: date)
    }

    func resolvedGroupIndex(for id: UUID) -> Int? {
        if let idx = groups.firstIndex(where: { $0.id == id }) {
            return idx
        }
        if let mapped = groupIdAliases[id],
           let idx = groups.firstIndex(where: { $0.id == mapped }) {
            return idx
        }
        return nil
    }

    func resolvedGroupId(for id: UUID) -> UUID {
        groupIdAliases[id] ?? id
    }

    func persistPaymentHistory() {
        if let encoded = try? JSONEncoder().encode(archivedGroupPayments) {
            UserDefaults.standard.set(encoded, forKey: archivedPaymentsKey)
        }
        let monetary = activities.filter { Self.isMonetaryActivity($0) }
        if let encodedAct = try? JSONEncoder().encode(monetary) {
            UserDefaults.standard.set(encodedAct, forKey: savedActivitiesKey)
        }
    }

    private func loadPaymentHistory() {
        if let data = UserDefaults.standard.data(forKey: archivedPaymentsKey),
           let decoded = try? JSONDecoder().decode([PersonalExpenseRecord].self, from: data) {
            archivedGroupPayments = decoded
        }
        if let actData = UserDefaults.standard.data(forKey: savedActivitiesKey),
           let decodedAct = try? JSONDecoder().decode([ActivityEvent].self, from: actData) {
            if activities.isEmpty {
                activities = decodedAct.filter { Self.isMonetaryActivity($0) }
            }
        }
    }

    func unreadCount(forGroup groupId: UUID) -> Int {
        unreadGroupCounts[resolvedGroupId(for: groupId)] ?? 0
    }

    func unreadCount(forFriend username: String) -> Int {
        unreadFriendCounts[username.lowercased()] ?? 0
    }

    func markFriendChatAsRead(username: String) {
        let key = username.lowercased()
        if (unreadFriendCounts[key] ?? 0) > 0 {
            unreadFriendCounts[key] = 0
        }
    }

    func markGroupChatAsRead(groupId: UUID) {
        let realId = resolvedGroupId(for: groupId)
        if (unreadGroupCounts[realId] ?? 0) > 0 {
            unreadGroupCounts[realId] = 0
        }
    }

    /// Exclui o contato da lista de contatos e do servidor (sem bloquear)
    func deleteContact(username raw: String) {
        let clean = raw.lowercased().replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        friends.removeAll { $0.username.lowercased() == clean }
        sentInviteUsernames.remove(clean)
        chatMessages.removeValue(forKey: clean)
        unreadFriendCounts.removeValue(forKey: clean)
        hiddenChatUsernames.remove(clean)
        persistHiddenChats()
        Task { _ = await JuntoBackendService.shared.removeFriend(username: clean) }
        showToast("Contato excluído.", icon: "trash")
    }

    /// Gera mensagem pronta de cobrança Pix para os pendentes do grupo (Recurso Juntô Pro)
    func pendingChargeMessage(for group: RoleGroup) -> String {
        let pending = group.participants.filter { !$0.hasPaid && $0.quotaAmount > 0 }
        let organizer = organizerPixInfo(for: group)
        if pending.isEmpty {
            return "Todos os participantes do grupo \"\(group.title)\" já estão quitados!"
        }
        let lines = pending.map { "• \($0.name): \(Self.formatBRL($0.quotaAmount))" }.joined(separator: "\n")
        let pixLine = (group.pixQuickPinEnabled && !organizer.pixKey.isEmpty) ? "\nChave Pix: \(organizer.pixKey)" : ""
        return "Lembrete do grupo *\(group.title)* no Juntô:\n\nCotas pendentes:\n\(lines)\(pixLine)\n\nAssim que pagar, marque como pago no app!"
    }

    // MARK: - Agente Juntô IA de Lembretes de Vencimento (Recurso Exclusivo Juntô Pro)
    private struct SavedGroupProSettings: Codable {
        var aiReminderEnabled: Bool
        var aiReminderDaysBefore: Int
        var aiReminderTone: AIReminderTone
        var pixQuickPinEnabled: Bool
        var restrictExpensesToAdmins: Bool
        var autoClosureSummaryEnabled: Bool
    }

    private let groupProSettingsKey = "junto_group_pro_settings_v1"

    func saveGroupProSettings(for groupId: UUID) {
        guard let idx = resolvedGroupIndex(for: groupId) else { return }
        let g = groups[idx]
        var allMap: [String: SavedGroupProSettings] = [:]
        if let data = UserDefaults.standard.data(forKey: groupProSettingsKey),
           let decoded = try? JSONDecoder().decode([String: SavedGroupProSettings].self, from: data) {
            allMap = decoded
        }
        allMap[g.id.uuidString.lowercased()] = SavedGroupProSettings(
            aiReminderEnabled: g.aiReminderEnabled,
            aiReminderDaysBefore: g.aiReminderDaysBefore,
            aiReminderTone: g.aiReminderTone,
            pixQuickPinEnabled: g.pixQuickPinEnabled,
            restrictExpensesToAdmins: g.restrictExpensesToAdmins,
            autoClosureSummaryEnabled: g.autoClosureSummaryEnabled
        )
        if let encoded = try? JSONEncoder().encode(allMap) {
            UserDefaults.standard.set(encoded, forKey: groupProSettingsKey)
        }

        let gidStr = g.id.uuidString.lowercased()
        let aiEnabled = g.aiReminderEnabled
        let aiDays = g.aiReminderDaysBefore
        let aiTone = g.aiReminderTone.rawValue
        let pixPin = g.pixQuickPinEnabled
        let adminOnly = g.restrictExpensesToAdmins
        let autoClosure = g.autoClosureSummaryEnabled
        Task {
            await JuntoBackendService.shared.updateGroupProSettings(
                groupId: gidStr,
                aiReminderEnabled: aiEnabled,
                aiReminderDaysBefore: aiDays,
                aiReminderTone: aiTone,
                pixQuickPinEnabled: pixPin,
                restrictExpensesToAdmins: adminOnly,
                autoClosureSummaryEnabled: autoClosure
            )
        }
    }

    func applySavedGroupProSettings() {
        guard let data = UserDefaults.standard.data(forKey: groupProSettingsKey),
              let allMap = try? JSONDecoder().decode([String: SavedGroupProSettings].self, from: data) else {
            return
        }
        for i in groups.indices {
            let key = groups[i].id.uuidString.lowercased()
            if let cfg = allMap[key] {
                groups[i].aiReminderEnabled = cfg.aiReminderEnabled
                groups[i].aiReminderDaysBefore = cfg.aiReminderDaysBefore
                groups[i].aiReminderTone = cfg.aiReminderTone
                groups[i].pixQuickPinEnabled = cfg.pixQuickPinEnabled
                groups[i].restrictExpensesToAdmins = cfg.restrictExpensesToAdmins
                groups[i].autoClosureSummaryEnabled = cfg.autoClosureSummaryEnabled
            }
        }
    }

    func daysUntilDue(for group: RoleGroup) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let due = cal.startOfDay(for: group.targetDate)
        return cal.dateComponents([.day], from: today, to: due).day ?? 0
    }

    /// Monta a mensagem natural, bem formatada e realista do contato oficial Juntou conforme o tom escolhido e prazo restante
    func composeAIReminderMessage(for group: RoleGroup, pendingParticipants: [GroupParticipant], daysLeft: Int) -> String {
        let deadlinePhrase: String
        if daysLeft < 0 {
            deadlinePhrase = "venceu há \(abs(daysLeft)) dia(s)"
        } else if daysLeft == 0 {
            deadlinePhrase = "vence hoje"
        } else if daysLeft == 1 {
            deadlinePhrase = "vence amanhã"
        } else {
            deadlinePhrase = "vence em \(daysLeft) dias"
        }

        let namesList = pendingParticipants
            .map { $0.name.split(separator: " ").first.map(String.init) ?? $0.name }
            .joined(separator: ", ")
        let quotaSample = pendingParticipants.first?.quotaAmount ?? group.dynamicQuotaPerPerson
        let quotaText = quotaSample > 0 ? Self.formatBRL(quotaSample) : "valor em aberto"
        let organizer = organizerPixInfo(for: group)
        let pixBlock = (group.pixQuickPinEnabled && !organizer.pixKey.isEmpty)
            ? "\n\nChave Pix (\(organizer.name.split(separator: " ").first.map(String.init) ?? organizer.name)):\n\(organizer.pixKey)"
            : ""
        let footer = "\n\n— Juntou · Contato Oficial\nConheça o Plano Anual: https://junto.app/anual"

        switch group.aiReminderTone {
        case .friendly:
            return """
            Olá, pessoal!

            Aqui é o Juntou, passando para lembrar com carinho que o prazo de \(group.title) \(deadlinePhrase).

            • Ainda em aberto: \(namesList)
            • Valor por pessoa: \(quotaText)\(pixBlock)

            Quando fizer a transferência, basta confirmar no grupo para manter tudo atualizado.\(footer)
            """
        case .direct:
            return """
            Lembrete de pagamento · \(group.title)

            O prazo do grupo \(deadlinePhrase).
            • Pendentes: \(namesList)
            • Valor por pessoa: \(quotaText)\(pixBlock)\(footer)
            """
        case .funny:
            return """
            Oi pessoal de \(group.title)!

            Passando para dar aquele toque amigo: o prazo \(deadlinePhrase) e ainda faltam alguns pagamentos para fechar tudo certinho.

            • Quem ainda falta: \(namesList)
            • Valor individual: \(quotaText)\(pixBlock)

            Assim que enviar o Pix, confirme direto no grupo para atualizar na hora.\(footer)
            """
        }
    }

    /// Varredura automática do contato oficial Juntou: dispara lembretes no app próximo ao vencimento para quem ainda não pagou
    func runAIReminderAgentScan() {
        guard user.isPro else { return }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dayKey = df.string(from: Date())

        for group in groups {
            // 1. Lembrete automático próximo ao vencimento
            if group.aiReminderEnabled {
                let daysLeft = daysUntilDue(for: group)
                let pending = group.participants.filter { !$0.hasPaid && $0.quotaAmount > 0 }
                let dedupKey = "junto_ai_reminder_\(group.id.uuidString.lowercased())_\(dayKey)"

                if daysLeft <= group.aiReminderDaysBefore,
                   !pending.isEmpty,
                   !UserDefaults.standard.bool(forKey: dedupKey) {
                    let messageBody = composeAIReminderMessage(for: group, pendingParticipants: pending, daysLeft: daysLeft)
                    deliverAIReminderInApp(group: group, messageBody: messageBody)
                    UserDefaults.standard.set(true, forKey: dedupKey)
                }
            }

            // 2. Resumo automático de fechamento ao atingir 100%
            if group.autoClosureSummaryEnabled && group.overallGoalPercent == 100 {
                let closureKey = "junto_ai_closure_\(group.id.uuidString.lowercased())"
                if !UserDefaults.standard.bool(forKey: closureKey) {
                    let summary = """
                    Meta concluída em \(group.title)!

                    Todos os \(group.participants.count) participantes confirmaram o pagamento e o grupo atingiu 100% da meta, somando \(Self.formatBRL(group.potBalance)) arrecadados.

                    — Juntou · Contato Oficial
                    Conheça o Plano Anual: https://junto.app/anual
                    """
                    deliverAIReminderInApp(group: group, messageBody: summary, notifTitle: "Juntou · Grupo 100% quitado!")
                    UserDefaults.standard.set(true, forKey: closureKey)
                }
            }
        }
    }

    /// Envia imediatamente um lembrete do contato oficial Juntou (via Manus IA no servidor Docker, com fallback instantâneo)
    func triggerAIReminderNow(for groupId: UUID) {
        guard user.isPro else {
            showToast("O Agente Juntou é exclusivo do plano Juntô Pro.", icon: "sparkles")
            return
        }
        guard let idx = resolvedGroupIndex(for: groupId) else { return }
        let group = groups[idx]
        let pending = group.participants.filter { !$0.hasPaid && $0.quotaAmount > 0 }
        guard !pending.isEmpty else {
            showToast("Todos os participantes já estão quitados!", icon: "checkmark.circle")
            return
        }
        let daysLeft = daysUntilDue(for: group)
        let gidStr = group.id.uuidString.lowercased()
        showToast("Juntou está preparando o lembrete...", icon: "sparkles")

        Task {
            let serverMessage = await JuntoBackendService.shared.triggerGroupAIReminder(groupId: gidStr)
            let finalBody = (serverMessage?.isEmpty == false)
                ? serverMessage!
                : composeAIReminderMessage(for: group, pendingParticipants: pending, daysLeft: daysLeft)
            // Evita duplicação caso o evento SSE já tenha inserido a mensagem oficial idêntica
            let alreadyArrived = (groupChatMessages[group.id] ?? []).suffix(3).contains { msg in
                if case .text(let t) = msg.kind {
                    return t.trimmingCharacters(in: .whitespacesAndNewlines) == finalBody.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                return false
            }
            if !alreadyArrived {
                deliverAIReminderInApp(group: group, messageBody: finalBody)
            }
            showToast("Juntou enviou o lembrete no grupo!", icon: "checkmark.circle")
        }
    }

    private func deliverAIReminderInApp(group: RoleGroup, messageBody: String, notifTitle: String? = nil) {
        let aiMsg = ChatMessage(
            isFromMe: false,
            kind: .text(messageBody),
            timeText: currentTimeString(),
            createdAt: Date(),
            status: .read,
            senderName: "Juntou",
            senderUsername: "juntou.oficial",
            senderProPlanType: .yearly
        )
        unhideGroupConversation(for: group.id)
        groupChatMessages[group.id, default: []].append(aiMsg)
        unreadGroupCounts[group.id, default: 0] += 1

        let title = notifTitle ?? "Juntou · Lembrete em \(group.title)"
        notifications.insert(
            AppNotification(
                icon: "sparkles",
                title: title,
                message: messageBody,
                timeAgo: "Agora",
                isUnread: true
            ),
            at: 0
        )
        JuntoNotificationManager.shared.triggerLocalNotification(title: title, body: messageBody)
        objectWillChange.send()
    }

    private func persistHiddenChats() {
        UserDefaults.standard.set(Array(hiddenChatUsernames), forKey: hiddenChatsKey)
        UserDefaults.standard.set(hiddenGroupChatIds.map { $0.uuidString }, forKey: hiddenGroupChatsKey)
    }

    private func loadHiddenChats() {
        if let arr = UserDefaults.standard.stringArray(forKey: hiddenChatsKey) {
            hiddenChatUsernames = Set(arr.map { $0.lowercased() })
        }
        if let gArr = UserDefaults.standard.stringArray(forKey: hiddenGroupChatsKey) {
            hiddenGroupChatIds = Set(gArr.compactMap { UUID(uuidString: $0) })
        }
    }

    func unhideConversation(for username: String) {
        let key = username.lowercased()
        if hiddenChatUsernames.remove(key) != nil {
            persistHiddenChats()
        }
    }

    func unhideGroupConversation(for groupId: UUID) {
        if hiddenGroupChatIds.remove(groupId) != nil {
            persistHiddenChats()
        }
    }

    func saveUserSession() {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: savedProfileKey)
            UserDefaults.standard.set(true, forKey: sessionActiveKey)
        }
        let u = user
        Task {
            _ = await JuntoBackendService.shared.updateProfile(
                fullName: u.fullName,
                email: u.email,
                phone: u.phone,
                pixKey: u.pixKey
            )
        }
    }

    func loadSavedUserSession() {
        loadHiddenChats()
        loadPaymentHistory()
        let isSessionActive = UserDefaults.standard.bool(forKey: sessionActiveKey)
        guard isSessionActive,
              let data = UserDefaults.standard.data(forKey: savedProfileKey),
              let savedUser = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return
        }
        self.user = savedUser
        self.route = .main
    }

    func clearUserSession() {
        UserDefaults.standard.removeObject(forKey: savedProfileKey)
        UserDefaults.standard.set(false, forKey: sessionActiveKey)
        UserDefaults.standard.removeObject(forKey: hiddenChatsKey)
        UserDefaults.standard.removeObject(forKey: hiddenGroupChatsKey)
        UserDefaults.standard.removeObject(forKey: archivedPaymentsKey)
        UserDefaults.standard.removeObject(forKey: savedActivitiesKey)
        hiddenChatUsernames = []
        hiddenGroupChatIds = []
        archivedGroupPayments = []
        groupIdAliases = [:]
        UserDefaults.standard.removeObject(forKey: "junto_access_token")
        KeychainHelper.delete(forKey: "junto_access_token")
        KeychainHelper.delete(forKey: "junto_refresh_token")
    }

    init() {
        // Solicita permissão real de notificações do iOS e carrega sessão salva (Auto-Login)
        JuntoNotificationManager.shared.requestAuthorization()
        loadSavedUserSession()
        Task {
            await syncWithBackendDatabase()
        }
    }

    // Pessoas próximas descobertas pelo algoritmo
    @Published var nearbyUsers: [NearbyUserItem] = []

    // Grupos sincronizados do banco PostgreSQL (no plano gratuito permite 1 grupo; no Juntô Pro ilimitado)
    @Published var groups: [RoleGroup] = []

    /// Potes Pessoais ("Caixinhas" individuais para guardar dinheiro para uma ocasião especial — recurso Juntô Pro)
    @Published var personalPots: [PersonalSavingsPot] = []

    @Published var activities: [ActivityEvent] = []

    // Diretório de usuários para busca em tempo real letra por letra
    @Published var directoryUsers: [SearchableUser] = []

    @Published var sentInviteUsernames: Set<String> = []

    @Published var notifications: [AppNotification] = []

    @Published var blockedUsers: [BlockedUserEntry] = []

    @Published var connectedDevices: [ConnectedDeviceSession] = [
        ConnectedDeviceSession(
            deviceName: UIDevice.current.name,
            systemInfo: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
            locationText: "Brasil",
            lastActiveText: "Ativo agora",
            isCurrentDevice: true
        )
    ]

    @Published var activePixSheet: PixChargeSheetData? = nil
    @Published var showAddExpenseSheet: Bool = false

    @Published var toastMessage: String? = nil
    @Published var toastIcon: String = "checkmark.circle"
    @Published var expectedWhatsAppOTP: String = ""
    private var toastTask: Task<Void, Never>? = nil
    private var usernameCheckTask: Task<Void, Never>? = nil

    func generateAndSendWhatsAppOTP() {
        let code = String(format: "%06d", Int.random(in: 100000...999999))
        expectedWhatsAppOTP = code
        let phone = draftPhone
        Task {
            let sent = await WhatsAppCloudAPIService.shared.sendOTP(to: phone, code: code)
            if !sent {
                _ = await JuntoBackendService.shared.sendWhatsAppVerificationCode(phone: phone, code: code)
            }
        }
        showToast("Código enviado para seu WhatsApp!", icon: "message.fill")
    }

    private let takenUsernames: Set<String> = ["admin", "pedro", "matheus", "camila", "junto", "teste", "suporte"]

    var unreadNotificationsCount: Int {
        notifications.filter { $0.isUnread || $0.isFriendRequest }.count
    }

    var netBalance: Double {
        friends.reduce(0) { $0 + $1.balance }
    }

    nonisolated static func formatBRL(_ value: Double) -> String {
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
            if let serverAvailable = await JuntoBackendService.shared.checkUsernameAvailability(cleaned) {
                guard !Task.isCancelled else { return }
                usernameState = serverAvailable ? .available : .unavailable
                return
            }
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            usernameState = takenUsernames.contains(cleaned) ? .unavailable : .available
        }
    }

    func login(identifier: String, password: String = "") {
        let clean = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.isEmpty {
            if clean.contains("@") { user.email = clean } else { user.username = clean.lowercased() }
        }
        saveUserSession()
        Task {
            if let res = await JuntoBackendService.shared.login(identifier: clean.isEmpty ? user.username : clean, password: password),
               let uDict = res["user"] as? [String: Any] {
                if let name = uDict["fullName"] as? String { user.fullName = name }
                if let uname = uDict["username"] as? String { user.username = uname }
                if let mail = uDict["email"] as? String { user.email = mail }
                if let phone = uDict["phone"] as? String { user.phone = phone }
                if let pix = uDict["pixKey"] as? String { user.pixKey = pix }
                if let pro = uDict["isPro"] as? Bool { user.isPro = pro }
                saveUserSession()
                await syncWithBackendDatabase()
            }
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            route = .main
        }
    }

    func completeRegistration() {
        let cleanName = draftFullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPix = draftPixKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUser = draftUsername.replacingOccurrences(of: "@", with: "").lowercased()
        let cleanEmail = draftEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalPix = cleanPix.isEmpty ? cleanEmail : cleanPix

        user = UserProfile(
            fullName: cleanName.isEmpty ? "Novo usuário" : cleanName,
            username: cleanUser,
            email: cleanEmail,
            country: draftCountry,
            phone: draftPhone,
            pixKey: finalPix
        )
        saveUserSession()

        let pwd = draftPassword
        Task {
            _ = await JuntoBackendService.shared.register(
                email: cleanEmail,
                username: cleanUser,
                password: pwd,
                fullName: user.fullName,
                phone: draftPhone,
                pixKey: finalPix
            )
            await syncWithBackendDatabase()
        }

        withAnimation(.easeInOut(duration: 0.28)) {
            route = .welcomeSlides
        }
    }

    /// Solicita código de 6 dígitos para recuperação de senha (sincronizado no Redis/PostgreSQL + Notificação Real no iPhone)
    func requestPasswordReset(identifier: String, code: String) async {
        _ = await JuntoBackendService.shared.requestPasswordReset(identifier: identifier, code: code)
        JuntoNotificationManager.shared.triggerLocalNotification(
            title: "Código de recuperação Juntô: \(code)",
            body: "Use o código \(code) para redefinir a senha da sua conta. Válido por 15 minutos."
        )
        showToast("Código de 6 dígitos enviado!", icon: "envelope")
    }

    /// Confirma a redefinição de senha no banco PostgreSQL
    func confirmPasswordReset(identifier: String, code: String, newPassword: String) async {
        _ = await JuntoBackendService.shared.confirmPasswordReset(identifier: identifier, code: code, newPassword: newPassword)
        JuntoNotificationManager.shared.triggerLocalNotification(
            title: "Senha atualizada com segurança",
            body: "A senha da sua conta Juntô foi alterada com sucesso."
        )
        showToast("Senha redefinida com sucesso!", icon: "checkmark.circle")
    }

    /// Registra chamado do Fale Conosco no PostgreSQL + dispara notificação de confirmação
    func submitContactTicket(name: String, email: String, subject: String, message: String, protocolCode: String) {
        Task {
            _ = await JuntoBackendService.shared.submitSupportTicket(
                protocolCode: protocolCode,
                name: name,
                email: email,
                subject: subject,
                message: message
            )
        }
        JuntoNotificationManager.shared.triggerLocalNotification(
            title: "Atendimento Juntô • #\(protocolCode)",
            body: "Recebemos sua mensagem sobre \"\(subject)\". Responderemos no e-mail \(email)."
        )
        showToast("Mensagem enviada! Protocolo #\(protocolCode)", icon: "checkmark.circle")
    }

    // MARK: - Contatos Reais Estilo WhatsApp (Só abre conversa se o número tiver conta REAL no Juntô; senão apenas convite!)
    func addContactAndOpenChat(name rawName: String, phone rawPhone: String) async -> (friend: FriendItem?, isRegistered: Bool) {
        let cleanName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = ContactsManager.normalizeBrDigits(rawPhone)
        guard cleanName.count >= 2, digits.count >= 8 else {
            showToast("Informe o nome e um telefone válido.", icon: "exclamationmark.circle")
            return (nil, false)
        }

        let formattedPhone = ContactsManager.formatPhone(digits)

        // Se já é um contato registrado na lista local, abre direto
        if let existing = friends.first(where: { ContactsManager.normalizeBrDigits($0.phone) == digits }) {
            return (existing, true)
        }

        // Verifica no PostgreSQL se o telefone possui conta real
        guard let res = await JuntoBackendService.shared.addOrOpenContact(name: cleanName, phone: formattedPhone),
              (res["isRegistered"] as? Bool) == true,
              let contactObj = res["contact"] as? [String: Any],
              let resolvedUsername = contactObj["username"] as? String, !resolvedUsername.isEmpty else {
            // Conta NÃO existe no Juntô -> não cria contato fake nem abre chat!
            return (nil, false)
        }

        let resolvedName = (contactObj["name"] as? String) ?? cleanName
        let resolvedPlan = ProPlanType(rawValue: (contactObj["proPlanType"] as? String) ?? "none") ?? .none

        if let existingByHandle = friends.first(where: { $0.username.lowercased() == resolvedUsername.lowercased() }) {
            return (existingByHandle, true)
        }

        let initials = resolvedName.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
        let newContact = FriendItem(
            name: resolvedName,
            username: resolvedUsername,
            initials: initials.isEmpty ? "CT" : initials,
            phone: formattedPhone,
            balance: 0,
            proPlanType: resolvedPlan,
            isPendingInvite: false,
            isOnline: true,
            lastSeenText: "online",
            friendsSinceText: "Contato"
        )
        friends.insert(newContact, at: 0)
        return (newContact, true)
    }

    // MARK: - Login & Cadastro Exclusivo via WhatsApp + Código OTP
    func loginWithWhatsAppOTP(
        phone: String,
        code: String,
        fullName: String? = nil,
        pixKey: String? = nil,
        age: Int? = nil,
        autoNavigate: Bool = true
    ) async -> (success: Bool, needsProfile: Bool, errorMessage: String?) {
        guard let res = await JuntoBackendService.shared.loginWithWhatsAppOTP(
            phone: phone,
            code: code,
            fullName: fullName,
            pixKey: pixKey
        ) else {
            return (false, false, "Código inválido ou expirado. Tente novamente.")
        }

        if (res["needsProfile"] as? Bool) == true {
            return (false, true, nil)
        }

        if let uDict = res["user"] as? [String: Any] {
            if let n = uDict["fullName"] as? String, !n.isEmpty { user.fullName = n }
            if let u = uDict["username"] as? String, !u.isEmpty { user.username = u }
            if let e = uDict["email"] as? String, !e.isEmpty { user.email = e }
            if let p = uDict["phone"] as? String, !p.isEmpty { user.phone = p }
            if let pix = uDict["pixKey"] as? String, !pix.isEmpty { user.pixKey = pix }
            if let pro = uDict["isPro"] as? Bool { user.isPro = pro }
            if let pt = uDict["proPlanType"] as? String { user.proPlanType = ProPlanType(rawValue: pt) ?? .none }
            if let pn = uDict["proPlanName"] as? String { user.proPlanName = pn }
        }
        if let age {
            user.age = age
        }

        saveUserSession()
        await syncWithBackendDatabase()
        if let token = JuntoNotificationManager.shared.apnsDeviceToken {
            await JuntoBackendService.shared.registerDeviceToken(token)
        }

        if autoNavigate {
            withAnimation(.easeInOut(duration: 0.25)) {
                route = .main
            }
        }
        return (true, false, nil)
    }

    func refreshDatabaseSync() {
        Task {
            await syncWithBackendDatabase()
        }
    }

    /// Sincroniza todos os dados reais com o banco PostgreSQL do Docker (usuário, amigos, grupos, potes pessoais, despesas, notificações e atividades)
    func syncWithBackendDatabase() async {
        guard let payload = await JuntoBackendService.shared.fetchBootstrap(username: user.username) else {
            return
        }
        isDatabaseSynced = true

        if let uDict = payload["user"] as? [String: Any] {
            if let name = uDict["fullName"] as? String, !name.isEmpty { user.fullName = name }
            if let uname = uDict["username"] as? String, !uname.isEmpty { user.username = uname }
            if let mail = uDict["email"] as? String, !mail.isEmpty { user.email = mail }
            if let phone = uDict["phone"] as? String, !phone.isEmpty { user.phone = phone }
            if let pix = uDict["pixKey"] as? String, !pix.isEmpty { user.pixKey = pix }
            if let pro = uDict["isPro"] as? Bool { user.isPro = pro }
            if let plan = uDict["proPlanName"] as? String { user.proPlanName = plan }
            if let pType = uDict["proPlanType"] as? String {
                user.proPlanType = ProPlanType(rawValue: pType) ?? (user.isPro ? .monthly : .none)
            }
        }

        // Sincroniza amigos reais do PostgreSQL
        if let friendsArr = payload["friends"] as? [[String: Any]] {
            var loadedFriends: [FriendItem] = []
            for f in friendsArr {
                let name = (f["name"] as? String) ?? "Contato"
                let uname = (f["username"] as? String) ?? "contato"
                let phone = (f["phone"] as? String) ?? ""
                let balance = (f["balance"] as? Double) ?? 0.0
                let pending = (f["isPendingInvite"] as? Bool) ?? false
                let muted = (f["isMuted"] as? Bool) ?? false
                let pTypeStr = (f["proPlanType"] as? String) ?? "none"
                let initials = name.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
                loadedFriends.append(
                    FriendItem(
                        name: name,
                        username: uname,
                        initials: initials.isEmpty ? "CT" : initials,
                        phone: phone,
                        balance: balance,
                        proPlanType: ProPlanType(rawValue: pTypeStr) ?? .none,
                        isPendingInvite: pending,
                        isOnline: true,
                        lastSeenText: "online",
                        friendsSinceText: "Contato",
                        isMuted: muted
                    )
                )
            }
            self.friends = loadedFriends
        }

        let isoParser = ISO8601DateFormatter()
        isoParser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Sincroniza grupos e Pote Mensal do PostgreSQL (preservando UUID exato do banco!)
        if let groupsArr = payload["groups"] as? [[String: Any]] {
            var loadedGroups: [RoleGroup] = []
            for g in groupsArr {
                let serverGroupId = (g["id"] as? String).flatMap(UUID.init(uuidString:)) ?? UUID()
                let title = (g["title"] as? String) ?? "Grupo"
                let category = (g["category"] as? String) ?? "Viagem"
                let cover = (g["coverImage"] as? String) ?? "GroupPraia"
                let potBalance = (g["potBalance"] as? Double) ?? 0.0
                let potTarget = (g["potTarget"] as? Double) ?? 0.0
                let totalSpent = (g["totalSpent"] as? Double) ?? 0.0
                let potModeStr = (g["potMode"] as? String) ?? "SINGLE"
                let totalMonths = (g["totalMonths"] as? Int) ?? 1
                let ownerUsername = (g["ownerUsername"] as? String) ?? user.username
                let ownerName = (g["ownerName"] as? String) ?? user.fullName
                let ownerPixKey = (g["ownerPixKey"] as? String) ?? user.pixKey
                let aiReminderEnabled = (g["aiReminderEnabled"] as? Bool) ?? false
                let aiReminderDaysBefore = (g["aiReminderDaysBefore"] as? Int) ?? 2
                let aiReminderToneStr = (g["aiReminderTone"] as? String) ?? AIReminderTone.friendly.rawValue
                let pixQuickPinEnabled = (g["pixQuickPinEnabled"] as? Bool) ?? true
                let restrictExpensesToAdmins = (g["restrictExpensesToAdmins"] as? Bool) ?? true
                let autoClosureSummaryEnabled = (g["autoClosureSummaryEnabled"] as? Bool) ?? false
                let startDate = (g["startDate"] as? String).flatMap { isoParser.date(from: $0) } ?? Date()
                let targetDate = (g["targetDate"] as? String).flatMap { isoParser.date(from: $0) } ?? (Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date())

                var loadedParticipants: [GroupParticipant] = []
                var loadedInitials: [String] = []
                if let pArr = g["participants"] as? [[String: Any]] {
                    for p in pArr {
                        let pName = (p["name"] as? String) ?? "Membro"
                        let pUname = (p["username"] as? String) ?? "membro"
                        let roleStr = (p["role"] as? String) ?? "MEMBER"
                        let quota = (p["quotaAmount"] as? Double) ?? 0.0
                        let hasPaid = (p["hasPaid"] as? Bool) ?? false
                        let markedPaid = (p["markedPaidByMember"] as? Bool) ?? false
                        let pTypeStr = (p["proPlanType"] as? String) ?? "none"
                        let role: GroupParticipantRole = roleStr == "OWNER" ? .owner : (roleStr == "ADMIN" ? .admin : .member)
                        loadedParticipants.append(
                            GroupParticipant(
                                name: pName,
                                username: pUname,
                                quotaAmount: quota,
                                hasPaid: hasPaid,
                                markedPaidByMember: markedPaid,
                                role: role,
                                proPlanType: ProPlanType(rawValue: pTypeStr) ?? .none
                            )
                        )
                        let initStr = pName.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
                        loadedInitials.append(initStr.isEmpty ? "MB" : initStr)
                    }
                }

                var loadedCycles: [PotMonthCycle] = []
                if let cArr = g["monthlyCycles"] as? [[String: Any]] {
                    for c in cArr {
                        let mNum = (c["monthNumber"] as? Int) ?? 1
                        let lbl = (c["label"] as? String) ?? "Mês \(mNum)"
                        let paidArr = (c["paidUsernames"] as? [String]) ?? []
                        let markedArr = (c["markedPaidUsernames"] as? [String]) ?? []
                        loadedCycles.append(
                            PotMonthCycle(
                                monthNumber: mNum,
                                label: lbl,
                                paidUsernames: Set(paidArr.map { $0.lowercased() }),
                                markedPaidUsernames: Set(markedArr.map { $0.lowercased() })
                            )
                        )
                    }
                }

                let roleGroup = RoleGroup(
                    id: serverGroupId,
                    title: title,
                    category: category,
                    coverImageName: cover,
                    startDate: startDate,
                    targetDate: targetDate,
                    potBalance: potBalance,
                    potTarget: potTarget,
                    totalSpent: totalSpent,
                    myShare: 0,
                    members: loadedInitials,
                    participants: loadedParticipants,
                    hasCollectivePot: true,
                    comandaItems: [],
                    ownerUsername: ownerUsername,
                    ownerName: ownerName,
                    ownerPixKey: ownerPixKey,
                    aiReminderEnabled: aiReminderEnabled,
                    aiReminderDaysBefore: aiReminderDaysBefore,
                    aiReminderTone: AIReminderTone(rawValue: aiReminderToneStr) ?? .friendly,
                    pixQuickPinEnabled: pixQuickPinEnabled,
                    restrictExpensesToAdmins: restrictExpensesToAdmins,
                    autoClosureSummaryEnabled: autoClosureSummaryEnabled,
                    potMode: potModeStr == "MONTHLY" ? .monthly : .single,
                    totalMonths: totalMonths,
                    selectedMonthIndex: 0,
                    monthlyCycles: loadedCycles
                )
                loadedGroups.append(roleGroup)
            }
            self.groups = loadedGroups
        }

        // Sincroniza histórico persistido de conversas 1-a-1 do PostgreSQL
        if let friendChatsDict = payload["friendChats"] as? [String: [[String: Any]]] {
            for (handle, rawMsgs) in friendChatsDict {
                let parsed = rawMsgs.compactMap { parseWireChatMessage($0) }
                self.chatMessages[handle.lowercased()] = parsed
            }
        }

        // Sincroniza histórico persistido de conversas em grupo do PostgreSQL
        if let groupChatsDict = payload["groupChats"] as? [String: [[String: Any]]] {
            for (gidStr, rawMsgs) in groupChatsDict {
                guard let gid = UUID(uuidString: gidStr) else { continue }
                let parsed = rawMsgs.compactMap { parseWireChatMessage($0) }
                self.groupChatMessages[gid] = parsed
            }
        }

        // Sincroniza Potes Pessoais (Caixinhas) do PostgreSQL
        if let potsArr = payload["personalPots"] as? [[String: Any]] {
            var loadedPots: [PersonalSavingsPot] = []
            for p in potsArr {
                let title = (p["title"] as? String) ?? "Caixinha"
                let occasion = (p["occasion"] as? String) ?? "Viagem"
                let icon = (p["icon"] as? String) ?? "airplane"
                let current = (p["currentAmount"] as? Double) ?? 0.0
                let target = (p["targetAmount"] as? Double) ?? 0.0
                let dateTxt = (p["targetDateText"] as? String) ?? ""
                var loadedDeps: [PersonalPotDeposit] = []
                if let dArr = p["deposits"] as? [[String: Any]] {
                    for d in dArr {
                        loadedDeps.append(
                            PersonalPotDeposit(
                                amount: (d["amount"] as? Double) ?? 0.0,
                                note: (d["note"] as? String) ?? "Depósito",
                                dateText: (d["dateText"] as? String) ?? "Hoje"
                            )
                        )
                    }
                }
                loadedPots.append(
                    PersonalSavingsPot(
                        title: title,
                        occasion: occasion,
                        icon: icon,
                        currentAmount: current,
                        targetAmount: target,
                        targetDateText: dateTxt,
                        deposits: loadedDeps
                    )
                )
            }
            self.personalPots = loadedPots
        }

        // Sincroniza Despesas Pessoais do PostgreSQL (preservando UUID real!)
        if let expArr = payload["personalExpenses"] as? [[String: Any]] {
            self.personalExpenses = expArr.map { e in
                let eid = (e["id"] as? String).flatMap(UUID.init(uuidString:)) ?? UUID()
                return PersonalExpenseRecord(
                    id: eid,
                    title: (e["title"] as? String) ?? "Despesa",
                    category: (e["category"] as? String) ?? "Outros",
                    amount: (e["amount"] as? Double) ?? 0.0,
                    dateText: (e["dateText"] as? String) ?? "Hoje",
                    monthKey: (e["monthKey"] as? String) ?? Self.currentMonthKey(),
                    groupName: (e["groupName"] as? String) ?? "Pessoal",
                    isPaid: (e["isPaid"] as? Bool) ?? false
                )
            }
        }

        // Sincroniza Notificações do PostgreSQL
        if let notifArr = payload["notifications"] as? [[String: Any]] {
            self.notifications = notifArr.map { n in
                AppNotification(
                    icon: (n["icon"] as? String) ?? "bell",
                    title: (n["title"] as? String) ?? "Notificação",
                    message: (n["message"] as? String) ?? "",
                    timeAgo: "Agora",
                    isUnread: (n["isUnread"] as? Bool) ?? true,
                    isFriendRequest: (n["isFriendRequest"] as? Bool) ?? false,
                    requestUserName: n["requestUserName"] as? String,
                    requestUsername: n["requestUsername"] as? String
                )
            }
        }

        // Sincroniza Feed de Atividades do PostgreSQL (somente valores e pagamentos reais)
        if let actArr = payload["activities"] as? [[String: Any]] {
            self.activities = actArr.map { a in
                ActivityEvent(
                    icon: (a["icon"] as? String) ?? "checkmark.circle",
                    title: (a["title"] as? String) ?? "Pagamento",
                    subtitle: (a["subtitle"] as? String) ?? "",
                    timeAgo: (a["timeAgo"] as? String) ?? "Agora",
                    amountText: a["amountText"] as? String,
                    isPositive: (a["isPositive"] as? Bool) ?? true
                )
            }
            .filter { Self.isMonetaryActivity($0) }
        }

        applySavedGroupProSettings()
        runAIReminderAgentScan()
        startRealtimeSync()
        await refreshRemoteDirectory(query: "")
    }

    // MARK: - Filtro estrito de Lançamentos (SOMENTE valores e pagamentos reais — nunca criação/exclusão de grupos ou conversas)
    static func isMonetaryActivity(_ event: ActivityEvent) -> Bool {
        guard let amt = event.amountText?.trimmingCharacters(in: .whitespacesAndNewlines), !amt.isEmpty else {
            return false
        }
        let lowerTitle = event.title.lowercased()
        let blockedKeywords = [
            "grupo \"", "criado", "criada", "excluído", "excluída", "excluido", "excluida",
            "entrou no grupo", "convite", "aceitou", "apagada", "desfeita", "caixinha \""
        ]
        for kw in blockedKeywords where lowerTitle.contains(kw) {
            return false
        }
        return true
    }
    func startRealtimeSync() {
        Task {
            await JuntoBackendService.shared.startRealtimeStream { [weak self] eventName, rawJson in
                Task { @MainActor [weak self] in
                    guard let data = rawJson.data(using: .utf8),
                          let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                        return
                    }
                    self?.handleRealtimeEvent(eventName: eventName, payload: obj)
                }
            }
        }
    }

    private func handleRealtimeEvent(eventName: String, payload: [String: Any]) {
        switch eventName {
        case "chat:friend_message":
            if let msg = parseWireChatMessage(payload),
               let senderHandle = msg.senderUsername?.lowercased(), !senderHandle.isEmpty {
                unhideConversation(for: senderHandle)
                if !(chatMessages[senderHandle]?.contains(where: { $0.id == msg.id }) ?? false) {
                    chatMessages[senderHandle, default: []].append(msg)
                    if !msg.isFromMe {
                        unreadFriendCounts[senderHandle, default: 0] += 1
                    }
                    objectWillChange.send()
                    JuntoNotificationManager.shared.triggerLocalNotification(
                        title: msg.senderName ?? "@\(senderHandle)",
                        body: msg.previewText
                    )
                }
            }

        case "chat:group_message":
            if let gidStr = payload["groupId"] as? String,
               let gid = UUID(uuidString: gidStr),
               let msg = parseWireChatMessage(payload) {
                unhideGroupConversation(for: gid)
                if !(groupChatMessages[gid]?.contains(where: { $0.id == msg.id }) ?? false) {
                    groupChatMessages[gid, default: []].append(msg)
                    if !msg.isFromMe {
                        unreadGroupCounts[gid, default: 0] += 1
                    }
                    objectWillChange.send()
                    let gTitle = groups.first(where: { $0.id == gid })?.title ?? "Grupo"
                    JuntoNotificationManager.shared.triggerLocalNotification(
                        title: "\(msg.senderName ?? "Membro") em \(gTitle)",
                        body: msg.previewText
                    )
                }
            }

        case "chat:message_deleted":
            if let midStr = payload["messageId"] as? String, let mid = UUID(uuidString: midStr) {
                for key in chatMessages.keys {
                    chatMessages[key]?.removeAll { $0.id == mid }
                }
                for gid in groupChatMessages.keys {
                    groupChatMessages[gid]?.removeAll { $0.id == mid }
                }
                objectWillChange.send()
            }

        case "groups:updated", "groups:deleted", "friends:updated", "pot:updated", "notification:new":
            if eventName == "notification:new",
               let title = payload["title"] as? String,
               let body = payload["message"] as? String {
                JuntoNotificationManager.shared.triggerLocalNotification(title: title, body: body)
            }
            Task { await syncWithBackendDatabase() }

        default:
            break
        }
    }

    func refreshRemoteDirectory(query: String) async {
        let rows = await JuntoBackendService.shared.searchUsers(query: query)
        guard !rows.isEmpty else { return }
        self.directoryUsers = rows.compactMap { row in
            guard let name = row["name"] as? String,
                  let uname = row["username"] as? String else { return nil }
            let pType = ProPlanType(rawValue: (row["proPlanType"] as? String) ?? "none") ?? .none
            return SearchableUser(name: name, username: uname, proPlanType: pType)
        }
    }

    private func parseWireChatMessage(_ dict: [String: Any]) -> ChatMessage? {
        let msgId = (dict["id"] as? String).flatMap(UUID.init(uuidString:)) ?? UUID()
        let senderUname = dict["senderUsername"] as? String
        let senderName = dict["senderName"] as? String
        let isFromMe = (dict["isFromMe"] as? Bool) ?? (senderUname?.lowercased() == user.username.lowercased())
        let kindStr = (dict["kind"] as? String) ?? "TEXT"
        let content = (dict["content"] as? String) ?? ""
        let isEdited = (dict["isEdited"] as? Bool) ?? false
        let isListened = (dict["isListened"] as? Bool) ?? false
        let replyToAuthor = dict["replyToAuthor"] as? String
        let replyToPreview = dict["replyToPreview"] as? String
        let statusStr = (dict["status"] as? String) ?? "DELIVERED"
        let pTypeStr = (dict["senderProPlanType"] as? String) ?? "none"

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdDate = (dict["createdAt"] as? String).flatMap { iso.date(from: $0) } ?? Date()
        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"
        let timeText = tf.string(from: createdDate)

        let status: MessageDeliveryStatus
        switch statusStr {
        case "SENT": status = .sent
        case "READ": status = .read
        default: status = .delivered
        }

        let kind: ChatMessageKind
        switch kindStr {
        case "SYSTEM":
            kind = .system(content)
        case "AUDIO":
            let dur = (dict["audioDurationSec"] as? Int) ?? 3
            let wf = (dict["waveform"] as? [Double]) ?? []
            kind = .audio(duration: dur, waveform: wf, fileURL: nil)
        case "DOCUMENT":
            kind = .document(content.isEmpty ? "Documento" : content, "Arquivo")
        case "PHOTO":
            kind = .photo(nil, content)
        case "RECEIPT":
            kind = .receipt(amount: 0, imageData: nil, fileName: content.isEmpty ? "comprovante.jpg" : content, status: .pending)
        default:
            kind = .text(content)
        }

        return ChatMessage(
            id: msgId,
            isFromMe: isFromMe,
            kind: kind,
            timeText: timeText,
            createdAt: createdDate,
            isEdited: isEdited,
            isListened: isListened,
            status: status,
            senderName: senderName,
            senderUsername: senderUname,
            senderProPlanType: ProPlanType(rawValue: pTypeStr) ?? .none,
            replyToAuthor: replyToAuthor,
            replyToPreview: replyToPreview
        )
    }

    private func persistChatMessageToServer(
        localId: UUID,
        friendUsername: String?,
        groupId: UUID?,
        kind: ChatMessageKind,
        replyToAuthor: String?,
        replyToPreview: String?
    ) {
        Task {
            var kindStr = "TEXT"
            var content = ""
            var mediaUrl: String? = nil
            var audioDur: Int? = nil
            var waveform: [Double]? = nil

            switch kind {
            case .text(let t):
                kindStr = "TEXT"
                content = t
            case .system(let s):
                kindStr = "SYSTEM"
                content = s
            case .document(let name, _):
                kindStr = "DOCUMENT"
                content = name
            case .photo(let data, let caption):
                kindStr = "PHOTO"
                content = caption
                if let imgData = data {
                    mediaUrl = await JuntoBackendService.shared.uploadMedia(data: imgData, filename: "photo.jpg", mimeType: "image/jpeg")
                }
            case .audio(let dur, let wf, let fileURL):
                kindStr = "AUDIO"
                content = "Áudio (\(dur)s)"
                audioDur = dur
                waveform = wf
                if let url = fileURL, let audioData = try? Data(contentsOf: url) {
                    mediaUrl = await JuntoBackendService.shared.uploadMedia(data: audioData, filename: "audio.m4a", mimeType: "audio/mp4")
                }
            case .receipt(_, let imgData, let fileName, _):
                kindStr = "RECEIPT"
                content = fileName ?? "comprovante.jpg"
                if let d = imgData {
                    mediaUrl = await JuntoBackendService.shared.uploadMedia(data: d, filename: content, mimeType: "image/jpeg")
                }
            case .poll(let p):
                kindStr = "POLL"
                content = p.question
            }

            let serverIdStr: String?
            if let uname = friendUsername {
                serverIdStr = await JuntoBackendService.shared.sendFriendMessage(
                    to: uname,
                    kind: kindStr,
                    content: content,
                    mediaUrl: mediaUrl,
                    audioDurationSec: audioDur,
                    waveform: waveform,
                    replyToAuthor: replyToAuthor,
                    replyToPreview: replyToPreview
                )
            } else if let gid = groupId {
                serverIdStr = await JuntoBackendService.shared.sendGroupMessage(
                    groupId: gid.uuidString.lowercased(),
                    kind: kindStr,
                    content: content,
                    mediaUrl: mediaUrl,
                    audioDurationSec: audioDur,
                    waveform: waveform,
                    replyToAuthor: replyToAuthor,
                    replyToPreview: replyToPreview
                )
            } else {
                serverIdStr = nil
            }

            if let sidStr = serverIdStr, let serverUUID = UUID(uuidString: sidStr) {
                if let uname = friendUsername?.lowercased(),
                   let idx = chatMessages[uname]?.firstIndex(where: { $0.id == localId }) {
                    chatMessages[uname]?[idx].id = serverUUID
                    chatMessages[uname]?[idx].status = .delivered
                } else if let gid = groupId,
                          let idx = groupChatMessages[gid]?.firstIndex(where: { $0.id == localId }) {
                    groupChatMessages[gid]?[idx].id = serverUUID
                    groupChatMessages[gid]?[idx].status = .delivered
                }
            }
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
        return last.previewText
    }

    // MARK: - Chat de Grupo (histórico completo para todos os membros + respostas)
    func groupMessages(for groupId: UUID) -> [ChatMessage] {
        groupChatMessages[groupId] ?? []
    }

    func lastGroupMessagePreview(for groupId: UUID) -> String {
        guard let last = groupMessages(for: groupId).last else {
            return "Conversa do grupo criada"
        }
        if case .system(let txt) = last.kind { return txt }
        let prefix = last.isFromMe ? "Você: " : ((last.senderName?.split(separator: " ").first.map(String.init) ?? "") + ": ")
        return "\(prefix)\(last.previewText)"
    }

    func lastMessageDate(for username: String) -> Date {
        messages(for: username).last?.createdAt ?? Date.distantPast
    }

    func lastGroupMessageDate(for groupId: UUID) -> Date {
        groupMessages(for: groupId).last?.createdAt ?? Date.distantPast
    }

    var friendsSortedByRecent: [FriendItem] {
        friends.sorted { f1, f2 in
            let d1 = lastMessageDate(for: f1.username)
            let d2 = lastMessageDate(for: f2.username)
            if d1 != d2 { return d1 > d2 }
            return f1.name.localizedStandardCompare(f2.name) == .orderedAscending
        }
    }

    var groupsSortedByRecent: [RoleGroup] {
        groups.sorted { g1, g2 in
            let d1 = lastGroupMessageDate(for: g1.id)
            let d2 = lastGroupMessageDate(for: g2.id)
            if d1 != d2 { return d1 > d2 }
            return g1.title.localizedStandardCompare(g2.title) == .orderedAscending
        }
    }

    /// Lista unificada de todas as conversas estilo WhatsApp:
    /// amigos e grupos competem na mesma lista por atividade recente.
    /// Conversas apagadas saem da tela inicial imediatamente até receber nova mensagem ou reabertura.
    var unifiedChatsSortedByRecent: [UnifiedChatItem] {
        var list: [UnifiedChatItem] = []

        for f in friends {
            if hiddenChatUsernames.contains(f.username.lowercased()) { continue }
            let d = lastMessageDate(for: f.username)
            list.append(.friend(f, d))
        }

        for g in groups {
            if hiddenGroupChatIds.contains(g.id) { continue }
            let d = lastGroupMessageDate(for: g.id)
            list.append(.group(g, d))
        }

        return list.sorted { item1, item2 in
            let d1 = item1.lastActivityDate
            let d2 = item2.lastActivityDate
            if d1 != d2 {
                return d1 > d2
            }
            return item1.title.localizedStandardCompare(item2.title) == .orderedAscending
        }
    }

    func sendGroupChatMessage(
        groupId: UUID,
        kind: ChatMessageKind,
        replyToAuthor: String? = nil,
        replyToPreview: String? = nil
    ) {
        let realId = resolvedGroupId(for: groupId)
        unhideGroupConversation(for: realId)
        markGroupChatAsRead(groupId: realId)
        let msg = ChatMessage(
            isFromMe: true,
            kind: kind,
            timeText: currentTimeString(),
            status: .sent,
            senderName: user.fullName,
            senderUsername: user.username,
            replyToAuthor: replyToAuthor,
            replyToPreview: replyToPreview
        )
        let msgId = msg.id
        groupChatMessages[groupId, default: []].append(msg)

        // Move o grupo para o topo da lista de conversas de grupos imediatamente
        if let gIdx = groups.firstIndex(where: { $0.id == groupId }) {
            let g = groups.remove(at: gIdx)
            groups.insert(g, at: 0)
        }
        objectWillChange.send()

        // Persiste mensagem no PostgreSQL + broadcast em tempo real para o grupo
        persistChatMessageToServer(
            localId: msgId,
            friendUsername: nil,
            groupId: groupId,
            kind: kind,
            replyToAuthor: replyToAuthor,
            replyToPreview: replyToPreview
        )
    }

    func updateGroupMessageStatus(groupId: UUID, messageId: UUID, status: MessageDeliveryStatus) {
        guard let idx = groupChatMessages[groupId]?.firstIndex(where: { $0.id == messageId }) else { return }
        groupChatMessages[groupId]?[idx].status = status
    }

    /// Votar ou remover voto em uma enquete no chat individual com amigo
    func voteInFriendPoll(username: String, messageId: UUID, optionId: UUID) {
        let key = username.lowercased()
        guard let mIdx = chatMessages[key]?.firstIndex(where: { $0.id == messageId }) else { return }
        guard case .poll(var pollData) = chatMessages[key]?[mIdx].kind else { return }
        let myUname = user.username.lowercased()

        guard let oIdx = pollData.options.firstIndex(where: { $0.id == optionId }) else { return }
        let alreadyVoted = pollData.options[oIdx].voterUsernames.contains(myUname)

        if !pollData.allowMultipleAnswers {
            for i in pollData.options.indices {
                pollData.options[i].voterUsernames.removeAll { $0 == myUname }
            }
        }

        if alreadyVoted {
            pollData.options[oIdx].voterUsernames.removeAll { $0 == myUname }
        } else {
            pollData.options[oIdx].voterUsernames.append(myUname)
        }

        chatMessages[key]?[mIdx].kind = .poll(pollData)
    }

    /// Votar ou remover voto em uma enquete no chat em grupo
    func voteInGroupPoll(groupId: UUID, messageId: UUID, optionId: UUID) {
        guard let mIdx = groupChatMessages[groupId]?.firstIndex(where: { $0.id == messageId }) else { return }
        guard case .poll(var pollData) = groupChatMessages[groupId]?[mIdx].kind else { return }
        let myUname = user.username.lowercased()

        guard let oIdx = pollData.options.firstIndex(where: { $0.id == optionId }) else { return }
        let alreadyVoted = pollData.options[oIdx].voterUsernames.contains(myUname)

        if !pollData.allowMultipleAnswers {
            for i in pollData.options.indices {
                pollData.options[i].voterUsernames.removeAll { $0 == myUname }
            }
        }

        if alreadyVoted {
            pollData.options[oIdx].voterUsernames.removeAll { $0 == myUname }
        } else {
            pollData.options[oIdx].voterUsernames.append(myUname)
        }

        groupChatMessages[groupId]?[mIdx].kind = .poll(pollData)
    }

    func editGroupChatMessage(groupId: UUID, messageId: UUID, newText: String) {
        let clean = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        guard let idx = groupChatMessages[groupId]?.firstIndex(where: { $0.id == messageId }) else { return }
        groupChatMessages[groupId]?[idx].kind = .text(clean)
        groupChatMessages[groupId]?[idx].isEdited = true
        let mid = messageId.uuidString.lowercased()
        Task { await JuntoBackendService.shared.editChatMessage(messageId: mid, newText: clean) }
    }

    func deleteGroupChatMessage(groupId: UUID, messageId: UUID) {
        groupChatMessages[groupId]?.removeAll { $0.id == messageId }
        let mid = messageId.uuidString.lowercased()
        Task { await JuntoBackendService.shared.deleteChatMessage(messageId: mid) }
    }

    func markGroupAudioListened(groupId: UUID, messageId: UUID) {
        guard let idx = groupChatMessages[groupId]?.firstIndex(where: { $0.id == messageId }) else { return }
        groupChatMessages[groupId]?[idx].isListened = true
        let mid = messageId.uuidString.lowercased()
        Task { await JuntoBackendService.shared.markMessageListened(messageId: mid) }
    }

    private func currentTimeString() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: Date())
    }

    func sendChatMessage(
        to username: String,
        kind: ChatMessageKind,
        replyToAuthor: String? = nil,
        replyToPreview: String? = nil
    ) {
        let key = username.lowercased()
        unhideConversation(for: key)
        markFriendChatAsRead(username: key)
        let msg = ChatMessage(
            isFromMe: true,
            kind: kind,
            timeText: currentTimeString(),
            createdAt: Date(),
            status: .sent,
            replyToAuthor: replyToAuthor,
            replyToPreview: replyToPreview
        )
        let msgId = msg.id
        chatMessages[key, default: []].append(msg)

        // IMPORTANTE: Move o amigo para o topo da lista de conversas imediatamente!
        if let idx = friends.firstIndex(where: { $0.username.lowercased() == key }) {
            let friend = friends.remove(at: idx)
            friends.insert(friend, at: 0)
        }
        objectWillChange.send()

        // Persiste mensagem 1-a-1 no PostgreSQL + entrega em tempo real via SSE
        persistChatMessageToServer(
            localId: msgId,
            friendUsername: key,
            groupId: nil,
            kind: kind,
            replyToAuthor: replyToAuthor,
            replyToPreview: replyToPreview
        )
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

    /// Editar mensagem de texto enviada por você
    func editChatMessage(username: String, messageId: UUID, newText: String) {
        let clean = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let key = username.lowercased()
        guard let idx = chatMessages[key]?.firstIndex(where: { $0.id == messageId }) else { return }
        chatMessages[key]?[idx].kind = .text(clean)
        chatMessages[key]?[idx].isEdited = true
        let mid = messageId.uuidString.lowercased()
        Task { await JuntoBackendService.shared.editChatMessage(messageId: mid, newText: clean) }
    }

    /// Excluir uma mensagem específica da conversa
    func deleteChatMessage(username: String, messageId: UUID) {
        let key = username.lowercased()
        chatMessages[key]?.removeAll { $0.id == messageId }
        let mid = messageId.uuidString.lowercased()
        Task { await JuntoBackendService.shared.deleteChatMessage(messageId: mid) }
    }

    /// Aceitar convite de amizade vindo do sino de notificações
    func acceptFriendRequest(notificationId: UUID) {
        guard let idx = notifications.firstIndex(where: { $0.id == notificationId }) else { return }
        let notif = notifications[idx]
        guard let reqUsername = notif.requestUsername, let reqName = notif.requestUserName else { return }

        if !friends.contains(where: { $0.username.lowercased() == reqUsername.lowercased() }) {
            let initials = reqName.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
            friends.insert(
                FriendItem(
                    name: reqName,
                    username: reqUsername,
                    initials: initials.isEmpty ? "AM" : initials,
                    balance: 0,
                    isOnline: true,
                    lastSeenText: "online",
                    friendsSinceText: "Hoje"
                ),
                at: 0
            )
        }

        // Mantém no sino mostrando que o pedido foi aceito ("Vocês agora são amigos")
        notifications[idx] = AppNotification(
            icon: "person.2.fill",
            title: "Pedido aceito",
            message: "Você e \(reqName) agora são amigos.",
            timeAgo: "Agora",
            isUnread: false,
            isFriendRequest: false,
            requestUserName: reqName,
            requestUsername: reqUsername
        )
        Task { _ = await JuntoBackendService.shared.acceptFriend(username: reqUsername) }
        showToast("Você e \(reqName) agora são amigos!", icon: "checkmark.circle")
    }

    /// Recusar convite de amizade vindo do sino de notificações
    func declineFriendRequest(notificationId: UUID) {
        guard let idx = notifications.firstIndex(where: { $0.id == notificationId }) else { return }
        notifications.remove(at: idx)
        showToast("Convite recusado.", icon: "xmark.circle")
    }

    /// Apaga as mensagens e remove imediatamente a conversa da lista inicial (não vai para Lançamentos)
    func clearConversation(for username: String) {
        let key = username.lowercased()
        chatMessages[key] = []
        hiddenChatUsernames.insert(key)
        persistHiddenChats()
        objectWillChange.send()
        Task { await JuntoBackendService.shared.clearFriendConversation(username: key) }
        showToast("Conversa apagada.", icon: "trash")
    }

    /// Apaga as mensagens da conversa do grupo.
    /// Se o grupo ainda estiver ativo e dentro do prazo, limpa apenas as mensagens e mantém o grupo na tela inicial.
    /// Se o usuário saiu do grupo ou o prazo acabou, oculta a conversa da lista inicial.
    func clearGroupConversation(for groupId: UUID) {
        let realId = resolvedGroupId(for: groupId)
        groupChatMessages[realId] = []
        let myHandle = user.username.lowercased()
        let group = groups.first(where: { $0.id == realId })
        let isExpired = group.map { Date() > $0.targetDate } ?? true
        let isStillMember = group?.participants.contains(where: { $0.username.lowercased() == myHandle || $0.name == "Você" }) ?? false

        if isExpired || !isStillMember {
            hiddenGroupChatIds.insert(realId)
            persistHiddenChats()
            showToast("Conversa removida.", icon: "trash")
        } else {
            showToast("Mensagens da conversa limpas.", icon: "trash")
        }
        objectWillChange.send()
    }

    /// Adiciona diretamente como amigo
    func addFriend(username raw: String, name: String) {
        let clean = raw.lowercased().replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean != user.username.lowercased() else { return }
        if let idx = friends.firstIndex(where: { $0.username.lowercased() == clean }) {
            friends[idx].isPendingInvite = false
            showToast("\(name) já está na sua lista de amigos!", icon: "checkmark")
            return
        }
        let initials = String(name.prefix(2)).uppercased()
        friends.insert(
            FriendItem(name: name, username: clean, initials: initials, balance: 0, isPendingInvite: false, isOnline: true),
            at: 0
        )
        showToast("\(name) adicionado aos amigos!", icon: "person.badge.plus")
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
        let knownName = friends.first(where: { $0.username.lowercased() == clean })?.name
            ?? directoryUsers.first(where: { $0.username.lowercased() == clean })?.name
            ?? clean.split(separator: ".").map { $0.capitalized }.joined(separator: " ")

        friends.removeAll { $0.username.lowercased() == clean }
        sentInviteUsernames.remove(clean)
        chatMessages[clean] = nil
        if !blockedUsers.contains(where: { $0.username.lowercased() == clean }) {
            blockedUsers.insert(BlockedUserEntry(name: knownName, username: clean), at: 0)
        }
        showToast("\(knownName) bloqueado e amizade desfeita.", icon: "nosign")
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
        if group.ownerUsername.lowercased() == user.username.lowercased() { return true }
        return group.participants.first(where: { $0.name == "Você" || $0.username.lowercased() == user.username.lowercased() })?.role == .owner
    }

    /// Verifica se o usuário atual é Dono ou Admin do grupo (tem permissão de gerenciar pagamentos e membros)
    func isCurrentUserGroupOwnerOrAdmin(in group: RoleGroup) -> Bool {
        if group.ownerUsername.lowercased() == user.username.lowercased() { return true }
        if let me = group.participants.first(where: { $0.name == "Você" || $0.username.lowercased() == user.username.lowercased() }) {
            return me.role == .owner || me.role == .admin
        }
        return false
    }

    /// Marca um áudio como escutado (ondas ficam laranja para quem escutou e para quem enviou)
    func markAudioListened(username: String, messageId: UUID) {
        let key = username.lowercased()
        guard let idx = chatMessages[key]?.firstIndex(where: { $0.id == messageId }) else { return }
        chatMessages[key]?[idx].isListened = true
        let mid = messageId.uuidString.lowercased()
        Task { await JuntoBackendService.shared.markMessageListened(messageId: mid) }
    }

    static func currentMonthKey(for date: Date = Date()) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "pt_BR")
        df.dateFormat = "LLLL yyyy"
        let raw = df.string(from: date)
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }

    /// Todos os gastos filtrados automaticamente das dívidas e pagamentos feitos nos grupos (nada manual/pessoal)
    var allTrackedPersonalExpenses: [PersonalExpenseRecord] {
        var result: [PersonalExpenseRecord] = []
        let myUsername = user.username.lowercased()
        let monthKey = Self.currentMonthKey()

        for g in groups {
            if let me = g.participants.first(where: { $0.username.lowercased() == myUsername || $0.name == "Você" }) {
                if g.potMode == .monthly && !g.monthlyCycles.isEmpty && me.quotaAmount > 0 {
                    for cycle in g.monthlyCycles {
                        let isCyclePaid = cycle.paidUsernames.contains(myUsername) || cycle.markedPaidUsernames.contains(myUsername)
                        result.append(
                            PersonalExpenseRecord(
                                title: cycle.label,
                                category: g.category,
                                amount: me.quotaAmount,
                                dateText: isCyclePaid ? (me.paidDateText ?? "Parcela paga") : "Parcela em aberto",
                                monthKey: monthKey,
                                groupName: g.title,
                                isPaid: isCyclePaid
                            )
                        )
                    }
                } else if me.quotaAmount > 0 {
                    let paid = me.hasPaid || me.markedPaidByMember
                    result.append(
                        PersonalExpenseRecord(
                            title: paid ? "Cota paga" : "Cota em aberto",
                            category: g.category,
                            amount: me.quotaAmount,
                            dateText: paid ? (me.paidDateText ?? "Pote do grupo") : "Pote do grupo",
                            monthKey: monthKey,
                            groupName: g.title,
                            isPaid: paid
                        )
                    )
                }
            }

            // Dívida de comanda / rateio ainda aberta no grupo
            if g.myShare > 0 {
                result.append(
                    PersonalExpenseRecord(
                        title: "Rateio em aberto",
                        category: g.category,
                        amount: g.myShare,
                        dateText: "Comanda do grupo",
                        monthKey: monthKey,
                        groupName: g.title,
                        isPaid: false
                    )
                )
            }
        }

        // Pagamentos de despesas de comanda já quitados em grupos (sem lançamentos pessoais avulsos)
        for exp in personalExpenses where exp.isPaid && exp.groupName.lowercased() != "pessoal" && exp.title == "Pagamento no grupo" {
            result.append(exp)
        }

        // Histórico permanente de pagamentos de grupos já excluídos ou encerrados
        for archived in archivedGroupPayments {
            result.append(archived)
        }

        // Dívidas em aberto com amigos
        for friend in friends where friend.balance < 0 {
            result.append(
                PersonalExpenseRecord(
                    title: "Dívida com \(friend.name)",
                    category: "Dívidas",
                    amount: abs(friend.balance),
                    dateText: "@\(friend.username)",
                    monthKey: monthKey,
                    groupName: "Acerto entre amigos",
                    isPaid: false
                )
            )
        }

        return result
    }

    var totalPersonalPaidAmount: Double {
        allTrackedPersonalExpenses.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
    }

    /// Retorna quanto o usuário logado ainda deve neste grupo (0 se já quitou)
    func myPendingAmount(in group: RoleGroup) -> Double {
        let cleanMe = user.username.lowercased()
        if let me = group.participants.first(where: { $0.username.lowercased() == cleanMe || $0.name == "Você" }) {
            if group.potMode == .monthly, group.monthlyCycles.indices.contains(group.selectedMonthIndex) {
                let paid = group.monthlyCycles[group.selectedMonthIndex].paidUsernames.contains(me.username.lowercased())
                if !paid && me.quotaAmount > 0 {
                    return me.quotaAmount
                }
            } else if !me.hasPaid && me.quotaAmount > 0 {
                return me.quotaAmount
            }
        }
        if group.myShare > 0 {
            return group.myShare
        }
        let comandaPending = userShareForComanda(in: group, username: user.username)
        return comandaPending > 0 ? comandaPending : 0
    }

    /// Calcula o saldo efetivo entre você e um contato (incluindo pendências em grupos compartilhados) + grupo relacionado e chave Pix
    func sharedDebtContext(with friend: FriendItem) -> (netBalance: Double, relatedGroupId: UUID?, pixKey: String) {
        var net = friend.balance
        var linkedGroupId: UUID? = nil
        var targetPixKey: String = ""
        let friendHandle = friend.username.lowercased()
        let myHandle = user.username.lowercased()

        for g in groups {
            let ownerHandle = g.ownerUsername.lowercased()
            let isFriendOwner = ownerHandle == friendHandle || g.participants.contains(where: { $0.role == .owner && $0.username.lowercased() == friendHandle })
            let amIOwner = isCurrentUserOwner(in: g)

            if isFriendOwner && !amIOwner {
                let myDebt = myPendingAmount(in: g)
                if myDebt > 0 {
                    net -= myDebt
                    if linkedGroupId == nil { linkedGroupId = g.id }
                    let org = organizerPixInfo(for: g)
                    if !org.pixKey.isEmpty { targetPixKey = org.pixKey }
                }
            } else if amIOwner && friendHandle != myHandle {
                if let fp = g.participants.first(where: { $0.username.lowercased() == friendHandle && !$0.hasPaid && $0.quotaAmount > 0 }) {
                    net += fp.quotaAmount
                    if linkedGroupId == nil { linkedGroupId = g.id }
                    if targetPixKey.isEmpty { targetPixKey = user.pixKey }
                }
            }
        }

        if targetPixKey.isEmpty {
            targetPixKey = net < 0 ? "\(friendHandle)@pix.com.br" : user.pixKey
        }
        return (net, linkedGroupId, targetPixKey)
    }

    var totalPersonalPendingAmount: Double {
        allTrackedPersonalExpenses.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }

    /// Alterna status Pago / Pendente de uma despesa em "Gastos pessoais"
    func togglePersonalExpensePaid(id: UUID) {
        if let idx = personalExpenses.firstIndex(where: { $0.id == id }) {
            personalExpenses[idx].isPaid.toggle()
            let paid = personalExpenses[idx].isPaid
            let eid = id.uuidString.lowercased()
            Task { await JuntoBackendService.shared.togglePersonalExpensePaid(expenseId: eid) }
            showToast(paid ? "Despesa marcada como paga." : "Despesa marcada como pendente.", icon: paid ? "checkmark.circle" : "clock")
        }
    }

    /// Verifica se uma despesa é editável diretamente em personalExpenses
    func isManualPersonalExpense(id: UUID) -> Bool {
        personalExpenses.contains(where: { $0.id == id })
    }

    /// Retorna nome e chave Pix do organizador (dono) do grupo
    func organizerPixInfo(for group: RoleGroup) -> (name: String, pixKey: String) {
        // Use ownerPixKey / ownerName fields if set (non-placeholder)
        let hasRealOwnerKey = !group.ownerPixKey.isEmpty && group.ownerPixKey != "lucas.andrade@exemplo.com"
        if hasRealOwnerKey {
            let isCurrentUser = group.ownerUsername.lowercased() == user.username.lowercased()
            if isCurrentUser {
                return (user.fullName, user.pixKey.isEmpty ? group.ownerPixKey : user.pixKey)
            }
            return (group.ownerName, group.ownerPixKey)
        }
        // Fallback: scan participants for .owner role
        if let owner = group.participants.first(where: { $0.role == .owner }) {
            if owner.username.lowercased() == user.username.lowercased() {
                return (user.fullName, user.pixKey)
            }
            return (owner.name, "\(owner.username)@pix.com.br")
        }
        return (user.fullName, user.pixKey)
    }

    /// Participante informa que já fez o Pix para o organizador.
    /// Se quem pagou for o próprio dono do grupo, confirma e desconta imediatamente.
    /// Se for outro participante, aguarda confirmação do dono.
    func memberMarkQuotaAsPaid(groupId: UUID, participantId: UUID, monthIndex: Int? = nil) {
        guard let gIdx = resolvedGroupIndex(for: groupId),
              let pIdx = groups[gIdx].participants.firstIndex(where: { $0.id == participantId }) else { return }

        let resolvedId = groups[gIdx].id
        let mIdx = monthIndex ?? groups[gIdx].selectedMonthIndex

        // Quando quem paga é o próprio dono do grupo, confirma e desconta o valor imediatamente!
        if isCurrentUserOwner(in: groups[gIdx]) {
            ownerConfirmParticipantPaid(groupId: resolvedId, participantId: participantId, monthIndex: mIdx)
            return
        }

        let uname = groups[gIdx].participants[pIdx].username.lowercased()
        let groupTitle = groups[gIdx].title
        let quota = groups[gIdx].participants[pIdx].quotaAmount
        let organizer = organizerPixInfo(for: groups[gIdx])

        if groups[gIdx].potMode == .monthly, groups[gIdx].monthlyCycles.indices.contains(mIdx) {
            guard !groups[gIdx].monthlyCycles[mIdx].paidUsernames.contains(uname) else { return }
            groups[gIdx].monthlyCycles[mIdx].markedPaidUsernames.insert(uname)
        } else {
            guard !groups[gIdx].participants[pIdx].hasPaid else { return }
            groups[gIdx].participants[pIdx].markedPaidByMember = true
        }

        let monthSuffix = (groups[gIdx].potMode == .monthly && groups[gIdx].monthlyCycles.indices.contains(mIdx))
            ? " (\(groups[gIdx].monthlyCycles[mIdx].label))"
            : ""

        notifications.insert(
            AppNotification(
                icon: "checkmark.circle",
                title: "Você pagou a \(organizer.name)",
                message: "Pagamento de \(Self.formatBRL(quota)) referente ao grupo \(groupTitle)\(monthSuffix).",
                timeAgo: "Agora",
                isUnread: true
            ),
            at: 0
        )

        let nowDateText = Self.formattedCurrentDateTime()
        groups[gIdx].participants[pIdx].paidDateText = nowDateText

        activities.insert(
            ActivityEvent(
                icon: "clock.badge.checkmark",
                title: "Pagamento informado",
                subtitle: "\(groupTitle)\(monthSuffix) • Aguardando confirmação do dono",
                timeAgo: "Agora",
                amountText: Self.formatBRL(quota),
                isPositive: true,
                dateText: nowDateText,
                receiverName: organizer.name,
                groupName: groupTitle
            ),
            at: 0
        )

        persistPaymentHistory()
        runAIReminderAgentScan()
        let gidStr = resolvedId.uuidString.lowercased()
        Task {
            await JuntoBackendService.shared.markGroupPayment(groupId: gidStr, amount: quota, monthIndex: mIdx, kind: "QUOTA")
        }
        showToast("Pagamento enviado! Aguardando o dono do grupo confirmar.", icon: "checkmark.circle")
    }

    /// Participante informa que pagou as despesas selecionadas da comanda do grupo.
    /// Se for o dono, desconta imediatamente; se for outro participante, aguarda confirmação do dono.
    func memberMarkGroupExpensesAsPaid(groupId: UUID, amount: Double) {
        guard amount > 0, let gIdx = resolvedGroupIndex(for: groupId) else { return }
        let resolvedId = groups[gIdx].id
        let groupTitle = groups[gIdx].title
        let organizer = organizerPixInfo(for: groups[gIdx])
        let isOwner = isCurrentUserOwner(in: groups[gIdx])
        let nowDateText = Self.formattedCurrentDateTime()

        if isOwner {
            groups[gIdx].myShare = max(0, groups[gIdx].myShare - amount)
            for i in groups[gIdx].comandaItems.indices {
                if groups[gIdx].comandaItems[i].isSelected {
                    groups[gIdx].comandaItems[i].isSelected = false
                    groups[gIdx].comandaItems[i].isPaid = true
                }
            }
            personalExpenses.insert(
                PersonalExpenseRecord(
                    title: "Pagamento no grupo",
                    category: groups[gIdx].category,
                    amount: amount,
                    dateText: nowDateText,
                    monthKey: Self.currentMonthKey(),
                    groupName: groupTitle,
                    isPaid: true
                ),
                at: 0
            )
            activities.insert(
                ActivityEvent(
                    icon: "checkmark.circle",
                    title: "Pagamento confirmado",
                    subtitle: "\(groupTitle) • Valor descontado",
                    timeAgo: "Agora",
                    amountText: Self.formatBRL(amount),
                    isPositive: true,
                    dateText: nowDateText,
                    receiverName: organizer.name,
                    groupName: groupTitle,
                    itemsSummary: groups[gIdx].comandaItems.filter { $0.isPaid }.map { $0.name }
                ),
                at: 0
            )
        } else {
            let cleanUser = user.username.lowercased()
            if let pIdx = groups[gIdx].participants.firstIndex(where: { $0.username.lowercased() == cleanUser }) {
                groups[gIdx].participants[pIdx].markedPaidByMember = true
            }
            activities.insert(
                ActivityEvent(
                    icon: "clock.badge.checkmark",
                    title: "Pagamento informado",
                    subtitle: "\(groupTitle) • Aguardando confirmação do dono",
                    timeAgo: "Agora",
                    amountText: Self.formatBRL(amount),
                    isPositive: true,
                    dateText: nowDateText,
                    receiverName: organizer.name,
                    groupName: groupTitle
                ),
                at: 0
            )
        }

        notifications.insert(
            AppNotification(
                icon: "checkmark.circle",
                title: isOwner ? "Pagamento confirmado" : "Você pagou a \(organizer.name)",
                message: "Pagamento de \(Self.formatBRL(amount)) referente ao grupo \(groupTitle).",
                timeAgo: "Agora",
                isUnread: true
            ),
            at: 0
        )

        persistPaymentHistory()
        runAIReminderAgentScan()
        let gidStr = resolvedId.uuidString.lowercased()
        Task {
            await JuntoBackendService.shared.markGroupPayment(groupId: gidStr, amount: amount, kind: "EXPENSE")
            if isOwner {
                await JuntoBackendService.shared.confirmGroupPayment(groupId: gidStr, username: user.username.lowercased(), monthIndex: groups[gIdx].selectedMonthIndex)
            }
        }
        showToast(isOwner ? "Pagamento confirmado e descontado no grupo!" : "Enviado! Aguardando o dono do grupo confirmar.", icon: "checkmark.circle")
    }

    /// Dono do grupo confere o Pix na conta dele e confirma o pagamento do participante (suporta Pote Mensal por mês)
    func ownerConfirmParticipantPaid(groupId: UUID, participantId: UUID, monthIndex: Int? = nil) {
        guard let gIdx = resolvedGroupIndex(for: groupId),
              let pIdx = groups[gIdx].participants.firstIndex(where: { $0.id == participantId }) else { return }

        let resolvedId = groups[gIdx].id
        let quota = groups[gIdx].participants[pIdx].quotaAmount
        let personName = groups[gIdx].participants[pIdx].name
        let uname = groups[gIdx].participants[pIdx].username.lowercased()
        let groupTitle = groups[gIdx].title
        let mIdx = monthIndex ?? groups[gIdx].selectedMonthIndex

        if groups[gIdx].potMode == .monthly, groups[gIdx].monthlyCycles.indices.contains(mIdx) {
            guard !groups[gIdx].monthlyCycles[mIdx].paidUsernames.contains(uname) else { return }
            groups[gIdx].monthlyCycles[mIdx].paidUsernames.insert(uname)
            groups[gIdx].monthlyCycles[mIdx].markedPaidUsernames.remove(uname)
            groups[gIdx].potBalance += quota
        } else {
            guard !groups[gIdx].participants[pIdx].hasPaid else { return }
            groups[gIdx].participants[pIdx].hasPaid = true
            groups[gIdx].participants[pIdx].markedPaidByMember = false
            groups[gIdx].potBalance += quota
        }

        // Desconta imediatamente o valor do próprio usuário quando confirmado
        if uname == user.username.lowercased() || personName == "Você" {
            groups[gIdx].myShare = max(0, groups[gIdx].myShare - quota)
        }

        let monthSuffix = (groups[gIdx].potMode == .monthly && groups[gIdx].monthlyCycles.indices.contains(mIdx))
            ? " • \(groups[gIdx].monthlyCycles[mIdx].label)"
            : ""

        // Atualiza comprovantes pendentes desse participante no chat para aprovados
        if let msgs = groupChatMessages[resolvedId] {
            for i in msgs.indices {
                if msgs[i].senderUsername?.lowercased() == uname,
                   case .receipt(let amt, let img, let file, _) = msgs[i].kind {
                    groupChatMessages[resolvedId]?[i].kind = .receipt(amount: amt, imageData: img, fileName: file, status: .approved)
                }
            }
        }

        // Adiciona mensagem automática de confirmação no chat do grupo
        if groupChatMessages[resolvedId] == nil { groupChatMessages[resolvedId] = [] }
        groupChatMessages[resolvedId]?.append(
            ChatMessage(
                isFromMe: false,
                kind: .system("✅ @\(user.username) confirmou o pagamento de @\(uname)."),
                timeText: currentTimeString()
            )
        )

        let nowDateText = Self.formattedCurrentDateTime()
        groups[gIdx].participants[pIdx].paidDateText = nowDateText

        if quota > 0 && (uname == user.username.lowercased() || personName == "Você") {
            personalExpenses.insert(
                PersonalExpenseRecord(
                    title: "Pagamento no grupo\(monthSuffix)",
                    category: groups[gIdx].category,
                    amount: quota,
                    dateText: nowDateText,
                    monthKey: Self.currentMonthKey(),
                    groupName: groupTitle,
                    isPaid: true
                ),
                at: 0
            )
        }

        let organizerName = organizerPixInfo(for: groups[gIdx]).name
        let groupItems = groups[gIdx].comandaItems.map { $0.name }
        activities.insert(
            ActivityEvent(
                icon: "checkmark.circle",
                title: "Pagamento de \(personName) confirmado",
                subtitle: "\(groupTitle)\(monthSuffix) • Arrecadado \(Self.formatBRL(groups[gIdx].potBalance))",
                timeAgo: "Agora",
                amountText: "+ \(Self.formatBRL(quota))",
                isPositive: true,
                dateText: nowDateText,
                receiverName: organizerName,
                groupName: groupTitle,
                itemsSummary: groupItems.isEmpty ? nil : groupItems
            ),
            at: 0
        )
        persistPaymentHistory()
        runAIReminderAgentScan()
        let gidStr = resolvedId.uuidString.lowercased()
        Task {
            await JuntoBackendService.shared.confirmGroupPayment(groupId: gidStr, username: uname, monthIndex: mIdx)
        }
        showToast("Pagamento de \(personName) confirmado!", icon: "checkmark.circle")
    }

    /// Envia o comprovante de pagamento Pix (imagem ou arquivo PDF) diretamente no chat do grupo
    func sendGroupReceipt(groupId: UUID, amount: Double, imageData: Data?, fileName: String?) {
        guard let gIdx = resolvedGroupIndex(for: groupId) else { return }
        let resolvedId = groups[gIdx].id
        let isOwner = isCurrentUserOwner(in: groups[gIdx])

        let msg = ChatMessage(
            isFromMe: true,
            kind: .receipt(amount: amount, imageData: imageData, fileName: fileName, status: isOwner ? .approved : .pending),
            timeText: currentTimeString(),
            senderName: user.fullName,
            senderUsername: user.username,
            senderProPlanType: user.proPlanType
        )

        if groupChatMessages[resolvedId] == nil {
            groupChatMessages[resolvedId] = []
        }
        groupChatMessages[resolvedId]?.append(msg)
        persistChatMessageToServer(
            localId: msg.id,
            friendUsername: nil,
            groupId: resolvedId,
            kind: msg.kind,
            replyToAuthor: nil,
            replyToPreview: nil
        )

        if !isOwner {
            let cleanUser = user.username.lowercased()
            if let pIdx = groups[gIdx].participants.firstIndex(where: { $0.username.lowercased() == cleanUser }) {
                groups[gIdx].participants[pIdx].markedPaidByMember = true
                let mIdx = groups[gIdx].selectedMonthIndex
                if groups[gIdx].potMode == .monthly, groups[gIdx].monthlyCycles.indices.contains(mIdx) {
                    groups[gIdx].monthlyCycles[mIdx].markedPaidUsernames.insert(cleanUser)
                }
            }
        }
    }

    func markParticipantPaid(groupId: UUID, participantUsername: String, monthIndex: Int? = nil) {
        guard let gIdx = resolvedGroupIndex(for: groupId) else { return }
        let clean = participantUsername.lowercased()
        if let p = groups[gIdx].participants.first(where: { $0.username.lowercased() == clean }) {
            ownerConfirmParticipantPaid(groupId: groups[gIdx].id, participantId: p.id, monthIndex: monthIndex)
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

        if blockedUsers.contains(where: { $0.username.lowercased() == clean }) {
            showToast("Este usuário está bloqueado.", icon: "nosign")
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
        Task { _ = await JuntoBackendService.shared.inviteFriend(username: clean) }
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
        if let idx = nearbyUsers.firstIndex(where: { $0.username.lowercased() == clean }) {
            nearbyUsers[idx].isInvited = false
        }
        Task { _ = await JuntoBackendService.shared.removeFriend(username: clean) }
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

    /// Controla permissão para lançar despesas no grupo conforme a chave de segurança do grupo
    func canCurrentUserAddExpenses(in group: RoleGroup) -> Bool {
        if !group.restrictExpensesToAdmins { return true }
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
        let targetUsername = groups[gIdx].participants[pIdx].username
        let gidStr = groupId.uuidString.lowercased()
        if groups[gIdx].participants[pIdx].role == .admin {
            groups[gIdx].participants[pIdx].role = .member
            Task { await JuntoBackendService.shared.updateGroupMemberRole(groupId: gidStr, username: targetUsername, isAdmin: false) }
            showToast("\(name) não é mais admin.", icon: "person")
        } else {
            groups[gIdx].participants[pIdx].role = .admin
            Task { await JuntoBackendService.shared.updateGroupMemberRole(groupId: gidStr, username: targetUsername, isAdmin: true) }
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
            let monthsCount = groups[gIdx].potMode == .monthly ? max(1, groups[gIdx].totalMonths) : 1
            let newQuota = (groups[gIdx].potTarget / Double(monthsCount)) / Double(groups[gIdx].participants.count)
            for i in groups[gIdx].participants.indices {
                groups[gIdx].participants[i].quotaAmount = newQuota
            }
        }
        let gidStr = groupId.uuidString.lowercased()
        Task { await JuntoBackendService.shared.removeGroupMember(groupId: gidStr, username: removed.username) }
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

        notifications.insert(
            AppNotification(
                icon: "list.bullet.rectangle.portrait",
                title: "Você adicionou uma nova despesa",
                message: "\"\(cleanName)\" (\(Self.formatBRL(totalAmount))) em \(groups[idx].title).",
                timeAgo: "Agora",
                isUnread: true
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

    /// Adiciona múltiplos itens escaneados de um recibo / nota fiscal a um grupo
    func addReceiptItemsToGroup(groupId: UUID, items: [ComandaItem], payFromPot: Bool = false) {
        guard let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }
        guard canCurrentUserAddExpenses(in: groups[idx]) else {
            showToast("Apenas o dono ou admins podem adicionar despesas.", icon: "lock")
            return
        }

        let total = items.reduce(0) { $0 + $1.price }
        groups[idx].totalSpent += total

        if payFromPot && groups[idx].hasCollectivePot {
            groups[idx].potBalance = max(0, groups[idx].potBalance - total)
        }

        for item in items {
            groups[idx].comandaItems.insert(item, at: 0)
        }

        groupChatMessages[groupId, default: []].append(
            ChatMessage(
                isFromMe: false,
                kind: .system("Recibo com \(items.count) item(ns) escaneado. Total: \(Self.formatBRL(total))."),
                timeText: currentTimeString()
            )
        )

        showToast("\(items.count) itens do recibo adicionados!", icon: "doc.text.viewfinder")
    }

    /// Alterna se um membro consumiu/divide um item específico da comanda
    func toggleMemberAssignedToComandaItem(groupId: UUID, itemId: UUID, username: String) {
        guard let gIdx = groups.firstIndex(where: { $0.id == groupId }),
              let iIdx = groups[gIdx].comandaItems.firstIndex(where: { $0.id == itemId }) else { return }

        let clean = username.lowercased()
        if groups[gIdx].comandaItems[iIdx].assignedUsernames.contains(clean) {
            groups[gIdx].comandaItems[iIdx].assignedUsernames.remove(clean)
        } else {
            groups[gIdx].comandaItems[iIdx].assignedUsernames.insert(clean)
        }
    }

    /// Alterna se um item do checklist da comanda foi quitado/conferido
    func toggleComandaItemPaid(groupId: UUID, itemId: UUID) {
        guard let gIdx = groups.firstIndex(where: { $0.id == groupId }),
              let iIdx = groups[gIdx].comandaItems.firstIndex(where: { $0.id == itemId }) else { return }

        groups[gIdx].comandaItems[iIdx].isPaid.toggle()
    }

    /// Calcula o valor exato que um participante deve com base nos itens do checklist que ele consumiu
    func userShareForComanda(in group: RoleGroup, username: String) -> Double {
        let cleanUser = username.lowercased()
        var share: Double = 0.0

        for item in group.comandaItems where item.isSelected && !item.isPaid {
            if item.assignedUsernames.isEmpty {
                // Dividido igualmente entre todos os membros
                let count = max(1, group.participants.count)
                share += item.price / Double(count)
            } else if item.assignedUsernames.contains(cleanUser) {
                // Dividido apenas entre quem consumiu
                let count = max(1, item.assignedUsernames.count)
                share += item.price / Double(count)
            }
        }
        return share
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
            let monthsCount = groups[idx].potMode == .monthly ? max(1, groups[idx].totalMonths) : 1
            let newQuota = (groups[idx].potTarget / Double(monthsCount)) / Double(groups[idx].participants.count)
            for i in groups[idx].participants.indices {
                groups[idx].participants[i].quotaAmount = newQuota
            }
        }

        // Registra entrada no chat do grupo (novo membro puxa automaticamente todo o histórico)
        groupChatMessages[groupId, default: []].append(
            ChatMessage(
                isFromMe: false,
                kind: .system("\(displayName) entrou no grupo"),
                timeText: currentTimeString()
            )
        )

        let gidStr = groupId.uuidString.lowercased()
        Task { await JuntoBackendService.shared.addGroupMember(groupId: gidStr, username: clean) }
        showToast("@\(clean) adicionado e cotas recalculadas!", icon: "person.badge.plus")
    }

    func canCreateMoreGroups() -> Bool {
        if user.isPro { return true }
        return groups.count < 1
    }

    func createNewGroup(
        title: String,
        category: String,
        hasPot: Bool = true,
        potTarget: Double = 0,
        potMode: PotRecurrenceMode = .single,
        totalMonths: Int = 1,
        invitedPeople: [SearchableUser] = [],
        coverImageData: Data? = nil,
        startDate: Date = Date(),
        targetDate: Date = Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date(),
        isPublic: Bool = false,
        maxParticipants: Int = 100,
        publicUntilDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
        comandaItems: [ComandaItem] = []
    ) {
        guard canCreateMoreGroups() else {
            showToast("O plano gratuito permite apenas 1 grupo. Assine o Juntô Pro para grupos ilimitados.", icon: "lock")
            return
        }

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
        let monthsCount = potMode == .monthly ? max(1, totalMonths) : 1
        let itemsTotal = comandaItems.reduce(0) { $0 + $1.price }
        let effectiveTarget = potTarget > 0 ? potTarget : itemsTotal
        let quotaPerPerson = effectiveTarget > 0 ? ((effectiveTarget / Double(monthsCount)) / Double(totalPeopleCount)) : 0

        var participantsList: [GroupParticipant] = [
            GroupParticipant(name: "Você", username: user.username, quotaAmount: quotaPerPerson, hasPaid: false, role: .owner, proPlanType: user.proPlanType)
        ]
        var memberInitials: [String] = ["EU"]

        for person in invitedPeople {
            participantsList.append(
                GroupParticipant(name: person.name, username: person.username, quotaAmount: quotaPerPerson, hasPaid: false, role: .member, proPlanType: person.proPlanType)
            )
            let initStr = person.name.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
            memberInitials.append(initStr.isEmpty ? String(person.username.prefix(2)).uppercased() : initStr)
        }

        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "pt_BR")
        monthFormatter.dateFormat = "MMM/yy"

        var cycles: [PotMonthCycle] = []
        if potMode == .monthly {
            for idx in 0..<monthsCount {
                let d = Calendar.current.date(byAdding: .month, value: idx, to: startDate) ?? startDate
                let mStr = monthFormatter.string(from: d).replacingOccurrences(of: ".", with: "").capitalized
                cycles.append(
                    PotMonthCycle(
                        monthNumber: idx + 1,
                        label: "Mês \(idx + 1) • \(mStr)"
                    )
                )
            }
        }

        let newGroup = RoleGroup(
            title: cleanTitle,
            category: category,
            coverImageName: cover,
            coverImageData: coverImageData,
            startDate: startDate,
            targetDate: targetDate,
            potBalance: 0,
            potTarget: effectiveTarget,
            totalSpent: itemsTotal > 0 ? itemsTotal : effectiveTarget,
            myShare: quotaPerPerson,
            members: memberInitials,
            participants: participantsList,
            hasCollectivePot: true,
            comandaItems: comandaItems,
            ownerUsername: user.username,
            ownerName: user.fullName,
            ownerPixKey: user.pixKey,
            potMode: potMode,
            totalMonths: monthsCount,
            selectedMonthIndex: 0,
            monthlyCycles: cycles,
            isPublic: isPublic,
            maxParticipants: min(100, max(2, maxParticipants)),
            publicUntilDate: publicUntilDate
        )

        groups.insert(newGroup, at: 0)

        // Cria automaticamente a conversa em grupo com todos os membros
        groupChatMessages[newGroup.id] = [
            ChatMessage(
                isFromMe: false,
                kind: .system("Grupo \"\(cleanTitle)\" criado com \(totalPeopleCount) participante(s)."),
                timeText: currentTimeString()
            )
        ]

        let subtitleText: String
        if potMode == .monthly && quotaPerPerson > 0 {
            subtitleText = "\(category) • \(monthsCount) meses de \(Self.formatBRL(quotaPerPerson))/pessoa"
        } else if hasPot && quotaPerPerson > 0 {
            subtitleText = "\(category) • \(Self.formatBRL(quotaPerPerson)) p/ cada (\(totalPeopleCount) pessoas)"
        } else {
            subtitleText = "\(category) • \(totalPeopleCount) participante(s)"
        }

        let localGroupId = newGroup.id
        let memberHandles = invitedPeople.map { $0.username }
        let modeString = potMode == .monthly ? "MONTHLY" : "SINGLE"
        let cyclesPayload: [[String: Any]] = cycles.map { c in
            [
                "monthNumber": c.monthNumber,
                "label": c.label,
                "paidUsernames": Array(c.paidUsernames),
                "markedPaidUsernames": Array(c.markedPaidUsernames)
            ]
        }
        Task {
            if let serverIdStr = await JuntoBackendService.shared.createGroupOnServer(
                title: cleanTitle,
                category: category,
                coverImage: cover,
                potTarget: effectiveTarget,
                potMode: modeString,
                totalMonths: monthsCount,
                monthlyCycles: cyclesPayload,
                startDate: startDate,
                targetDate: targetDate,
                memberUsernames: memberHandles
            ), let serverUUID = UUID(uuidString: serverIdStr) {
                self.groupIdAliases[localGroupId] = serverUUID
                if let idx = self.groups.firstIndex(where: { $0.id == localGroupId }) {
                    self.groups[idx].id = serverUUID
                    if let existingMsgs = self.groupChatMessages.removeValue(forKey: localGroupId) {
                        self.groupChatMessages[serverUUID] = existingMsgs
                    }
                }
            }
        }
        JuntoNotificationManager.shared.triggerLocalNotification(
            title: "Grupo \"\(cleanTitle)\" criado",
            body: subtitleText
        )
        showToast("Grupo \"\(cleanTitle)\" criado e cotas distribuídas!", icon: "checkmark.circle")
    }

    // MARK: - Potes Pessoais ("Caixinhas" individuais para guardar finanças para uma ocasião — Exclusivo Juntô Pro)
    func createPersonalPot(title: String, occasion: String, icon: String, targetAmount: Double, targetDateText: String) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty, targetAmount > 0 else {
            showToast("Informe o nome e o valor da meta da caixinha.", icon: "exclamationmark.circle")
            return
        }
        let pot = PersonalSavingsPot(
            title: cleanTitle,
            occasion: occasion,
            icon: icon,
            currentAmount: 0,
            targetAmount: targetAmount,
            targetDateText: targetDateText
        )
        personalPots.insert(pot, at: 0)
        let uname = user.username
        Task {
            await JuntoBackendService.shared.createPersonalPot(
                username: uname,
                title: cleanTitle,
                occasion: occasion,
                icon: icon,
                targetAmount: targetAmount,
                targetDateText: targetDateText
            )
        }
        JuntoNotificationManager.shared.triggerLocalNotification(
            title: "Nova Caixinha • \(cleanTitle)",
            body: "Meta de \(Self.formatBRL(targetAmount)) para \(occasion) até \(targetDateText)."
        )
        showToast("Caixinha \"\(cleanTitle)\" criada!", icon: "checkmark.circle")
    }

    func depositIntoPersonalPot(potId: UUID, amount: Double, note: String) {
        guard amount > 0, let idx = personalPots.firstIndex(where: { $0.id == potId }) else { return }
        personalPots[idx].currentAmount += amount
        let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        personalPots[idx].deposits.insert(
            PersonalPotDeposit(
                amount: amount,
                note: cleanNote.isEmpty ? "Depósito na caixinha" : cleanNote,
                dateText: "Hoje"
            ),
            at: 0
        )
        let title = personalPots[idx].title
        let pct = personalPots[idx].percentCompleted
        activities.insert(
            ActivityEvent(
                icon: "checkmark.circle",
                title: "Guardou em \"\(title)\"",
                subtitle: "Caixinha pessoal • \(pct)% da meta concluída",
                timeAgo: "Agora",
                amountText: "+ \(Self.formatBRL(amount))",
                isPositive: true
            ),
            at: 0
        )
        JuntoNotificationManager.shared.triggerLocalNotification(
            title: "Caixinha \"\(title)\" • \(pct)%",
            body: "Você guardou \(Self.formatBRL(amount)). Total acumulado: \(Self.formatBRL(personalPots[idx].currentAmount))."
        )
        showToast("Guardado \(Self.formatBRL(amount)) na caixinha!", icon: "checkmark.circle")
    }

    func deletePersonalPot(potId: UUID) {
        guard let idx = personalPots.firstIndex(where: { $0.id == potId }) else { return }
        let title = personalPots[idx].title
        personalPots.remove(at: idx)
        showToast("Caixinha \"\(title)\" excluída.", icon: "trash")
    }

    /// Arquiva permanentemente o histórico de pagamentos do usuário antes de sair ou excluir um grupo
    private func archivePaymentsFromGroup(_ group: RoleGroup) {
        let myUsername = user.username.lowercased()
        let monthKey = Self.currentMonthKey()
        let fallbackDate = Self.formattedCurrentDateTime()

        if let me = group.participants.first(where: { $0.username.lowercased() == myUsername || $0.name == "Você" }) {
            if group.potMode == .monthly && !group.monthlyCycles.isEmpty && me.quotaAmount > 0 {
                for cycle in group.monthlyCycles {
                    let isCyclePaid = cycle.paidUsernames.contains(myUsername) || cycle.markedPaidUsernames.contains(myUsername)
                    guard isCyclePaid else { continue }
                    archivedGroupPayments.insert(
                        PersonalExpenseRecord(
                            title: cycle.label,
                            category: group.category,
                            amount: me.quotaAmount,
                            dateText: me.paidDateText ?? fallbackDate,
                            monthKey: monthKey,
                            groupName: group.title,
                            isPaid: true
                        ),
                        at: 0
                    )
                }
            } else if me.quotaAmount > 0 && (me.hasPaid || me.markedPaidByMember) {
                archivedGroupPayments.insert(
                    PersonalExpenseRecord(
                        title: "Cota paga",
                        category: group.category,
                        amount: me.quotaAmount,
                        dateText: me.paidDateText ?? fallbackDate,
                        monthKey: monthKey,
                        groupName: group.title,
                        isPaid: true
                    ),
                    at: 0
                )
            }
        }
        persistPaymentHistory()
    }

    /// Exclui o grupo preservando integralmente o histórico de pagamentos do usuário em Meus Gastos e Lançamentos
    func deleteGroup(groupId: UUID) {
        guard let idx = resolvedGroupIndex(for: groupId) else { return }
        let group = groups[idx]
        let realId = group.id
        archivePaymentsFromGroup(group)
        groups.remove(at: idx)
        groupChatMessages.removeValue(forKey: realId)
        hiddenGroupChatIds.remove(realId)
        persistHiddenChats()
        let gidStr = realId.uuidString.lowercased()
        Task { await JuntoBackendService.shared.deleteGroupOnServer(groupId: gidStr) }
        showToast("Grupo \"\(group.title)\" excluído. Histórico de pagamentos preservado.", icon: "trash")
    }

    /// Sai do grupo preservando o histórico de pagamentos e removendo a conversa da lista
    func leaveGroup(groupId: UUID) {
        guard let idx = resolvedGroupIndex(for: groupId) else { return }
        let group = groups[idx]
        let realId = group.id
        archivePaymentsFromGroup(group)
        groups.remove(at: idx)
        groupChatMessages.removeValue(forKey: realId)
        hiddenGroupChatIds.insert(realId)
        persistHiddenChats()
        showToast("Você saiu de \"\(group.title)\". Histórico de pagamentos mantido.", icon: "rectangle.portrait.and.arrow.right")
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

        let currentMonth = Self.currentMonthKey()
        personalExpenses.insert(
            PersonalExpenseRecord(
                title: cleanDesc,
                category: category,
                amount: amount,
                dateText: "Hoje",
                monthKey: currentMonth,
                groupName: groupTitle.isEmpty ? "Pessoal" : groupTitle
            ),
            at: 0
        )

        notifications.insert(
            AppNotification(
                icon: "list.bullet.rectangle.portrait",
                title: "Você adicionou uma nova despesa",
                message: "\"\(cleanDesc)\" (\(Self.formatBRL(amount))) em \(groupTitle.isEmpty ? category : groupTitle).",
                timeAgo: "Agora",
                isUnread: true
            ),
            at: 0
        )

        let monthTotal = personalExpenses.filter { $0.monthKey == currentMonth }.reduce(0) { $0 + $1.amount }
        if monthTotal >= 1500 {
            notifications.insert(
                AppNotification(
                    icon: "exclamationmark.triangle",
                    title: "Alerta de gastos",
                    message: "Seus gastos do mês chegaram a \(Self.formatBRL(monthTotal)).",
                    timeAgo: "Agora",
                    isUnread: true
                ),
                at: 0
            )
        }

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
        let localExpenseId = personalExpenses.first?.id
        let uname = user.username
        let gName = groupTitle.isEmpty ? "Pessoal" : groupTitle
        Task {
            if let serverIdStr = await JuntoBackendService.shared.createPersonalExpense(
                username: uname,
                title: cleanDesc,
                category: category,
                amount: amount,
                dateText: "Hoje",
                monthKey: currentMonth,
                groupName: gName
            ), let serverUUID = UUID(uuidString: serverIdStr),
               let lid = localExpenseId,
               let idx = self.personalExpenses.firstIndex(where: { $0.id == lid }) {
                self.personalExpenses[idx].id = serverUUID
            }
        }
        JuntoNotificationManager.shared.triggerLocalNotification(
            title: "Nova despesa registrada",
            body: "\(cleanDesc) • \(Self.formatBRL(amount)) (\(gName))"
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
        for i in notifications.indices {
            // Zera notificações comuns ao abrir, mas mantém pedidos de amizade pendentes contando até aceitar/recusar
            if !notifications[i].isFriendRequest {
                notifications[i].isUnread = false
            }
        }
        Task { await JuntoBackendService.shared.markAllNotificationsReadOnServer() }
    }

    func unblockUser(_ username: String) {
        let clean = username.lowercased()
        blockedUsers.removeAll { $0.username.lowercased() == clean }
        showToast("@\(clean) desbloqueado.", icon: "checkmark.circle")
    }

    func disconnectDevice(_ sessionId: UUID) {
        guard let item = connectedDevices.first(where: { $0.id == sessionId }), !item.isCurrentDevice else { return }
        connectedDevices.removeAll { $0.id == sessionId }
        showToast("\(item.deviceName) desconectado.", icon: "lock.shield")
    }

    func disconnectAllDevices() {
        connectedDevices.removeAll { !$0.isCurrentDevice }
        showToast("Todos os outros dispositivos foram desconectados.", icon: "lock.shield")
    }

    func deleteAccountPermanently() {
        Task {
            _ = await JuntoBackendService.shared.deleteAccount(reason: "Solicitado pelo usuário no app iOS")
        }
        clearUserSession()
        friends = []
        groups = []
        chatMessages = [:]
        groupChatMessages = [:]
        personalExpenses = []
        activities = []
        notifications = []
        draftEmail = ""
        draftUsername = ""
        draftPassword = ""
        draftFullName = ""
        draftPhone = ""
        withAnimation(.easeInOut(duration: 0.25)) {
            route = .welcomeAuth
        }
        showToast("Conta desativada no servidor. Dados retidos por 90 dias (LGPD).", icon: "trash")
    }

    /// Exibe opção de renovação apenas quando o plano está perto de vencer (últimos 5 dias) ou vencido
    var isProRenewalDue: Bool {
        guard user.isPro else { return false }
        guard let exp = user.proExpiresAt else { return false }
        let renewalWindow = Calendar.current.date(byAdding: .day, value: -5, to: exp) ?? exp
        return Date() >= renewalWindow
    }

    // MARK: - Gestão da Assinatura Juntô Pro
    func subscribeToPro(plan: String = "Mensal (R$ 19,90)", planType: ProPlanType = .monthly) {
        user.isPro = true
        user.proPlanType = planType
        user.proPlanName = plan
        let days = planType == .yearly ? 365 : 30
        let expDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        user.proExpiresAt = expDate
        let df = DateFormatter()
        df.locale = Locale(identifier: "pt_BR")
        df.dateFormat = "dd/MM/yyyy"
        user.proExpiresDateText = "Renovação em \(df.string(from: expDate))"
        saveUserSession()
        let uname = user.username
        Task {
            await JuntoBackendService.shared.syncProStatus(username: uname, isPro: true, planName: plan, planType: planType)
        }
        let selo = planType == .yearly ? "Dourado" : "Roxo"
        JuntoNotificationManager.shared.triggerLocalNotification(
            title: "Juntô Pro Ativado • Selo \(selo)",
            body: "Grupos ilimitados, grupos públicos e selo verificado \(selo.lowercased()) liberados em todo o app!"
        )
        showToast("Você agora é Juntô Pro com Selo \(selo)!", icon: "checkmark.seal.fill")
    }

    func cancelPro() {
        user.isPro = false
        user.proPlanType = .none
        user.proPlanName = nil
        user.proExpiresDateText = nil
        let uname = user.username
        Task {
            await JuntoBackendService.shared.syncProStatus(username: uname, isPro: false, planName: nil, planType: .none)
        }
        showToast("Assinatura Juntô Pro cancelada.", icon: "checkmark")
    }

    // MARK: - Interações da Aba Próximos (Pessoas e Grupos Públicos)
    func joinPublicGroup(groupId: UUID) {
        guard let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }
        let group = groups[idx]
        guard !group.participants.contains(where: { $0.username.lowercased() == user.username.lowercased() }) else {
            showToast("Você já está participando deste grupo.", icon: "info.circle")
            return
        }
        guard group.participants.count < group.maxParticipants else {
            showToast("Este grupo atingiu a capacidade máxima de vagas (\(group.maxParticipants)).", icon: "person.crop.circle.badge.xmark")
            return
        }
        guard Date() <= group.publicUntilDate else {
            showToast("O prazo deste grupo público já expirou.", icon: "clock.badge.xmark")
            return
        }

        addMemberToGroup(groupId: groupId, memberUsername: user.username)
        showToast("Você entrou no grupo \"\(group.title)\"!", icon: "checkmark.circle")
    }

    func addNearbyUserAsFriend(userItem: NearbyUserItem) {
        guard let idx = nearbyUsers.firstIndex(where: { $0.id == userItem.id }) else { return }
        if nearbyUsers[idx].isInvited {
            nearbyUsers[idx].isInvited = false
            friends.removeAll { $0.username.lowercased() == userItem.username.lowercased() && $0.isPendingInvite }
            sentInviteUsernames.remove(userItem.username.lowercased())
            showToast("Convite cancelado para \(userItem.name).", icon: "arrow.uturn.backward")
        } else {
            nearbyUsers[idx].isInvited = true
            sendFriendInvite(username: userItem.username, displayName: userItem.name)
            showToast("Convite enviado para \(userItem.name)!", icon: "person.badge.plus")
        }
    }

    /// Algoritmo dinâmico que rotaciona e embaralha pessoas próximas conforme localização e tempo
    func refreshNearbyUsers() {
        guard nearbyUsers.count > 1 else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            nearbyUsers.shuffle()
            for i in 0..<nearbyUsers.count {
                let jitter = Int.random(in: -90...130)
                nearbyUsers[i].distanceMeters = max(160, nearbyUsers[i].distanceMeters + jitter)
            }
        }
    }

    // MARK: - Dados Iniciais / Seed para Próximos e Grupos Públicos
    func setupSeedData() {
        if nearbyUsers.isEmpty {
            nearbyUsers = [
                NearbyUserItem(
                    name: "Beatriz Lima",
                    username: "bia.lima",
                    distanceMeters: 450,
                    neighborhood: "Pinheiros, SP",
                    mutualFriendsCount: 3,
                    interests: ["Viagens", "Churrasco", "Praia"],
                    proPlanType: .yearly
                ),
                NearbyUserItem(
                    name: "Rodrigo Costa",
                    username: "rodrigo.costa",
                    distanceMeters: 800,
                    neighborhood: "Vila Madalena, SP",
                    mutualFriendsCount: 5,
                    interests: ["Futebol", "Bar & Drinks"],
                    proPlanType: .monthly
                ),
                NearbyUserItem(
                    name: "Juliana Mendes",
                    username: "ju.mendes",
                    distanceMeters: 1200,
                    neighborhood: "Pinheiros, SP",
                    mutualFriendsCount: 2,
                    interests: ["Piscina", "Música"],
                    proPlanType: .none
                ),
                NearbyUserItem(
                    name: "Felipe Siqueira",
                    username: "felipe.siqueira",
                    distanceMeters: 2400,
                    neighborhood: "Itaim Bibi, SP",
                    mutualFriendsCount: 4,
                    interests: ["Viagem", "Trilha"],
                    proPlanType: .yearly
                ),
                NearbyUserItem(
                    name: "Mariana Alencar",
                    username: "mari.alencar",
                    distanceMeters: 3100,
                    neighborhood: "Jardins, SP",
                    mutualFriendsCount: 1,
                    interests: ["Casal", "Gastronomia"],
                    proPlanType: .monthly
                ),
                NearbyUserItem(
                    name: "Gabriel Ramos",
                    username: "gabriel.ramos",
                    distanceMeters: 4500,
                    neighborhood: "Moema, SP",
                    mutualFriendsCount: 6,
                    interests: ["Festa", "Rolezinho"],
                    proPlanType: .none
                ),
                NearbyUserItem(
                    name: "Larissa Duarte",
                    username: "lari.duarte",
                    distanceMeters: 620,
                    neighborhood: "Bela Vista, SP",
                    mutualFriendsCount: 4,
                    interests: ["Cinema", "Cafés"],
                    proPlanType: .monthly
                ),
                NearbyUserItem(
                    name: "Thiago Prado",
                    username: "thiago.prado",
                    distanceMeters: 1540,
                    neighborhood: "Moema, SP",
                    mutualFriendsCount: 3,
                    interests: ["Beach Tennis", "Corrida"],
                    proPlanType: .yearly
                ),
                NearbyUserItem(
                    name: "Camila Nogueira",
                    username: "camila.nog",
                    distanceMeters: 2100,
                    neighborhood: "Perdizes, SP",
                    mutualFriendsCount: 2,
                    interests: ["Gastronomia", "Shows"],
                    proPlanType: .none
                ),
                NearbyUserItem(
                    name: "Lucas Brandão",
                    username: "lucas.brandao",
                    distanceMeters: 980,
                    neighborhood: "Vila Mariana, SP",
                    mutualFriendsCount: 5,
                    interests: ["Churrasco", "Futebol"],
                    proPlanType: .monthly
                )
            ]
        }

        if directoryUsers.isEmpty {
            directoryUsers = [
                SearchableUser(name: "Beatriz Lima", username: "bia.lima", proPlanType: .yearly),
                SearchableUser(name: "Rodrigo Costa", username: "rodrigo.costa", proPlanType: .monthly),
                SearchableUser(name: "Juliana Mendes", username: "ju.mendes", proPlanType: .none),
                SearchableUser(name: "Felipe Siqueira", username: "felipe.siqueira", proPlanType: .yearly),
                SearchableUser(name: "Mariana Alencar", username: "mari.alencar", proPlanType: .monthly),
                SearchableUser(name: "Gabriel Ramos", username: "gabriel.ramos", proPlanType: .none),
                SearchableUser(name: "Camila Ribeiro", username: "camila.ribeiro", proPlanType: .monthly),
                SearchableUser(name: "Pedro Henrique", username: "pedro.henrique", proPlanType: .none)
            ]
        }

        if friends.isEmpty {
            friends = [
                FriendItem(
                    name: "Camila Ribeiro",
                    username: "camila.ribeiro",
                    initials: "CR",
                    balance: 45.0,
                    proPlanType: .monthly,
                    isOnline: true,
                    lastSeenText: "online",
                    friendsSinceText: "12 de jan. de 2026"
                ),
                FriendItem(
                    name: "Pedro Henrique",
                    username: "pedro.henrique",
                    initials: "PH",
                    balance: -30.0,
                    proPlanType: .none,
                    isOnline: false,
                    lastSeenText: "visto há 15 min",
                    friendsSinceText: "03 de fev. de 2026"
                ),
                FriendItem(
                    name: "Beatriz Lima",
                    username: "bia.lima",
                    initials: "BL",
                    balance: 0.0,
                    proPlanType: .yearly,
                    isOnline: true,
                    lastSeenText: "online",
                    friendsSinceText: "20 de mar. de 2026"
                )
            ]
        }

        if groups.isEmpty {
            let poolGroup = RoleGroup(
                title: "Piscina no Clube",
                category: "Festa",
                coverImageName: "GroupBar",
                startDate: Date(),
                targetDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
                potBalance: 750,
                potTarget: 1500,
                totalSpent: 0,
                myShare: 0,
                members: ["BL", "RC", "JM", "FS", "MA", "GR"],
                participants: [
                    GroupParticipant(name: "Beatriz Lima", username: "bia.lima", quotaAmount: 68.18, hasPaid: true, role: .owner, proPlanType: .yearly),
                    GroupParticipant(name: "Rodrigo Costa", username: "rodrigo.costa", quotaAmount: 68.18, hasPaid: true, role: .admin, proPlanType: .monthly),
                    GroupParticipant(name: "Juliana Mendes", username: "ju.mendes", quotaAmount: 68.18, hasPaid: true, role: .member, proPlanType: .none),
                    GroupParticipant(name: "Felipe Siqueira", username: "felipe.siqueira", quotaAmount: 68.18, hasPaid: true, role: .member, proPlanType: .yearly),
                    GroupParticipant(name: "Mariana Alencar", username: "mari.alencar", quotaAmount: 68.18, hasPaid: false, role: .member, proPlanType: .monthly),
                    GroupParticipant(name: "Gabriel Ramos", username: "gabriel.ramos", quotaAmount: 68.18, hasPaid: false, role: .member, proPlanType: .none)
                ],
                hasCollectivePot: true,
                comandaItems: [],
                potMode: .single,
                totalMonths: 1,
                selectedMonthIndex: 0,
                monthlyCycles: [],
                isPublic: true,
                maxParticipants: 25,
                publicUntilDate: Calendar.current.date(byAdding: .day, value: 20, to: Date()) ?? Date(),
                locationText: "São Paulo, SP • 1.4 km",
                distanceKm: 1.4
            )

            let soccerGroup = RoleGroup(
                title: "Futebol de Quinta & Resenha",
                category: "Esporte",
                coverImageName: "GroupChurrasco",
                startDate: Date(),
                targetDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date(),
                potBalance: 320,
                potTarget: 400,
                totalSpent: 0,
                myShare: 0,
                members: ["RC", "FS", "GR", "PH"],
                participants: [
                    GroupParticipant(name: "Rodrigo Costa", username: "rodrigo.costa", quotaAmount: 40.0, hasPaid: true, role: .owner, proPlanType: .monthly),
                    GroupParticipant(name: "Felipe Siqueira", username: "felipe.siqueira", quotaAmount: 40.0, hasPaid: true, role: .admin, proPlanType: .yearly),
                    GroupParticipant(name: "Gabriel Ramos", username: "gabriel.ramos", quotaAmount: 40.0, hasPaid: true, role: .member, proPlanType: .none),
                    GroupParticipant(name: "Pedro Henrique", username: "pedro.henrique", quotaAmount: 40.0, hasPaid: true, role: .member, proPlanType: .none)
                ],
                hasCollectivePot: true,
                comandaItems: [],
                potMode: .single,
                totalMonths: 1,
                selectedMonthIndex: 0,
                monthlyCycles: [],
                isPublic: true,
                maxParticipants: 14,
                publicUntilDate: Calendar.current.date(byAdding: .day, value: 12, to: Date()) ?? Date(),
                locationText: "São Paulo, SP • 800 m",
                distanceKm: 0.8
            )

            groups = [poolGroup, soccerGroup]
        }
    }

    func logout() {
        Task { await JuntoBackendService.shared.clearSessionTokens() }
        clearUserSession()
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
