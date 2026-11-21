import SwiftUI
import AVFoundation
import PhotosUI

struct ConversationsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var activeConversation: Conversation?

    var body: some View {
        Group {
            if appState.conversations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(AppTheme.Colors.textGray)
                    Text("Nenhuma conversa ainda")
                        .font(AppTheme.Typography.headline())
                        .foregroundStyle(AppTheme.Colors.darkGray)
                    Text("Quando der match ou enviar mensagem, suas conversas aparecerão aqui.")
                        .font(AppTheme.Typography.subheadline())
                        .foregroundStyle(AppTheme.Colors.textGray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24)
            } else {
                List {
                    ForEach(appState.conversations) { conversation in
                        Button {
                            activeConversation = conversation
                        } label: {
                            HStack(spacing: 14) {
                                if let firstPhoto = conversation.profile.photos.first {
                                    PhotoContentView(photo: firstPhoto)
                                        .frame(width: 56, height: 56)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(AppTheme.Colors.primaryRed.opacity(0.14))
                                        .frame(width: 56, height: 56)
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
                                    Text("\(conversation.unreadCount)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(AppTheme.Colors.primaryRed, in: Capsule())
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(AppTheme.Colors.white)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task {
                                    await deleteConversationFromList(conversation)
                                }
                            } label: {
                                Label("Excluir", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(AppTheme.Colors.background)
            }
        }
        .onAppear {
            openPendingIfNeeded()
        }
        .onChange(of: appState.pendingOpenConversationId) { _, _ in
            openPendingIfNeeded()
        }
        .fullScreenCover(item: $activeConversation) { conversation in
            ChatDetailView(conversationId: conversation.id, chatService: appState.services.chatService)
        }
    }

    private func openPendingIfNeeded() {
        guard let pendingId = appState.pendingOpenConversationId else { return }
        if let found = appState.conversations.first(where: { $0.id == pendingId }) {
            activeConversation = found
            appState.pendingOpenConversationId = nil
        }
    }

    private func deleteConversationFromList(_ conversation: Conversation) async {
        let idStr = conversation.id.uuidString.lowercased()
        try? await APIClient.shared.requestVoid(path: "/matches/\(idStr)", method: "DELETE")
        withAnimation {
            appState.conversations.removeAll { $0.id == conversation.id }
            appState.matches.removeAll { $0.id == conversation.id }
        }
    }
}

struct ChatDetailView: View {
    let conversationId: UUID
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ChatViewModel
    @StateObject private var audioRecorder = AudioRecorderHelper()
    @StateObject private var playbackManager = AudioPlaybackManager()
    @Environment(\.dismiss) private var dismiss

    @State private var screenShieldEnabled: Bool = true
    @State private var showPaywall: Bool = false
    @State private var showReportSheet: Bool = false
    @State private var showBlockAlert: Bool = false
    @State private var showDeleteConvAlert: Bool = false
    @State private var revealedViewOnceText: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var previewImageURL: URL?
    @State private var previewImageData: Data?
    @State private var freeSafeModeEndsAt: Date?
    @State private var safeModeRemainingSeconds: Int = 0
    @State private var dragUpOffset: CGFloat = 0

    private let safeModeTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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
            return "digitando..."
        }
        if let partner = conversation?.profile {
            let userKey = partner.id.uuidString.lowercased()
            let isOnline = appState.onlineUsers[userKey] ?? partner.isOnline
            if isOnline {
                return "online"
            }
            if let lastSeen = appState.lastActiveByUser[userKey] ?? partner.lastActiveAt {
                let calendar = Calendar.current
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                let timeStr = timeFormatter.string(from: lastSeen)
                if calendar.isDateInToday(lastSeen) {
                    return "visto por último hoje às \(timeStr)"
                } else if calendar.isDateInYesterday(lastSeen) {
                    return "visto por último ontem às \(timeStr)"
                } else {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd/MM"
                    return "visto por último em \(dateFormatter.string(from: lastSeen)) às \(timeStr)"
                }
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
                            if appState.isPremium {
                                Text("Modo Temporário ativo • Mensagens lidas somem ao sair")
                                    .font(AppTheme.Typography.micro())
                            } else {
                                let mins = safeModeRemainingSeconds / 60
                                let secs = safeModeRemainingSeconds % 60
                                Text(String(format: "Modo Seguro (5 min grátis) • %02d:%02d", mins, secs))
                                    .font(AppTheme.Typography.micro())
                            }
                        }
                        .foregroundStyle(Color(hex: "00A884"))
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "00A884").opacity(0.1))
                    }

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 2) {
                                if let messages = conversation?.messages, !messages.isEmpty {
                                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                                        let showDateSeparator = index == 0 || !Calendar.current.isDate(messages[index - 1].sentAt, inSameDayAs: message.sentAt)
                                        if showDateSeparator {
                                            ChatDateSeparator(date: message.sentAt)
                                        }

                                        WhatsAppMessageBubble(
                                            message: message,
                                            playbackManager: playbackManager,
                                            onConsumeViewOnce: {
                                                Task { await consumeViewOnce(message) }
                                            },
                                            onImageTap: { url, data in
                                                previewImageURL = url
                                                previewImageData = data
                                            }
                                        )
                                        .id(message.id)
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
                                    }
                                } else {
                                    VStack(spacing: 8) {
                                        Image(systemName: "hand.wave")
                                            .font(.system(size: 36))
                                            .foregroundStyle(Color(hex: "8696A0"))
                                            .padding(.top, 40)
                                        Text("Diga olá para \(conversation?.profile.firstName ?? "seu match")!")
                                            .font(AppTheme.Typography.subheadline())
                                            .foregroundStyle(Color(hex: "667781"))
                                    }
                                    .frame(maxWidth: .infinity)
                                }

                                Text(viewModel.isEphemeralOnExit
                                     ? "Arraste para cima para voltar ao modo normal"
                                     : "Arraste para cima para ativar o Modo Seguro")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "8696A0"))
                                    .padding(.top, 14)
                                    .id("bottom_anchor")
                            }
                            .padding(.vertical, 8)
                        }
                        .background(Color(hex: "EFEAE2"))
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 35)
                                .onChanged { value in
                                    if value.translation.height < 0 {
                                        dragUpOffset = value.translation.height
                                    }
                                }
                                .onEnded { value in
                                    if value.translation.height < -70 || dragUpOffset < -70 {
                                        toggleSafeModeByGesture()
                                    }
                                    dragUpOffset = 0
                                }
                        )
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if let lastId = conversation?.messages.last?.id {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: conversation?.messages.count) { _, _ in
                            if let lastId = conversation?.messages.last?.id {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }

                    if let editing = viewModel.editingMessage {
                        HStack {
                            Text("Editando: \(editing.text)")
                                .font(AppTheme.Typography.caption())
                                .foregroundStyle(Color(hex: "667781"))
                                .lineLimit(1)
                            Spacer()
                            Button("Cancelar") {
                                viewModel.editingMessage = nil
                                viewModel.draftText = ""
                            }
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(Color(hex: "00A884"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.white)
                    }

                    inputBar
                }
                .background(Color(hex: "EFEAE2"))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 8) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color(hex: "00A884"))
                        }

                        if let firstPhoto = conversation?.profile.photos.first {
                            PhotoContentView(photo: firstPhoto)
                                .frame(width: 38, height: 38)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(hex: "00A884").opacity(0.15))
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Text(String((conversation?.profile.firstName ?? "?").prefix(1)).uppercased())
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(Color(hex: "00A884"))
                                )
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 4) {
                                Text(conversation?.profile.firstName ?? "Conversa")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color(hex: "111B21"))
                                if conversation?.profile.isVerified == true {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(hex: "3B82F6"))
                                }
                            }

                            if !partnerStatusText.isEmpty {
                                Text(partnerStatusText)
                                    .font(.system(size: 11.5, weight: .regular))
                                    .foregroundStyle(
                                        partnerStatusText == "digitando..." || partnerStatusText == "online"
                                        ? Color(hex: "25D366")
                                        : Color(hex: "667781")
                                    )
                            }
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
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

                        Divider()

                        Button {
                            showReportSheet = true
                        } label: {
                            Label("Denunciar usuário", systemImage: "exclamationmark.triangle")
                        }

                        Button(role: .destructive) {
                            showBlockAlert = true
                        } label: {
                            Label("Bloquear usuário", systemImage: "hand.raised")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(hex: "00A884"))
                    }
                }
            }
            .onAppear {
                let idStr = conversationId.uuidString.lowercased()
                appState.socketClient.joinChat(conversationId: idStr)
                appState.socketClient.markRead(conversationId: idStr)
                Task {
                    await viewModel.loadMessagesIfNeeded(for: conversationId, appState: appState)
                }
            }
            .onDisappear {
                let idStr = conversationId.uuidString.lowercased()
                appState.socketClient.sendTyping(conversationId: idStr, isTyping: false)
                appState.socketClient.leaveChat(conversationId: idStr)
                playbackManager.stop()
                if viewModel.isEphemeralOnExit {
                    Task {
                        try? await APIClient.shared.requestVoid(
                            path: "/conversations/\(idStr)/purge-ephemeral",
                            method: "POST"
                        )
                        await appState.loadSocialData()
                    }
                }
            }
            .onReceive(safeModeTimer) { _ in
                guard viewModel.isEphemeralOnExit, !appState.isPremium, let endsAt = freeSafeModeEndsAt else { return }
                let rem = Int(endsAt.timeIntervalSinceNow)
                if rem <= 0 {
                    viewModel.isEphemeralOnExit = false
                    freeSafeModeEndsAt = nil
                    safeModeRemainingSeconds = 0
                } else {
                    safeModeRemainingSeconds = rem
                }
            }
            .sheet(isPresented: $showPaywall) {
                PremiumPaywallSheet()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showReportSheet) {
                if let partner = conversation?.profile {
                    ReportUserSheet(
                        targetUserId: partner.id.uuidString.lowercased(),
                        targetName: partner.firstName
                    ) {
                        removeCurrentConversationAndDismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { previewImageURL != nil || previewImageData != nil },
                set: { if !$0 { previewImageURL = nil; previewImageData = nil } }
            )) {
                FullScreenImageViewer(imageURL: previewImageURL, imageData: previewImageData) {
                    previewImageURL = nil
                    previewImageData = nil
                }
            }
            .alert("Excluir conversa?", isPresented: $showDeleteConvAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Excluir", role: .destructive) {
                    Task { await deleteConversation() }
                }
            } message: {
                Text("Esta conversa será removida da sua lista.")
            }
            .alert("Bloquear \(conversation?.profile.firstName ?? "usuário")?", isPresented: $showBlockAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Bloquear", role: .destructive) {
                    Task { await blockPartner() }
                }
            } message: {
                Text("Você não verá mais este perfil e ele não poderá enviar mensagens. Você pode desbloquear em Segurança.")
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

    private var inputBar: some View {
        HStack(spacing: 8) {
            if audioRecorder.isRecording {
                Button {
                    audioRecorder.cancelRecording()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 19))
                        .foregroundStyle(Color(hex: "EA4335"))
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancelar gravação")

                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: "EA4335"))
                        .frame(width: 8, height: 8)

                    Text(String(format: "%d:%02d", audioRecorder.elapsedSeconds / 60, audioRecorder.elapsedSeconds % 60))
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(hex: "111B21"))

                    HStack(spacing: 2.5) {
                        ForEach(Array(audioRecorder.levels.enumerated()), id: \.offset) { _, level in
                            Capsule()
                                .fill(Color(hex: "00A884"))
                                .frame(width: 2.5, height: max(4, level * 26))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .animation(.linear(duration: 0.08), value: audioRecorder.levels)
                }
                .padding(.horizontal, 14)
                .frame(height: 42)
                .background(Color.white, in: Capsule())
                .shadow(color: Color.black.opacity(0.06), radius: 2, y: 1)

                Button {
                    toggleViewOnce()
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(viewModel.isViewOnce ? Color(hex: "00A884") : Color(hex: "8696A0"), lineWidth: 1.5)
                            .frame(width: 26, height: 26)
                        Text("1")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(viewModel.isViewOnce ? Color(hex: "00A884") : Color(hex: "8696A0"))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Áudio de visualização única")

                Button {
                    Task { await finishAndSendAudio() }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color(hex: "00A884"), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Enviar áudio")
            } else {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: "00A884"))
                        .frame(width: 36, height: 36)
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    guard let newItem else { return }
                    Task {
                        await sendSelectedPhoto(newItem)
                        selectedPhotoItem = nil
                    }
                }

                Button {
                    toggleViewOnce()
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(viewModel.isViewOnce ? Color(hex: "00A884") : Color(hex: "8696A0"), lineWidth: 1.5)
                            .frame(width: 24, height: 24)
                        Text("1")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(viewModel.isViewOnce ? Color(hex: "00A884") : Color(hex: "8696A0"))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Visualização única")

                TextField("Mensagem", text: $viewModel.draftText)
                    .font(.system(size: 16))
                    .padding(.horizontal, 14)
                    .frame(height: 42)
                    .background(Color.white, in: Capsule())
                    .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                    .onChange(of: viewModel.draftText) { _, newValue in
                        appState.socketClient.sendTyping(
                            conversationId: conversationId.uuidString.lowercased(),
                            isTyping: !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }

                if viewModel.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        audioRecorder.startRecording()
                    } label: {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(Color(hex: "00A884"), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Gravar áudio")
                } else {
                    Button {
                        Task {
                            await viewModel.sendMessage(in: conversationId, appState: appState)
                        }
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(Color(hex: "00A884"), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Enviar mensagem")
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(hex: "F0F2F5"))
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
            playbackManager.togglePlay(messageId: message.id, url: url)
        } else if message.type == .image, let url = URL(string: res.revealedContent) {
            previewImageURL = url
        } else {
            revealedViewOnceText = res.revealedContent
        }
    }

    private func toggleViewOnce() {
        if appState.isPremium {
            viewModel.isViewOnce.toggle()
            return
        }
        let used = UserDefaults.standard.integer(forKey: "free_view_once_used_count")
        if used < 1 {
            viewModel.isViewOnce.toggle()
        } else {
            showPaywall = true
        }
    }

    private func toggleSafeModeByGesture() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.easeInOut(duration: 0.25)) {
            if viewModel.isEphemeralOnExit {
                viewModel.isEphemeralOnExit = false
                freeSafeModeEndsAt = nil
                safeModeRemainingSeconds = 0
            } else {
                viewModel.isEphemeralOnExit = true
                if !appState.isPremium {
                    freeSafeModeEndsAt = Date().addingTimeInterval(300)
                    safeModeRemainingSeconds = 300
                }
            }
        }
    }

    private func finishAndSendAudio() async {
        guard let audioData = audioRecorder.stopRecording(),
              let localURL = audioRecorder.fileURL else { return }

        let viewOnce = viewModel.isViewOnce
        viewModel.isViewOnce = false
        if viewOnce && !appState.isPremium {
            let used = UserDefaults.standard.integer(forKey: "free_view_once_used_count")
            UserDefaults.standard.set(used + 1, forKey: "free_view_once_used_count")
        }

        let tempId = UUID()
        let optimisticAudio = ChatMessage(
            id: tempId,
            senderIsCurrentUser: true,
            text: localURL.absoluteString,
            sentAt: Date(),
            type: .audio,
            isViewOnce: viewOnce,
            isEphemeralOnExit: viewModel.isEphemeralOnExit,
            isDelivered: false,
            isRead: false
        )
        if let idx = appState.conversations.firstIndex(where: { $0.id == conversationId }) {
            appState.conversations[idx].messages.append(optimisticAudio)
            appState.conversations[idx].unreadCount = 0
        }

        struct AudioUploadResponse: Decodable {
            let url: String
        }
        guard let uploaded: AudioUploadResponse = try? await APIClient.shared.uploadJPEG(
            path: "/messages/audio-upload",
            imageData: audioData,
            filename: "voice.m4a"
        ) else { return }

        let clientMessageId = tempId.uuidString.lowercased()
        appState.socketClient.sendMessage(
            conversationId: conversationId.uuidString.lowercased(),
            content: uploaded.url,
            type: "AUDIO",
            isViewOnce: viewOnce,
            isEphemeralOnExit: viewModel.isEphemeralOnExit,
            clientMessageId: clientMessageId
        )
    }

    private func sendSelectedPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }

        let viewOnce = viewModel.isViewOnce
        viewModel.isViewOnce = false
        if viewOnce && !appState.isPremium {
            let used = UserDefaults.standard.integer(forKey: "free_view_once_used_count")
            UserDefaults.standard.set(used + 1, forKey: "free_view_once_used_count")
        }

        let tempId = UUID()
        let optimisticPhoto = ChatMessage(
            id: tempId,
            senderIsCurrentUser: true,
            text: "",
            sentAt: Date(),
            type: .image,
            isViewOnce: viewOnce,
            isEphemeralOnExit: viewModel.isEphemeralOnExit,
            isDelivered: false,
            isRead: false,
            localImageData: data
        )
        if let idx = appState.conversations.firstIndex(where: { $0.id == conversationId }) {
            appState.conversations[idx].messages.append(optimisticPhoto)
            appState.conversations[idx].unreadCount = 0
        }

        struct PhotoUploadResp: Decodable {
            struct PhotoObj: Decodable { let url: String }
            let photo: PhotoObj?
            let url: String?
        }
        guard let uploaded: PhotoUploadResp = try? await APIClient.shared.uploadJPEG(
            path: "/photos/upload",
            imageData: data,
            filename: "chat_photo.jpg"
        ) else { return }

        let urlStr = uploaded.photo?.url ?? uploaded.url ?? ""
        guard !urlStr.isEmpty else { return }

        if let idx = appState.conversations.firstIndex(where: { $0.id == conversationId }),
           let mIdx = appState.conversations[idx].messages.firstIndex(where: { $0.id == tempId }) {
            appState.conversations[idx].messages[mIdx].text = urlStr
        }

        let clientMessageId = tempId.uuidString.lowercased()
        appState.socketClient.sendMessage(
            conversationId: conversationId.uuidString.lowercased(),
            content: urlStr,
            type: "IMAGE",
            isViewOnce: viewOnce,
            isEphemeralOnExit: viewModel.isEphemeralOnExit,
            clientMessageId: clientMessageId
        )
    }

    private func deleteConversation() async {
        let idStr = conversationId.uuidString.lowercased()
        try? await APIClient.shared.requestVoid(path: "/matches/\(idStr)", method: "DELETE")
        removeCurrentConversationAndDismiss()
    }

    private func blockPartner() async {
        guard let partnerId = conversation?.profile.id.uuidString.lowercased() else { return }
        try? await APIClient.shared.requestVoid(path: "/users/\(partnerId)/block", method: "POST")
        removeCurrentConversationAndDismiss()
    }

    private func removeCurrentConversationAndDismiss() {
        appState.conversations.removeAll { $0.id == conversationId }
        appState.matches.removeAll { $0.id == conversationId }
        dismiss()
    }
}

