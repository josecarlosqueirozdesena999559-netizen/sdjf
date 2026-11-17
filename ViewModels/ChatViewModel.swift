import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var draftText: String = ""
    @Published var isSending: Bool = false

    private let chatService: ChatServiceProtocol

    init(chatService: ChatServiceProtocol) {
        self.chatService = chatService
    }

    func sendMessage(in conversationId: UUID, appState: AppState) async {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }

        isSending = true
        draftText = ""

        let clientMessageId = UUID().uuidString
        appState.socketClient.sendMessage(
            conversationId: conversationId.uuidString.lowercased(),
            content: trimmed,
            clientMessageId: clientMessageId
        )

        do {
            let message = try await chatService.sendMessage(text: trimmed, conversationId: conversationId)
            if let index = appState.conversations.firstIndex(where: { $0.id == conversationId }) {
                appState.conversations[index].messages.append(message)
                appState.conversations[index].unreadCount = 0
            }
        } catch {
            draftText = trimmed
        }

        isSending = false
    }
}
