import Foundation

/// Native Engine.IO v4 + Socket.IO v4 WebSocket client using URLSessionWebSocketTask.
/// Requires zero external Swift Package dependencies.
@MainActor
final class RealtimeSocketClient: ObservableObject {
    @Published private(set) var isConnected = false

    var onNewMessage: ((_ conversationId: String, _ messageId: String, _ senderId: String, _ content: String, _ type: String, _ isViewOnce: Bool, _ isEphemeralOnExit: Bool, _ createdAt: Date) -> Void)?
    var onMessageEdited: ((_ conversationId: String, _ messageId: String, _ content: String, _ editedAt: Date) -> Void)?
    var onMessageDeleted: ((_ conversationId: String, _ messageId: String) -> Void)?
    var onMessageConsumed: ((_ conversationId: String, _ messageId: String) -> Void)?
    var onChatCleared: ((_ conversationId: String) -> Void)?
    var onEphemeralPurged: ((_ conversationId: String, _ messageIds: [String]) -> Void)?
    var onNewMatch: ((_ matchId: String, _ conversationId: String?, _ partnerId: String) -> Void)?
    var onNewNotification: (() -> Void)?
    var onPresenceChanged: ((_ userId: String, _ isOnline: Bool, _ lastActiveAt: Date) -> Void)?
    var onTypingChanged: ((_ conversationId: String, _ userId: String, _ isTyping: Bool) -> Void)?

    private var webSocketTask: URLSessionWebSocketTask?
    private var shouldReconnect = false

    func connect() {
        guard let token = KeychainHelper.read(forKey: "access_token") else { return }
        shouldReconnect = true

        let task = URLSession.shared.webSocketTask(with: NetworkConfig.socketWebSocketURL)
        self.webSocketTask = task
        task.resume()

        // Send Socket.IO v4 connect packet with JWT auth payload after Engine.IO open
        listen(task: task, token: token)
    }

    func disconnect() {
        shouldReconnect = false
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }

    func sendMessage(
        conversationId: String,
        content: String,
        type: String = "TEXT",
        isViewOnce: Bool = false,
        isEphemeralOnExit: Bool = false,
        clientMessageId: String = UUID().uuidString
    ) {
        let payload: [String: Any] = [
            "conversationId": conversationId,
            "clientMessageId": clientMessageId,
            "type": type,
            "content": content,
            "isViewOnce": isViewOnce,
            "isEphemeralOnExit": isEphemeralOnExit
        ]
        emit(event: "message:send", data: payload)
    }

    func editMessage(messageId: String, content: String) {
        emit(event: "message:edit", data: ["messageId": messageId, "content": content])
    }

    func deleteMessage(messageId: String) {
        emit(event: "message:delete", data: ["messageId": messageId])
    }

    func clearChat(conversationId: String) {
        emit(event: "chat:clear", data: ["conversationId": conversationId])
    }

    func leaveChat(conversationId: String) {
        emit(event: "chat:leave", data: ["conversationId": conversationId])
    }

    func markRead(conversationId: String) {
        emit(event: "message:read", data: ["conversationId": conversationId])
    }

    func sendTyping(conversationId: String, isTyping: Bool) {
        emit(event: isTyping ? "typing:start" : "typing:stop", data: ["conversationId": conversationId])
    }

    private func emit(event: String, data: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: [event, data]),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        let packet = "42" + jsonString
        webSocketTask?.send(.string(packet)) { _ in }
    }

    private func listen(task: URLSessionWebSocketTask, token: String) {
        task.receive { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success(let message):
                    if case .string(let text) = message {
                        self.handlePacket(text, task: task, token: token)
                    }
                    self.listen(task: task, token: token)
                case .failure:
                    self.isConnected = false
                    if self.shouldReconnect {
                        try? await Task.sleep(for: .seconds(3))
                        if self.shouldReconnect {
                            self.connect()
                        }
                    }
                }
            }
        }
    }

    private func handlePacket(_ text: String, task: URLSessionWebSocketTask, token: String) {
        // Engine.IO Open ("0{...}") -> respond with Socket.IO v4 CONNECT ("40{\"token\":\"...\"}")
        if text.hasPrefix("0") {
            let authPacket = "40{\"token\":\"\(token)\"}"
            task.send(.string(authPacket)) { _ in }
            return
        }

        // Engine.IO Ping ("2") -> Pong ("3")
        if text == "2" {
            task.send(.string("3")) { _ in }
            return
        }

        // Socket.IO Connect Ack ("40{...}")
        if text.hasPrefix("40") {
            isConnected = true
            return
        }

        // Socket.IO Event ("42[...]")
        if text.hasPrefix("42") {
            let jsonPart = String(text.dropFirst(2))
            guard let data = jsonPart.data(using: .utf8),
                  let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
                  let eventName = array.first as? String,
                  let payload = array.dropFirst().first as? [String: Any] else {
                return
            }

            switch eventName {
            case "message:new":
                if let conversationId = payload["conversationId"] as? String,
                   let id = payload["id"] as? String,
                   let senderId = payload["senderId"] as? String,
                   let content = payload["content"] as? String {
                    let type = (payload["type"] as? String) ?? "TEXT"
                    let isViewOnce = (payload["isViewOnce"] as? Bool) ?? false
                    let isEphemeral = (payload["isEphemeralOnExit"] as? Bool) ?? false
                    let dateStr = payload["createdAt"] as? String
                    let date = dateStr.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
                    onNewMessage?(conversationId, id, senderId, content, type, isViewOnce, isEphemeral, date)
                }
            case "message:edited":
                if let conversationId = payload["conversationId"] as? String,
                   let id = payload["id"] as? String,
                   let content = payload["content"] as? String {
                    onMessageEdited?(conversationId, id, content, Date())
                }
            case "message:deleted":
                if let conversationId = payload["conversationId"] as? String,
                   let id = payload["id"] as? String {
                    onMessageDeleted?(conversationId, id)
                }
            case "message:consumed":
                if let conversationId = payload["conversationId"] as? String,
                   let id = payload["messageId"] as? String {
                    onMessageConsumed?(conversationId, id)
                }
            case "chat:cleared":
                if let conversationId = payload["conversationId"] as? String {
                    onChatCleared?(conversationId)
                }
            case "chat:ephemeral_purged":
                if let conversationId = payload["conversationId"] as? String,
                   let ids = payload["messageIds"] as? [String] {
                    onEphemeralPurged?(conversationId, ids)
                }
            case "match:new":
                if let matchId = payload["matchId"] as? String,
                   let partnerId = payload["partnerId"] as? String {
                    let conversationId = payload["conversationId"] as? String
                    onNewMatch?(matchId, conversationId, partnerId)
                }
            case "notification:new":
                onNewNotification?()
            case "user:online", "user:offline":
                if let userId = payload["userId"] as? String {
                    let isOnline = (eventName == "user:online")
                    let dateStr = payload["lastActiveAt"] as? String
                    let date = dateStr.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
                    onPresenceChanged?(userId, isOnline, date)
                }
            case "typing:start", "typing:stop":
                if let conversationId = payload["conversationId"] as? String,
                   let userId = payload["userId"] as? String {
                    onTypingChanged?(conversationId, userId, eventName == "typing:start")
                }
            default:
                break
            }
        }
    }
}