// MARK: - WhatsApp UI Components

struct MessageStatusCheckmarks: View {
    let isDelivered: Bool
    let isRead: Bool

    var body: some View {
        HStack(spacing: -3.5) {
            Image(systemName: "checkmark")
                .font(.system(size: 9.5, weight: .bold))
            if isDelivered || isRead {
                Image(systemName: "checkmark")
                    .font(.system(size: 9.5, weight: .bold))
            }
        }
        .foregroundStyle(isRead ? Color(hex: "53BDEB") : Color(hex: "8696A0"))
    }
}

struct ChatDateSeparator: View {
    let date: Date

    var dateText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "HOJE"
        } else if calendar.isDateInYesterday(date) {
            return "ONTEM"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter.string(from: date)
        }
    }

    var body: some View {
        Text(dateText)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color(hex: "54656F"))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.85), in: Capsule())
            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
            .padding(.vertical, 6)
    }
}

struct WhatsAppAudioBubble: View {
    let message: ChatMessage
    @ObservedObject var playbackManager: AudioPlaybackManager
    let onConsumeViewOnce: () -> Void

    var isCurrentAudioPlaying: Bool {
        playbackManager.playingMessageId == message.id && playbackManager.isPlaying
    }

    var progress: Double {
        if playbackManager.playingMessageId == message.id {
            return playbackManager.progress
        }
        return 0.0
    }

