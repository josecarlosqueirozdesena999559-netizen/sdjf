import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var draftText: String = ""
    @Published var isSending: Bool = false
    @Published var isViewOnce: Bool = false
    @Published var isEphemeralOnExit: Bool = false
    @Published var editingMessage: ChatMessage?

    private let chatService: ChatServiceProtocol

    init(chatService: ChatServiceProtocol) {
        self.chatService = chatService
    }

    func sendMessage(in conversationId: UUID, appState: AppState) async {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }

        if let editing = editingMessage {
            draftText = ""
            editingMessage = nil
            appState.socketClient.editMessage(
                messageId: editing.id.uuidString.lowercased(),
                content: trimmed
            )
            return
        }

        isSending = true
        draftText = ""
        let viewOnce = isViewOnce
        let ephemeral = isEphemeralOnExit
        isViewOnce = false

        if viewOnce && !appState.isPremium {
            let used = UserDefaults.standard.integer(forKey: "free_view_once_used_count")
            UserDefaults.standard.set(used + 1, forKey: "free_view_once_used_count")
        }

        let clientMessageId = UUID().uuidString
        appState.socketClient.sendMessage(
            conversationId: conversationId.uuidString.lowercased(),
            content: trimmed,
            type: "TEXT",
            isViewOnce: viewOnce,
            isEphemeralOnExit: ephemeral,
            clientMessageId: clientMessageId
        )

        let optimistic = ChatMessage(
            id: UUID(),
            senderIsCurrentUser: true,
            text: trimmed,
            sentAt: Date(),
            type: .text,
            isViewOnce: viewOnce,
            isEphemeralOnExit: ephemeral
        )
        if let index = appState.conversations.firstIndex(where: { $0.id == conversationId }) {
            appState.conversations[index].messages.append(optimistic)
            appState.conversations[index].unreadCount = 0
        }

        isSending = false
    }
}
