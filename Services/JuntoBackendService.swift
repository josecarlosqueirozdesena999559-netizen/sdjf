import Foundation

/// Cliente HTTP + SSE Real que sincroniza o aplicativo iOS Juntô com o banco PostgreSQL + Redis no Docker via Cloudflare Tunnel HTTPS
actor JuntoBackendService {
    static let shared = JuntoBackendService()
    static let defaultProductionTunnelURL = "https://brings-extent-personals-desktops.trycloudflare.com"

    private static let accessTokenKey = "junto_access_token"
    private static let refreshTokenKey = "junto_refresh_token"

    private var baseURL: String {
        return JuntoBackendService.defaultProductionTunnelURL
    }

    private var accessToken: String? {
        get {
            if let kc = KeychainHelper.read(forKey: Self.accessTokenKey), !kc.isEmpty {
                return kc
            }
            // Migração única de token legado do UserDefaults para o Keychain criptografado
            if let legacy = UserDefaults.standard.string(forKey: Self.accessTokenKey), !legacy.isEmpty {
                KeychainHelper.save(legacy, forKey: Self.accessTokenKey)
                UserDefaults.standard.removeObject(forKey: Self.accessTokenKey)
                return legacy
            }
            return nil
        }
        set {
            UserDefaults.standard.removeObject(forKey: Self.accessTokenKey)
            if let token = newValue, !token.isEmpty {
                KeychainHelper.save(token, forKey: Self.accessTokenKey)
            } else {
                KeychainHelper.delete(forKey: Self.accessTokenKey)
            }
        }
    }

    private var refreshToken: String? {
        get { KeychainHelper.read(forKey: Self.refreshTokenKey) }
        set {
            if let token = newValue, !token.isEmpty {
                KeychainHelper.save(token, forKey: Self.refreshTokenKey)
            } else {
                KeychainHelper.delete(forKey: Self.refreshTokenKey)
            }
        }
    }

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 25.0
        return URLSession(configuration: config)
    }()

    private var sseTask: Task<Void, Never>? = nil

    func setAccessToken(_ token: String?) {
        accessToken = token
    }

    func setTokens(access: String?, refresh: String?) {
        accessToken = access
        refreshToken = refresh
    }

    func clearSessionTokens() {
        accessToken = nil
        refreshToken = nil
        sseTask?.cancel()
        sseTask = nil
    }

    func currentBaseURL() -> String {
        baseURL
    }

    // MARK: - Helper Genérico REST com renovação automática de JWT
    private func request(
        path: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        allowRetryOnUnauthorized: Bool = true,
        allowErrorBody: Bool = false
    ) async -> [String: Any]? {
        guard let url = URL(string: "\(baseURL)\(path)") else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else { return nil }

            if http.statusCode == 401 && allowRetryOnUnauthorized, await refreshAccessToken() {
                return await request(path: path, method: method, body: body, allowRetryOnUnauthorized: false, allowErrorBody: allowErrorBody)
            }

            if !(200...299).contains(http.statusCode) {
                if allowErrorBody {
                    return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
                }
                return nil
            }
            return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        } catch {
            return nil
        }
    }

    private func refreshAccessToken() async -> Bool {
        guard let rt = refreshToken, !rt.isEmpty,
              let url = URL(string: "\(baseURL)/v1/auth/refresh") else { return false }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["refreshToken": rt])

        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
                  let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let newAccess = json["accessToken"] as? String else {
                return false
            }
            accessToken = newAccess
            if let newRefresh = json["refreshToken"] as? String {
                refreshToken = newRefresh
            }
            return true
        } catch {
            return false
        }
    }

    // MARK: - Stream em Tempo Real (SSE nativo via HTTPS)
    func startRealtimeStream(onEvent: @escaping @Sendable (String, String) -> Void) {
        sseTask?.cancel()
        guard let token = accessToken, !token.isEmpty else { return }
        let streamURLString = "\(baseURL)/v1/realtime/events"

        sseTask = Task.detached(priority: .utility) {
            while !Task.isCancelled {
                guard let url = URL(string: streamURLString) else { break }
                var req = URLRequest(url: url)
                req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                req.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                req.timeoutInterval = 300

                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: req)
                    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                        continue
                    }

                    var currentEvent = "message"
                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        if line.hasPrefix("event:") {
                            currentEvent = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
                        } else if line.hasPrefix("data:") {
                            let rawJson = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                            onEvent(currentEvent, rawJson)
                            currentEvent = "message"
                        }
                    }
                } catch {
                    if Task.isCancelled { break }
                }

                try? await Task.sleep(nanoseconds: 4_000_000_000)
            }
        }
    }

    func stopRealtimeStream() {
        sseTask?.cancel()
        sseTask = nil
    }

    // MARK: - 1. Validação Instantânea de @username no Redis/PostgreSQL
    func checkUsernameAvailability(_ username: String) async -> Bool? {
        let clean = username.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "")
        guard let encoded = clean.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let res = await request(path: "/v1/auth/check-username/\(encoded)", allowRetryOnUnauthorized: false) else {
            return nil
        }
        return res["available"] as? Bool
    }

    // MARK: - 2. Login Real no PostgreSQL
    func login(identifier: String, password: String) async -> [String: Any]? {
        guard !password.isEmpty else { return nil }
        let res = await request(
            path: "/v1/auth/login",
            method: "POST",
            body: [
                "identifier": identifier,
                "password": password,
                "deviceName": "iPhone iOS"
            ],
            allowRetryOnUnauthorized: false
        )
        if let token = res?["accessToken"] as? String {
            accessToken = token
        }
        if let rt = res?["refreshToken"] as? String {
            refreshToken = rt
        }
        return res
    }

    // MARK: - 3. Cadastro Real no PostgreSQL (Criptografia AES-256-GCM + Argon2id)
    func register(
        email: String,
        username: String,
        password: String,
        fullName: String,
        phone: String,
        pixKey: String
    ) async -> [String: Any]? {
        guard password.count >= 6, phone.filter({ $0.isNumber }).count >= 10 else { return nil }
        let res = await request(
            path: "/v1/auth/register",
            method: "POST",
            body: [
                "email": email,
                "username": username,
                "password": password,
                "fullName": fullName,
                "countryCode": "+55",
                "phone": phone,
                "pixKey": pixKey,
                "lgpdAccepted": true,
                "deviceName": "iPhone iOS"
            ],
            allowRetryOnUnauthorized: false
        )
        if let token = res?["accessToken"] as? String {
            accessToken = token
        }
        if let rt = res?["refreshToken"] as? String {
            refreshToken = rt
        }
        return res
    }

    // MARK: - 4. Login / Cadastro Exclusivo via WhatsApp OTP no Redis/PostgreSQL
    func checkPhoneRegistered(phone: String) async -> (ok: Bool, exists: Bool, errorMessage: String?) {
        let digitsOnly = phone.filter { $0.isNumber }
        guard digitsOnly.count >= 10 else { return (false, false, "Número inválido.") }
        let res = await request(
            path: "/v1/auth/check-phone",
            method: "POST",
            body: ["phone": digitsOnly],
            allowRetryOnUnauthorized: false,
            allowErrorBody: true
        )
        let ok = (res?["ok"] as? Bool) ?? false
        let exists = (res?["exists"] as? Bool) ?? false
        let err = res?["error"] as? String
        return (ok, exists, err)
    }

    func requestWhatsAppOTP(phone: String, mode: String? = nil) async -> (ok: Bool, isExistingUser: Bool, errorMessage: String?) {
        let digitsOnly = phone.filter { $0.isNumber }
        guard digitsOnly.count >= 10 else { return (false, false, "Número inválido.") }
        var body: [String: Any] = [
            "phone": digitsOnly,
            "template": "junto_codigo_verificacao"
        ]
        if let mode {
            body["mode"] = mode
        }
        let res = await request(
            path: "/v1/auth/whatsapp/send-otp",
            method: "POST",
            body: body,
            allowRetryOnUnauthorized: false,
            allowErrorBody: true
        )
        let ok = (res?["ok"] as? Bool) ?? false
        let existing = (res?["isExistingUser"] as? Bool) ?? false
        let err = res?["error"] as? String
        return (ok, existing, err)
    }

    func loginWithWhatsAppOTP(
        phone: String,
        code: String,
        fullName: String? = nil,
        pixKey: String? = nil
    ) async -> [String: Any]? {
        let digitsOnly = phone.filter { $0.isNumber }
        guard digitsOnly.count >= 10 else { return nil }
        var body: [String: Any] = [
            "phone": digitsOnly,
            "code": code.trimmingCharacters(in: .whitespacesAndNewlines),
            "deviceName": "iPhone iOS"
        ]
        if let name = fullName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            body["fullName"] = name
        }
        if let pix = pixKey?.trimmingCharacters(in: .whitespacesAndNewlines), !pix.isEmpty {
            body["pixKey"] = pix
        }

        let res = await request(
            path: "/v1/auth/whatsapp/login-otp",
            method: "POST",
            body: body,
            allowRetryOnUnauthorized: false
        )
        if let token = res?["accessToken"] as? String {
            accessToken = token
        }
        if let rt = res?["refreshToken"] as? String {
            refreshToken = rt
        }
        return res
    }

    func sendWhatsAppVerificationCode(phone: String, code: String) async -> Bool {
        let digitsOnly = phone.filter { $0.isNumber }
        guard digitsOnly.count >= 10 else { return false }
        let res = await request(
            path: "/v1/auth/whatsapp/send-otp",
            method: "POST",
            body: [
                "phone": digitsOnly,
                "code": code,
                "template": "junto_codigo_verificacao"
            ],
            allowRetryOnUnauthorized: false
        )
        return (res?["ok"] as? Bool) ?? false
    }

    func verifyWhatsAppCode(phone: String, code: String) async -> Bool {
        let digitsOnly = phone.filter { $0.isNumber }
        let res = await request(
            path: "/v1/auth/whatsapp/verify-otp",
            method: "POST",
            body: ["phone": digitsOnly, "code": code],
            allowRetryOnUnauthorized: false
        )
        return (res?["ok"] as? Bool) ?? false
    }

    func requestPasswordReset(identifier: String, code: String) async -> Bool {
        let res = await request(
            path: "/v1/auth/forgot-password",
            method: "POST",
            body: ["identifier": identifier, "code": code],
            allowRetryOnUnauthorized: false
        )
        return (res?["ok"] as? Bool) ?? false
    }

    func confirmPasswordReset(identifier: String, code: String, newPassword: String) async -> Bool {
        let res = await request(
            path: "/v1/auth/reset-password",
            method: "POST",
            body: [
                "identifier": identifier,
                "code": code,
                "newPassword": newPassword
            ],
            allowRetryOnUnauthorized: false
        )
        return (res?["ok"] as? Bool) ?? false
    }

    // MARK: - 5. Conta, Perfil, APNs Push Token & Exclusão Definitiva (LGPD / Apple Review)
    func updateProfile(fullName: String? = nil, email: String? = nil, phone: String? = nil, pixKey: String? = nil) async -> Bool {
        var body: [String: Any] = [:]
        if let v = fullName, !v.isEmpty { body["fullName"] = v }
        if let v = email, !v.isEmpty { body["email"] = v }
        if let v = phone, !v.isEmpty { body["phone"] = v }
        if let v = pixKey, !v.isEmpty { body["pixKey"] = v }
        guard !body.isEmpty else { return false }
        let res = await request(path: "/v1/account/me", method: "PATCH", body: body)
        return res != nil
    }

    func deleteAccount(reason: String = "Solicitado pelo usuário no app iOS") async -> Bool {
        let res = await request(
            path: "/v1/account",
            method: "DELETE",
            body: ["reason": reason]
        )
        clearSessionTokens()
        return (res?["ok"] as? Bool) ?? false
    }

    func registerDeviceToken(_ token: String) async {
        guard !token.isEmpty else { return }
        _ = await request(
            path: "/v1/account/device-token",
            method: "POST",
            body: ["token": token, "platform": "ios"]
        )
    }

    func submitSupportTicket(
        protocolCode: String,
        name: String,
        email: String,
        subject: String,
        message: String
    ) async -> Bool {
        let res = await request(
            path: "/v1/support/contact",
            method: "POST",
            body: [
                "protocolCode": protocolCode,
                "name": name,
                "email": email,
                "subject": subject,
                "message": message
            ]
        )
        return (res?["ok"] as? Bool) ?? false
    }

    // MARK: - 6. Sincronização Completa (Bootstrap) do Banco PostgreSQL
    func fetchBootstrap(username: String) async -> [String: Any]? {
        let encoded = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? username
        return await request(path: "/v1/sync/bootstrap?username=\(encoded)")
    }

    // MARK: - 7. Contatos Estilo WhatsApp & Busca Real no PostgreSQL
    func addOrOpenContact(name: String, phone: String) async -> [String: Any]? {
        return await request(
            path: "/v1/friends/contacts/add",
            method: "POST",
            body: [
                "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
                "phone": phone.trimmingCharacters(in: .whitespacesAndNewlines)
            ]
        )
    }

    func syncDeviceContacts(_ contacts: [[String: String]]) async -> [[String: Any]] {
        guard let res = await request(
            path: "/v1/friends/contacts/sync",
            method: "POST",
            body: ["contacts": contacts]
        ), let matched = res["matched"] as? [[String: Any]] else {
            return []
        }
        return matched
    }

    func searchUsers(query: String) async -> [[String: Any]] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let res = await request(path: "/v1/friends/search?q=\(encoded)"),
              let list = res["users"] as? [[String: Any]] else {
            return []
        }
        return list
    }

    func inviteFriend(username: String) async -> Bool {
        let res = await request(path: "/v1/friends/invite", method: "POST", body: ["username": username])
        return (res?["ok"] as? Bool) ?? false
    }

    func acceptFriend(username: String) async -> Bool {
        let res = await request(path: "/v1/friends/accept", method: "POST", body: ["username": username])
        return (res?["ok"] as? Bool) ?? false
    }

    func removeFriend(username: String) async -> Bool {
        let encoded = username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? username
        let res = await request(path: "/v1/friends/\(encoded)", method: "DELETE")
        return (res?["ok"] as? Bool) ?? false
    }

    // MARK: - 8. Grupos, Membros & Pagamentos no PostgreSQL
    func createGroupOnServer(
        title: String,
        category: String,
        coverImage: String = "GroupChurrasco",
        potTarget: Double,
        potMode: String = "SINGLE",
        totalMonths: Int = 1,
        monthlyCycles: [[String: Any]] = [],
        startDate: Date = Date(),
        targetDate: Date? = nil,
        memberUsernames: [String] = []
    ) async -> String? {
        let iso = ISO8601DateFormatter()
        var body: [String: Any] = [
            "title": title,
            "category": category,
            "coverImage": coverImage,
            "hasCollectivePot": true,
            "potTargetCents": Int(round(potTarget * 100)),
            "potMode": potMode,
            "totalMonths": totalMonths,
            "monthlyCyclesJson": monthlyCycles,
            "startDate": iso.string(from: startDate),
            "memberUsernames": memberUsernames
        ]
        if let td = targetDate {
            body["targetDate"] = iso.string(from: td)
        }
        let res = await request(path: "/v1/groups", method: "POST", body: body)
        if let grp = res?["group"] as? [String: Any], let id = grp["id"] as? String {
            return id
        }
        return nil
    }

    func deleteGroupOnServer(groupId: String) async {
        _ = await request(path: "/v1/groups/\(groupId)", method: "DELETE")
    }

    func addGroupMember(groupId: String, username: String) async {
        _ = await request(path: "/v1/groups/\(groupId)/members", method: "POST", body: ["username": username])
    }

    func removeGroupMember(groupId: String, username: String) async {
        let encoded = username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? username
        _ = await request(path: "/v1/groups/\(groupId)/members/\(encoded)", method: "DELETE")
    }

    func updateGroupMemberRole(groupId: String, username: String, isAdmin: Bool) async {
        let encoded = username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? username
        _ = await request(
            path: "/v1/groups/\(groupId)/members/\(encoded)/role",
            method: "PATCH",
            body: ["role": isAdmin ? "ADMIN" : "MEMBER"]
        )
    }

    func markGroupPayment(groupId: String, amount: Double, monthIndex: Int? = nil, kind: String = "QUOTA") async {
        var body: [String: Any] = [
            "amountCents": Int(round(amount * 100)),
            "kind": kind
        ]
        if let m = monthIndex { body["monthIndex"] = m }
        _ = await request(path: "/v1/groups/\(groupId)/payments/mark", method: "POST", body: body)
    }

    func confirmGroupPayment(groupId: String, username: String, monthIndex: Int? = nil) async {
        var body: [String: Any] = ["username": username]
        if let m = monthIndex { body["monthIndex"] = m }
        _ = await request(path: "/v1/groups/\(groupId)/payments/confirm", method: "POST", body: body)
    }

    /// Salva configurações Juntô Pro e controles do grupo no PostgreSQL
    func updateGroupProSettings(
        groupId: String,
        aiReminderEnabled: Bool,
        aiReminderDaysBefore: Int,
        aiReminderTone: String,
        pixQuickPinEnabled: Bool,
        restrictExpensesToAdmins: Bool,
        autoClosureSummaryEnabled: Bool
    ) async {
        let body: [String: Any] = [
            "aiReminderEnabled": aiReminderEnabled,
            "aiReminderDaysBefore": aiReminderDaysBefore,
            "aiReminderTone": aiReminderTone,
            "pixQuickPinEnabled": pixQuickPinEnabled,
            "restrictExpensesToAdmins": restrictExpensesToAdmins,
            "autoClosureSummaryEnabled": autoClosureSummaryEnabled
        ]
        _ = await request(path: "/v1/groups/\(groupId)/pro-settings", method: "PATCH", body: body)
    }

    /// Dispara imediatamente o Agente Juntô IA no servidor para avisar os pendentes do grupo
    func triggerGroupAIReminder(groupId: String) async -> String? {
        let res = await request(path: "/v1/groups/\(groupId)/ai-remind", method: "POST", body: [:])
        return res?["message"] as? String
    }

    // MARK: - 9. Chat & Mídia Persistente (Volume Docker + PostgreSQL)
    func uploadMedia(data: Data, filename: String, mimeType: String) async -> String? {
        let res = await request(
            path: "/v1/media/upload",
            method: "POST",
            body: [
                "dataBase64": data.base64EncodedString(),
                "filename": filename,
                "mimeType": mimeType
            ]
        )
        return res?["url"] as? String
    }

    func downloadMedia(pathOrURL: String) async -> Data? {
        let fullStr = pathOrURL.hasPrefix("http") ? pathOrURL : "\(baseURL)\(pathOrURL)"
        guard let url = URL(string: fullStr) else { return nil }
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }
            return data
        } catch {
            return nil
        }
    }

    func sendFriendMessage(
        to username: String,
        kind: String,
        content: String,
        mediaUrl: String? = nil,
        audioDurationSec: Int? = nil,
        waveform: [Double]? = nil,
        pollJson: [String: Any]? = nil,
        replyToAuthor: String? = nil,
        replyToPreview: String? = nil
    ) async -> String? {
        let encoded = username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? username
        var body: [String: Any] = ["kind": kind, "content": content]
        if let m = mediaUrl { body["mediaUrl"] = m }
        if let d = audioDurationSec { body["audioDurationSec"] = d }
        if let w = waveform { body["waveform"] = w }
        if let p = pollJson { body["pollJson"] = p }
        if let ra = replyToAuthor { body["replyToAuthor"] = ra }
        if let rp = replyToPreview { body["replyToPreview"] = rp }
        let res = await request(path: "/v1/chats/friend/\(encoded)", method: "POST", body: body)
        return (res?["message"] as? [String: Any])?["id"] as? String
    }

    func sendGroupMessage(
        groupId: String,
        kind: String,
        content: String,
        mediaUrl: String? = nil,
        audioDurationSec: Int? = nil,
        waveform: [Double]? = nil,
        pollJson: [String: Any]? = nil,
        replyToAuthor: String? = nil,
        replyToPreview: String? = nil
    ) async -> String? {
        var body: [String: Any] = ["kind": kind, "content": content]
        if let m = mediaUrl { body["mediaUrl"] = m }
        if let d = audioDurationSec { body["audioDurationSec"] = d }
        if let w = waveform { body["waveform"] = w }
        if let p = pollJson { body["pollJson"] = p }
        if let ra = replyToAuthor { body["replyToAuthor"] = ra }
        if let rp = replyToPreview { body["replyToPreview"] = rp }
        let res = await request(path: "/v1/chats/group/\(groupId)", method: "POST", body: body)
        return (res?["message"] as? [String: Any])?["id"] as? String
    }

    func editChatMessage(messageId: String, newText: String) async {
        _ = await request(path: "/v1/chats/messages/\(messageId)", method: "PATCH", body: ["content": newText])
    }

    func markMessageListened(messageId: String) async {
        _ = await request(path: "/v1/chats/messages/\(messageId)", method: "PATCH", body: ["isListened": true])
    }

    func updatePollMessage(messageId: String, pollJson: [String: Any]) async {
        _ = await request(path: "/v1/chats/messages/\(messageId)", method: "PATCH", body: ["pollJson": pollJson])
    }

    func deleteChatMessage(messageId: String) async {
        _ = await request(path: "/v1/chats/messages/\(messageId)", method: "DELETE")
    }

    func clearFriendConversation(username: String) async {
        let encoded = username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? username
        _ = await request(path: "/v1/chats/friend/\(encoded)", method: "DELETE")
    }

    // MARK: - 10. Assinatura Juntô Pro (StoreKit 2), Caixinhas, Despesas e Notificações
    func syncProStatus(username: String, isPro: Bool, planName: String?, planType: ProPlanType = .none) async {
        var body: [String: Any] = [
            "username": username,
            "isPro": isPro,
            "planType": planType.rawValue
        ]
        if let p = planName { body["planName"] = p }
        _ = await request(path: "/v1/sync/pro", method: "POST", body: body)
    }

    func verifyAppleSubscription(username: String, productId: String, transactionId: String, expiresAtISO: String?) async {
        var body: [String: Any] = [
            "username": username,
            "productId": productId,
            "transactionId": transactionId
        ]
        if let exp = expiresAtISO { body["expiresAt"] = exp }
        _ = await request(path: "/v1/sync/pro/verify-apple", method: "POST", body: body)
    }

    func createPersonalPot(
        username: String,
        title: String,
        occasion: String,
        icon: String,
        targetAmount: Double,
        targetDateText: String
    ) async {
        _ = await request(
            path: "/v1/sync/personal-pots",
            method: "POST",
            body: [
                "username": username,
                "title": title,
                "occasion": occasion,
                "icon": icon,
                "targetAmountCents": Int(round(targetAmount * 100)),
                "targetDateText": targetDateText
            ]
        )
    }

    func createPersonalExpense(
        username: String,
        title: String,
        category: String,
        amount: Double,
        dateText: String,
        monthKey: String,
        groupName: String
    ) async -> String? {
        let res = await request(
            path: "/v1/sync/personal-expenses",
            method: "POST",
            body: [
                "username": username,
                "title": title,
                "category": category,
                "amountCents": Int(round(amount * 100)),
                "dateText": dateText,
                "monthKey": monthKey,
                "groupName": groupName
            ]
        )
        return (res?["expense"] as? [String: Any])?["id"] as? String
    }

    func togglePersonalExpensePaid(expenseId: String) async {
        _ = await request(path: "/v1/sync/personal-expenses/\(expenseId)/toggle", method: "PATCH")
    }

    func markAllNotificationsReadOnServer() async {
        _ = await request(path: "/v1/sync/notifications/read-all", method: "POST")
    }
}
