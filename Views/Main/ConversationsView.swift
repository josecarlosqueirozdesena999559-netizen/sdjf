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
    @Environment(\.dismiss) private var dismiss

    @State private var screenShieldEnabled: Bool = true
    @State private var showPaywall: Bool = false
    @State private var showReportSheet: Bool = false
    @State private var showBlockAlert: Bool = false
    @State private var showDeleteConvAlert: Bool = false
    @State private var revealedViewOnceText: String?
    @State private var audioPlayer: AVPlayer?
    @State private var selectedPhotoItem: PhotosPickerItem?
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
            return "Digitando..."
        }
        if let partner = conversation?.profile {
            let userKey = partner.id.uuidString.lowercased()
            let isOnline = appState.onlineUsers[userKey] ?? partner.isOnline
            if isOnline {
                return "Online"
            }
            if let lastSeen = appState.lastActiveByUser[userKey] ?? partner.lastActiveAt {
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

                            Text(viewModel.isEphemeralOnExit
                                 ? "Arraste para cima para voltar ao modo normal"
                                 : "Arraste para cima para ativar o Modo Seguro")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.Colors.textGray.opacity(0.65))
                                .padding(.top, 14)
                        }
                        .padding(16)
                    }
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
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 10) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.primaryRed)
                        }

                        if let firstPhoto = conversation?.profile.photos.first {
                            PhotoContentView(photo: firstPhoto)
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(AppTheme.Colors.primaryRed.opacity(0.14))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(String((conversation?.profile.firstName ?? "?").prefix(1)).uppercased())
                                        .font(AppTheme.Typography.subheadline())
                                        .foregroundStyle(AppTheme.Colors.primaryRed)
                                )
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 4) {
                                Text(conversation?.profile.firstName ?? "Conversa")
                                    .font(AppTheme.Typography.headline())
                                    .foregroundStyle(AppTheme.Colors.darkGray)
                                if conversation?.profile.isVerified == true {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(hex: "3B82F6"))
                                }
                            }
                            if !partnerStatusText.isEmpty {
                                Text(partnerStatusText)
                                    .font(.system(size: 11.5, weight: .regular))
                                    .foregroundStyle(Color(hex: "8E8E93"))
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
                            .font(.system(size: 18))
                            .foregroundStyle(AppTheme.Colors.primaryRed)
                    }
                }
            }
            .onAppear {
                let idStr = conversationId.uuidString.lowercased()
                appState.socketClient.joinChat(conversationId: idStr)
                appState.socketClient.markRead(conversationId: idStr)
            }
            .onDisappear {
                let idStr = conversationId.uuidString.lowercased()
                appState.socketClient.sendTyping(conversationId: idStr, isTyping: false)
                appState.socketClient.leaveChat(conversationId: idStr)
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
                            if message.type == .audio && !message.isViewOnce {
                                Button {
                                    if let url = URL(string: message.text) {
                                        let player = AVPlayer(url: url)
                                        self.audioPlayer = player
                                        player.play()
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 22))
                                        Text("Mensagem de áudio")
                                            .font(AppTheme.Typography.body())
                                    }
                                }
                                .buttonStyle(.plain)
                            } else if message.type == .image && !message.isViewOnce, let imgUrl = URL(string: message.text) {
                                AsyncImage(url: imgUrl) { phase in
                                    if case .success(let img) = phase {
                                        img
                                            .resizable()
                                            .scaledToFill()
                                            .frame(maxWidth: 210, maxHeight: 240)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    } else {
                                        ProgressView()
                                            .frame(width: 160, height: 140)
                                    }
                                }
                            } else {
                                Text(message.type == .audio && message.viewedAt == nil ? "Áudio de visualização única" : message.text)
                                    .font(AppTheme.Typography.body())
                            }
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
            if audioRecorder.isRecording {
                Button {
                    audioRecorder.cancelRecording()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.Colors.textGray)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancelar gravação")

                HStack(spacing: 8) {
                    Circle()
                        .fill(AppTheme.Colors.primaryRed)
                        .frame(width: 8, height: 8)

                    Text(String(format: "%d:%02d", audioRecorder.elapsedSeconds / 60, audioRecorder.elapsedSeconds % 60))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(AppTheme.Colors.darkGray)

                    HStack(spacing: 2.5) {
                        ForEach(Array(audioRecorder.levels.enumerated()), id: \.offset) { _, level in
                            Capsule()
                                .fill(AppTheme.Colors.primaryRed)
                                .frame(width: 3, height: max(4, level * 26))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .animation(.linear(duration: 0.08), value: audioRecorder.levels)
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(AppTheme.Colors.white, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                )

                Button {
                    toggleViewOnce()
                } label: {
                    Image(systemName: viewModel.isViewOnce ? "1.circle.fill" : "1.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(viewModel.isViewOnce ? AppTheme.Colors.primaryRed : AppTheme.Colors.textGray)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Áudio de visualização única")

                Button {
                    Task { await finishAndSendAudio() }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.Colors.primaryRed, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Enviar áudio")
            } else {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 19))
                        .foregroundStyle(AppTheme.Colors.primaryRed)
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
                        audioRecorder.startRecording()
                    } label: {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.Colors.primaryRed, in: Circle())
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
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.Colors.primaryRed, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
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
        guard let audioData = audioRecorder.stopRecording() else { return }
        struct AudioUploadResponse: Decodable {
            let url: String
        }
        guard let uploaded: AudioUploadResponse = try? await APIClient.shared.uploadJPEG(
            path: "/messages/audio-upload",
            imageData: audioData,
            filename: "voice.m4a"
        ) else { return }

        let viewOnce = viewModel.isViewOnce
        viewModel.isViewOnce = false
        if viewOnce && !appState.isPremium {
            let used = UserDefaults.standard.integer(forKey: "free_view_once_used_count")
            UserDefaults.standard.set(used + 1, forKey: "free_view_once_used_count")
        }

        appState.socketClient.sendMessage(
            conversationId: conversationId.uuidString.lowercased(),
            content: uploaded.url,
            type: "AUDIO",
            isViewOnce: viewOnce,
            isEphemeralOnExit: viewModel.isEphemeralOnExit
        )
    }

    private func sendSelectedPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
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

        let viewOnce = viewModel.isViewOnce
        viewModel.isViewOnce = false
        if viewOnce && !appState.isPremium {
            let used = UserDefaults.standard.integer(forKey: "free_view_once_used_count")
            UserDefaults.standard.set(used + 1, forKey: "free_view_once_used_count")
        }

        appState.socketClient.sendMessage(
            conversationId: conversationId.uuidString.lowercased(),
            content: urlStr,
            type: "IMAGE",
            isViewOnce: viewOnce,
            isEphemeralOnExit: viewModel.isEphemeralOnExit
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

@MainActor
private final class AudioRecorderHelper: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var levels: [CGFloat] = Array(repeating: 0.15, count: 24)
    @Published var elapsedSeconds: Int = 0

    private var recorder: AVAudioRecorder?
    private var fileURL: URL?
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