    var timeLabel: String {
        if playbackManager.playingMessageId == message.id && playbackManager.totalDuration > 0 {
            let rem = Int(playbackManager.currentTime)
            return String(format: "%d:%02d", rem / 60, rem % 60)
        }
        return "0:15"
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                if message.isViewOnce && !message.senderIsCurrentUser && message.viewedAt == nil {
                    onConsumeViewOnce()
                } else if let url = URL(string: message.text) {
                    playbackManager.togglePlay(messageId: message.id, url: url)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(message.senderIsCurrentUser ? Color(hex: "00A884") : AppTheme.Colors.primaryRed)
                        .frame(width: 40, height: 40)

                    Image(systemName: isCurrentAudioPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: isCurrentAudioPlaying ? 0 : 1.5)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: "8696A0").opacity(0.35))
                            .frame(height: 4)

                        Capsule()
                            .fill(message.senderIsCurrentUser ? Color(hex: "00A884") : AppTheme.Colors.primaryRed)
                            .frame(width: max(4, geo.size.width * CGFloat(progress)), height: 4)
                    }
                    .frame(height: 4)
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                .frame(height: 14)

                HStack {
                    Text(timeLabel)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color(hex: "667781"))

                    Spacer()

                    if playbackManager.playingMessageId == message.id {
                        Button {
                            playbackManager.toggleSpeed()
                        } label: {
                            Text(String(format: "%.1fx", playbackManager.playbackRate).replacingOccurrences(of: ".0x", with: "x"))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color(hex: "111B21"))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color(hex: "E9EDEF"), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    Image(systemName: "mic.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(message.senderIsCurrentUser ? Color(hex: "53BDEB") : Color(hex: "8696A0"))
                }
            }
            .frame(minWidth: 160, maxWidth: 200)
        }
        .padding(.vertical, 4)
    }
}

