import SwiftUI
import AVFoundation

struct ConversationsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var activeConversation: Conversation?

    var body: some View {
        ScrollView {
            if appState.conversations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(AppTheme.Colors.textGray)
                    Text("Nenhuma conversa ainda")
                        .font(AppTheme.Typography.headline())
                        .foregroundStyle(AppTheme.Colors.darkGray)
                    Text("Quando der match, você poderá iniciar uma conversa aqui.")
                        .font(AppTheme.Typography.subheadline())
                        .foregroundStyle(AppTheme.Colors.textGray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 80)
                .padding(.horizontal, 24)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(appState.conversations) { conversation in
                        Button {
                            activeConversation = conversation
                        } label: {
                            HStack(spacing: 14) {
                                if let firstPhoto = conversation.profile.photos.first {
                                    PhotoContentView(photo: firstPhoto)
                                        .frame(width: 58, height: 58)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(AppTheme.Colors.primaryRed.opacity(0.14))
                                        .frame(width: 58, height: 58)
                                        .overlay(
                                            Text(String(conversation.profile.firstName.prefix(1)).uppercased())
                                                .font(AppTheme.Typography.headline())
                                                .foregroundStyle(AppTheme.Colors.primaryRed)
                                        )
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(conversation.profile.firstName)
                                            .font(AppTheme.Typography.headline())
                                            .foregroundStyle(AppTheme.Colors.darkGray)

                                        if conversation.profile.isVerified {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.system(size: 13))
                                                .foregroundStyle(Color(hex: "3B82F6"))
                                        }
                                    }

                                    Text(conversation.lastMessage?.text ?? "Diga olá para \(conversation.profile.firstName)!")
                                        .font(AppTheme.Typography.subheadline())
                                        .foregroundStyle(AppTheme.Colors.textGray)
                                        .lineLimit(1)
                                }

                                Spacer()

                                if conversation.unreadCount > 0 {
                                    Circle()
                                        .fill(AppTheme.Colors.primaryRed)
                                        .frame(width: 10, height: 10)
                                }
                            }
                            .padding(14)
                            .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                                    .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .sheet(item: $activeConversation) { conversation in
            ChatDetailView(conversationId: conversation.id, chatService: appState.services.chatService)
        }
    }
}

struct ChatDetailView: View {
    let conversationId: UUID
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ChatViewModel
    @StateObject private var audioRecorder = AudioRecorderHelper()
    @Environment(\.dismiss) private var dismiss

    @State private var screenShieldEnabled: Bool = true
    @State private var showPaywall: Bool = false
    @State private var revealedViewOnceText: String?
    @State private var audioPlayer: AVPlayer?

    init(conversationId: UUID, chatService: ChatServiceProtocol) {
        self.conversationId = conversationId
        _viewModel = StateObject(wrappedValue: ChatViewModel(chatService: chatService))
    }

    private var conversation: Conversation? {
        appState.conversations.first { $0.id == conversationId }
    }

    private var partnerStatusText: String {
        let convKey = conversationId.uuidString.lowercased()
        if appState.typingConversations.contains(convKey) {
            return "Digitando..."
        }
        if let partner = conversation?.profile {
            let userKey = partner.id.uuidString.lowercased()
            let isOnline = appState.onlineUsers[userKey] ?? partner.isOnline
            if isOnline {
                return "Online"
            }
            if let lastSeen = appState.lastActiveByUser[userKey] {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                return "Visto por último às \(formatter.string(from: lastSeen))"
            }
        }
        return ""
    }