struct WhatsAppMessageBubble: View {
    let message: ChatMessage
    @ObservedObject var playbackManager: AudioPlaybackManager
    let onConsumeViewOnce: () -> Void
    let onImageTap: (URL?, Data?) -> Void

    var isCurrentUser: Bool {
        message.senderIsCurrentUser
    }

    var bubbleBgColor: Color {
        if message.deletedForEveryoneAt != nil {
            return Color(hex: "E9EDEF")
        }
        return isCurrentUser ? Color(hex: "E7FFDB") : Color.white
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: message.sentAt)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if isCurrentUser { Spacer(minLength: 44) }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 3) {
                if message.deletedForEveryoneAt != nil {
                    HStack(spacing: 6) {
                        Image(systemName: "circle.slash")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "8696A0"))
                        Text("Esta mensagem foi apagada")
                            .font(.system(size: 14.5, weight: .regular))
                            .italic()
                            .foregroundStyle(Color(hex: "8696A0"))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                } else if message.isViewOnce && !isCurrentUser && message.viewedAt == nil {
                    Button {
                        onConsumeViewOnce()
                    } label: {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .strokeBorder(Color(hex: "00A884"), lineWidth: 1.5)
                                    .frame(width: 28, height: 28)
                                Text("1")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color(hex: "00A884"))
                            }
                            Text(message.type == .audio ? "Mensagem de voz (1x)" : "Foto de visualização única")
                                .font(.system(size: 14.5, weight: .medium))
                                .foregroundStyle(Color(hex: "111B21"))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                } else if message.type == .audio {
                    VStack(alignment: .trailing, spacing: 2) {
                        if message.isViewOnce {
                            HStack(spacing: 4) {
                                Image(systemName: "1.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "00A884"))
                                Text("Visualização única")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color(hex: "00A884"))
                            }
                            .padding(.top, 4)
                            .padding(.horizontal, 8)
                        }

                        WhatsAppAudioBubble(
                            message: message,
                            playbackManager: playbackManager,
                            onConsumeViewOnce: onConsumeViewOnce
                        )
                        .padding(.horizontal, 8)
                        .padding(.top, 4)

                        HStack(spacing: 4) {
                            Text(timeString)
                                .font(.system(size: 10.5))
                                .foregroundStyle(Color(hex: "667781"))

                            if isCurrentUser {
                                MessageStatusCheckmarks(
                                    isDelivered: message.isDelivered,
                                    isRead: message.isRead
                                )
                            }
                        }
                        .padding(.trailing, 8)
                        .padding(.bottom, 4)
                    }
                } else if message.type == .image {
                    VStack(alignment: .trailing, spacing: 0) {
                        Button {
                            onImageTap(URL(string: message.text), message.localImageData)
                        } label: {
                            if let localData = message.localImageData, let uiImg = UIImage(data: localData) {
                                Image(uiImage: uiImg)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: 240, maxHeight: 280)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            } else if let imgUrl = URL(string: message.text) {
                                AsyncImage(url: imgUrl) { phase in
                                    if case .success(let img) = phase {
                                        img
                                            .resizable()
                                            .scaledToFill()
                                            .frame(maxWidth: 240, maxHeight: 280)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    } else {
                                        ZStack {
                                            Color.gray.opacity(0.15)
                                            ProgressView()
                                        }
                                        .frame(width: 220, height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(4)

                        HStack(spacing: 4) {
                            if message.isViewOnce {
                                Image(systemName: "1.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color(hex: "00A884"))
                            }
                            Text(timeString)
                                .font(.system(size: 10.5))
                                .foregroundStyle(Color(hex: "667781"))

                            if isCurrentUser {
                                MessageStatusCheckmarks(
                                    isDelivered: message.isDelivered,
                                    isRead: message.isRead
                                )
                            }
                        }
                        .padding(.trailing, 8)
                        .padding(.bottom, 4)
                    }
                } else {
                    HStack(alignment: .bottom, spacing: 8) {
                        Text(message.text)
                            .font(.system(size: 15.5, weight: .regular))
                            .foregroundStyle(Color(hex: "111B21"))
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 3) {
                            if message.editedAt != nil {
                                Text("editada")
                                    .font(.system(size: 9.5))
                                    .foregroundStyle(Color(hex: "667781"))
                            }

                            Text(timeString)
                                .font(.system(size: 10.5))
                                .foregroundStyle(Color(hex: "667781"))

                            if isCurrentUser {
                                MessageStatusCheckmarks(
                                    isDelivered: message.isDelivered,
                                    isRead: message.isRead
                                )
                            }
                        }
                        .offset(y: 2)
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                }
            }
            .background(bubbleBgColor)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 14,
                    bottomLeadingRadius: isCurrentUser ? 14 : 3,
                    bottomTrailingRadius: isCurrentUser ? 3 : 14,
                    topTrailingRadius: 14,
                    style: .continuous
                )
            )
            .shadow(color: Color.black.opacity(0.06), radius: 1.5, x: 0, y: 1)

            if !isCurrentUser { Spacer(minLength: 44) }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2.5)
    }
}

struct FullScreenImageViewer: View {
    let imageURL: URL?
    let imageData: Data?
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFit()
                    } else {
                        ProgressView()
                            .tint(.white)
                    }
                }
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

@MainActor
final class AudioPlaybackManager: NSObject, ObservableObject {
    @Published var playingMessageId: UUID?
    @Published var isPlaying: Bool = false
    @Published var progress: Double = 0.0
    @Published var currentTime: TimeInterval = 0
    @Published var totalDuration: TimeInterval = 0
    @Published var playbackRate: Float = 1.0

    private var player: AVPlayer?
    private var timeObserverToken: Any?

    func togglePlay(messageId: UUID, url: URL) {
        if playingMessageId == messageId {
            if isPlaying {
                player?.pause()
                isPlaying = false
            } else {
                player?.rate = playbackRate
                player?.play()
                isPlaying = true
            }
            return
        }

        stop()

        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        self.player = newPlayer
        self.playingMessageId = messageId
        self.playbackRate = 1.0
        self.progress = 0
        self.currentTime = 0

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )

        let interval = CMTime(seconds: 0.05, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self, let currentItem = self.player?.currentItem else { return }
            let current = time.seconds
            let duration = currentItem.duration.seconds
            if duration > 0 && !duration.isNaN {
                self.currentTime = current
                self.totalDuration = duration
                self.progress = min(1.0, max(0.0, current / duration))
            }
        }