    var body: some View {
        NavigationStack {
            SecureScreenShield(isEnabled: screenShieldEnabled || appState.isPremium) {
                VStack(spacing: 0) {
                    if viewModel.isEphemeralOnExit {
                        HStack(spacing: 6) {
                            Image(systemName: "timer")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Modo temporário ativo: mensagens lidas somem ao sair")
                                .font(AppTheme.Typography.micro())
                        }
                        .foregroundStyle(AppTheme.Colors.primaryRed)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.Colors.primaryRed.opacity(0.08))
                    }

                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if let messages = conversation?.messages, !messages.isEmpty {
                                ForEach(messages) { message in
                                    messageBubble(message)
                                }
                            } else {
                                Text("Envie a primeira mensagem!")
                                    .font(AppTheme.Typography.subheadline())
                                    .foregroundStyle(AppTheme.Colors.textGray)
                                    .padding(.top, 48)
                            }
                        }
                        .padding(16)
                    }

                    if let editing = viewModel.editingMessage {
                        HStack {
                            Text("Editando: \(editing.text)")
                                .font(AppTheme.Typography.caption())
                                .foregroundStyle(AppTheme.Colors.textGray)
                                .lineLimit(1)
                            Spacer()
                            Button("Cancelar") {
                                viewModel.editingMessage = nil
                                viewModel.draftText = ""
                            }
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(AppTheme.Colors.primaryRed)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(AppTheme.Colors.white)
                    }

                    inputBar
                }
                .background(AppTheme.Colors.background)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text(conversation?.profile.firstName ?? "Conversa")
                            .font(AppTheme.Typography.headline())
                            .foregroundStyle(AppTheme.Colors.darkGray)
                        if !partnerStatusText.isEmpty {
                            Text(partnerStatusText)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(
                                    partnerStatusText == "Online" || partnerStatusText == "Digitando..."
                                        ? AppTheme.Colors.primaryRed
                                        : AppTheme.Colors.textGray
                                )
                        }
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            requirePremium {
                                viewModel.isEphemeralOnExit.toggle()
                            }
                        } label: {
                            Label(
                                viewModel.isEphemeralOnExit ? "Desativar modo temporário" : "Modo temporário (apagar ao sair)",
                                systemImage: "timer"
                            )
                        }

                        Button {
                            screenShieldEnabled.toggle()
                        } label: {
                            Label(
                                screenShieldEnabled ? "Proteção anti-print ativa" : "Ativar proteção anti-print",
                                systemImage: "eye.slash"
                            )
                        }

                        Divider()

                        Button(role: .destructive) {
                            requirePremium {
                                appState.socketClient.clearChat(conversationId: conversationId.uuidString.lowercased())
                            }
                        } label: {
                            Label("Limpar conversa para todos", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 17))
                            .foregroundStyle(AppTheme.Colors.darkGray)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.Colors.darkGray)
                            .frame(width: 30, height: 30)
                            .background(AppTheme.Colors.chipUnselected, in: Circle())
                    }
                }
            }
            .onAppear {
                appState.socketClient.markRead(conversationId: conversationId.uuidString.lowercased())
            }
            .onDisappear {
                appState.socketClient.sendTyping(conversationId: conversationId.uuidString.lowercased(), isTyping: false)
                appState.socketClient.leaveChat(conversationId: conversationId.uuidString.lowercased())
            }
            .sheet(isPresented: $showPaywall) {
                PremiumPaywallSheet()
                    .environmentObject(appState)
            }
            .alert("Visualização única", isPresented: Binding(
                get: { revealedViewOnceText != nil },
                set: { if !$0 { revealedViewOnceText = nil } }
            )) {
                Button("Fechar", role: .cancel) { revealedViewOnceText = nil }
            } message: {
                Text(revealedViewOnceText ?? "")
            }
        }
    }

    @ViewBuilder
    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.senderIsCurrentUser { Spacer(minLength: 48) }

            Group {
                if message.isViewOnce && !message.senderIsCurrentUser && message.viewedAt == nil {
                    Button {
                        Task { await consumeViewOnce(message) }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: message.type == .audio ? "waveform.circle.fill" : "1.circle.fill")
                                .font(.system(size: 18))
                            Text(message.type == .audio ? "Áudio único — tocar para ouvir" : "Mensagem única — tocar para abrir")
                                .font(AppTheme.Typography.subheadline())
                        }
                        .foregroundStyle(AppTheme.Colors.primaryRed)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(AppTheme.Colors.primaryRed.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    VStack(alignment: message.senderIsCurrentUser ? .trailing : .leading, spacing: 3) {
                        HStack(spacing: 5) {
                            if message.isViewOnce {
                                Image(systemName: "1.circle")
                                    .font(.system(size: 12))
                            }
                            if message.isEphemeralOnExit {
                                Image(systemName: "timer")
                                    .font(.system(size: 11))
                            }
                            Text(message.type == .audio && message.viewedAt == nil ? "Áudio de visualização única" : message.text)
                                .font(AppTheme.Typography.body())
                        }

                        if message.editedAt != nil && message.deletedForEveryoneAt == nil {
                            Text("Editada")
                                .font(.system(size: 10))
                                .opacity(0.75)
                        }
                    }
                    .foregroundStyle(message.senderIsCurrentUser ? .white : AppTheme.Colors.darkGray)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                message.deletedForEveryoneAt != nil
                                ? AppTheme.Colors.chipUnselected
                                : (message.senderIsCurrentUser ? AppTheme.Colors.primaryRed : AppTheme.Colors.white)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(message.senderIsCurrentUser ? .clear : AppTheme.Colors.borderSubtle, lineWidth: 1)
                    )
                }
            }
            .contextMenu {
                if message.senderIsCurrentUser && message.deletedForEveryoneAt == nil {
                    if message.type == .text && !message.isViewOnce {
                        Button {
                            requirePremium {
                                viewModel.editingMessage = message
                                viewModel.draftText = message.text
                            }
                        } label: {
                            Label("Editar mensagem", systemImage: "pencil")
                        }
                    }

                    Button(role: .destructive) {
                        requirePremium {
                            appState.socketClient.deleteMessage(messageId: message.id.uuidString.lowercased())
                        }
                    } label: {
                        Label("Excluir para todos", systemImage: "trash")
                    }
                }
            }

            if !message.senderIsCurrentUser { Spacer(minLength: 48) }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            Button {
                requirePremium {
                    viewModel.isViewOnce.toggle()
                }
            } label: {
                Image(systemName: viewModel.isViewOnce ? "1.circle.fill" : "1.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(viewModel.isViewOnce ? AppTheme.Colors.primaryRed : AppTheme.Colors.textGray)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Visualização única")

            TextField("Escreva uma mensagem...", text: $viewModel.draftText)
                .font(AppTheme.Typography.body())
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(AppTheme.Colors.white, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                )
                .onChange(of: viewModel.draftText) { _, newValue in
                    appState.socketClient.sendTyping(
                        conversationId: conversationId.uuidString.lowercased(),
                        isTyping: !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }

            if viewModel.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    requirePremium {
                        if audioRecorder.isRecording {
                            Task { await finishAndSendViewOnceAudio() }
                        } else {
                            audioRecorder.startRecording()
                        }
                    }
                } label: {
                    Image(systemName: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(audioRecorder.isRecording ? Color.black : AppTheme.Colors.primaryRed, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Gravar áudio único")
            } else {
                Button {
                    Task {
                        await viewModel.sendMessage(in: conversationId, appState: appState)
                    }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.Colors.primaryRed, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private func requirePremium(_ action: () -> Void) {
        if appState.isPremium {
            action()
        } else {
            showPaywall = true
        }
    }

    private func consumeViewOnce(_ message: ChatMessage) async {
        struct ConsumeResponse: Decodable {
            let revealedContent: String
        }
        guard let res: ConsumeResponse = try? await APIClient.shared.request(
            path: "/messages/\(message.id.uuidString.lowercased())/consume",
            method: "POST"
        ) else { return }

        if let cIdx = appState.conversations.firstIndex(where: { $0.id == conversationId }),
           let mIdx = appState.conversations[cIdx].messages.firstIndex(where: { $0.id == message.id }) {
            appState.conversations[cIdx].messages[mIdx].viewedAt = Date()
            appState.conversations[cIdx].messages[mIdx].text = "Visualização única aberta"
        }

        if message.type == .audio, let url = URL(string: res.revealedContent) {
            let player = AVPlayer(url: url)
            self.audioPlayer = player
            player.play()
        } else {
            revealedViewOnceText = res.revealedContent
        }
    }

    private func finishAndSendViewOnceAudio() async {
        guard let audioData = audioRecorder.stopRecording() else { return }
        struct AudioUploadResponse: Decodable {
            let url: String
        }
        guard let uploaded: AudioUploadResponse = try? await APIClient.shared.uploadJPEG(
            path: "/messages/audio-upload",
            imageData: audioData,
            filename: "voice.m4a"
        ) else { return }

        appState.socketClient.sendMessage(
            conversationId: conversationId.uuidString.lowercased(),
            content: uploaded.url,
            type: "AUDIO",
            isViewOnce: true,
            isEphemeralOnExit: viewModel.isEphemeralOnExit
        )
    }
}

@MainActor
private final class AudioRecorderHelper: NSObject, ObservableObject {
    @Published var isRecording = false
    private var recorder: AVAudioRecorder?
    private var fileURL: URL?

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default)
        try? session.setActive(true)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("voice_\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 22050,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        recorder = try? AVAudioRecorder(url: url, settings: settings)
        recorder?.record()
        fileURL = url
        isRecording = true
    }

    func stopRecording() -> Data? {
        recorder?.stop()
        isRecording = false
        guard let url = fileURL else { return nil }
        return try? Data(contentsOf: url)
    }
}