        newPlayer.rate = playbackRate
        newPlayer.play()
        isPlaying = true
    }

    func toggleSpeed() {
        if playbackRate == 1.0 {
            playbackRate = 1.5
        } else if playbackRate == 1.5 {
            playbackRate = 2.0
        } else {
            playbackRate = 1.0
        }
        if isPlaying {
            player?.rate = playbackRate
        }
    }

    func stop() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        player?.pause()
        player = nil
        playingMessageId = nil
        isPlaying = false
        progress = 0
        currentTime = 0
        totalDuration = 0
    }

    @objc private func playerItemDidReachEnd() {
        player?.seek(to: .zero)
        isPlaying = false
        progress = 0
        currentTime = 0
    }

    deinit {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
        }
        NotificationCenter.default.removeObserver(self)
        player?.pause()
    }
}

@MainActor
private final class AudioRecorderHelper: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var levels: [CGFloat] = Array(repeating: 0.15, count: 24)
    @Published var elapsedSeconds: Int = 0

    private var recorder: AVAudioRecorder?
    private(set) var fileURL: URL?
    private var meterTask: Task<Void, Never>?
    private var startedAt: Date?

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
        recorder?.isMeteringEnabled = true
        recorder?.record()
        fileURL = url
        startedAt = Date()
        elapsedSeconds = 0
        levels = Array(repeating: 0.15, count: 24)
        isRecording = true

        meterTask?.cancel()
        meterTask = Task { [weak self] in
            while let self, self.isRecording, !Task.isCancelled {
                self.recorder?.updateMeters()
                let power = self.recorder?.averagePower(forChannel: 0) ?? -60
                // Normalize -55 dB ... 0 dB into 0.12 ... 1.0
                let clamped = max(-55, min(0, power))
                let normalized = CGFloat((clamped + 55) / 55)
                let barValue = max(0.12, pow(normalized, 1.4))

                self.levels.removeFirst()
                self.levels.append(barValue)
                if let start = self.startedAt {
                    self.elapsedSeconds = Int(Date().timeIntervalSince(start))
                }
                try? await Task.sleep(for: .milliseconds(80))
            }
        }
    }

    func stopRecording() -> Data? {
        meterTask?.cancel()
        meterTask = nil
        recorder?.stop()
        isRecording = false
        guard let url = fileURL else { return nil }
        return try? Data(contentsOf: url)
    }

    func cancelRecording() {
        meterTask?.cancel()
        meterTask = nil
        recorder?.stop()
        isRecording = false
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
        }
        fileURL = nil
        elapsedSeconds = 0
    }
}
