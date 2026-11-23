import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// Chat estilo WhatsApp: sem saldo no topo, lixeira no lugar do "+" ao gravar áudio, e tela de perfil ao tocar no topo
struct FriendChatScreen: View {
    @EnvironmentObject var store: JuntoStore
    let friend: FriendItem
    @Environment(\.dismiss) private var dismiss

    @State private var inputText = ""
    @State private var editingMessageId: UUID? = nil
    @State private var replyingToMessage: ChatMessage? = nil
    @State private var selectedMessageForMenu: ChatMessage? = nil
    @State private var showAttachmentMenu = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showDocumentImporter = false
    @State private var showProfileScreen = false
    @State private var recMicPulse = false

    @StateObject private var audioManager = AudioChatManager()

    private var currentFriend: FriendItem {
        store.friends.first(where: { $0.username == friend.username }) ?? friend
    }

    private var messages: [ChatMessage] {
        store.messages(for: friend.username)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
            // Topo limpo estilo WhatsApp (SEM saldo e SEM bolinha online no avatar — toque no perfil abre FriendProfileScreen!)
            HStack(spacing: 12) {
                Button {
                    audioManager.stopPlayback()
                    audioManager.cancelRecording()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                        .frame(width: 34, height: 34)
                }

                Button {
                    showProfileScreen = true
                } label: {
                    HStack(spacing: 10) {
                        GeometricAvatarView(seed: currentFriend.username, size: 40)

                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 5) {
                                Text(currentFriend.name)
                                    .font(.inter(16, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                                    .lineLimit(1)
                                if currentFriend.isMuted {
                                    Image(systemName: "bell.slash.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(JuntoColors.textLight)
                                }
                            }

                            Text(currentFriend.isOnline ? "online" : currentFriend.lastSeenText)
                                .font(.inter(12, weight: .regular))
                                .foregroundColor(currentFriend.isOnline ? JuntoColors.pixGreen : JuntoColors.textMuted)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white)
            .overlay(Rectangle().fill(JuntoColors.border).frame(height: 0.8), alignment: .bottom)

            // Área de Mensagens
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    if messages.isEmpty {
                        VStack(spacing: 10) {
                            Spacer().frame(height: 80)
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 32, weight: .thin))
                                .foregroundColor(JuntoColors.textLight)
                            Text("Nenhuma mensagem ainda.")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                            Text("Envie texto, áudio, foto ou documento.")
                                .font(.inter(12, weight: .regular))
                                .foregroundColor(JuntoColors.textLight)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        LazyVStack(spacing: 10, pinnedViews: [.sectionHeaders]) {
                            ForEach(groupedMessagesByDate, id: \.date) { section in
                                Section(header: datePillHeader(section.date)) {
                                    ForEach(section.items) { msg in
                                        SwipeToReplyContainer(
                                            onReply: {
                                                withAnimation(.easeInOut(duration: 0.16)) {
                                                    replyingToMessage = msg
                                                }
                                            }
                                        ) {
                                            chatBubble(msg)
                                        }
                                        .id(msg.id)
                                        .onLongPressGesture(minimumDuration: 0.35) {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                                                selectedMessageForMenu = msg
                                            }
                                        }
                                    }
                                }
                            }

                            if currentFriend.isTyping {
                                HStack {
                                    TypingDotsBubble()
                                    Spacer()
                                }
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                    }
                }
                .background(JuntoColors.warmBg)
                .onChange(of: messages.count) { _, _ in
                    if let lastId = messages.last?.id {
                        withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                    }
                }
            }

            // Banner de Resposta (Reply) ou Edição de mensagem
            if let replyMsg = replyingToMessage {
                let author = replyMsg.isFromMe ? "Você" : currentFriend.name
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(JuntoColors.primary)
                        .frame(width: 3.5, height: 34)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Respondendo a \(author)")
                            .font(.inter(12, weight: .medium))
                            .foregroundColor(JuntoColors.primary)
                        Text(replyMsg.previewText)
                            .font(.inter(12, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { replyingToMessage = nil }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(JuntoColors.textMuted)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white)
                .overlay(Rectangle().fill(JuntoColors.border).frame(height: 0.7), alignment: .top)
            } else if editingMessageId != nil {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13))
                        .foregroundColor(JuntoColors.primary)
                    Text("Editando mensagem")
                        .font(.inter(12, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Spacer()
                    Button {
                        editingMessageId = nil
                        inputText = ""
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                            .foregroundColor(JuntoColors.textMuted)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(JuntoColors.primaryLight)
            }

            // Barra Inferior de Envio: estilo WhatsApp ao gravar áudio (lixeira SEM fundo + microfone pulsando + ondas fluidas)
            HStack(alignment: .center, spacing: 10) {
                if audioManager.isRecording {
                    // Lixeira limpa SEM fundo para cancelar o áudio
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            recMicPulse = false
                            audioManager.cancelRecording()
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(JuntoColors.danger)
                            .frame(width: 34, height: 34)
                    }

                    // Animação de gravação estilo WhatsApp (microfone vermelho pulsando + timer + ondas fluidas em tempo real)
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(JuntoColors.danger)
                            .scaleEffect(recMicPulse ? 1.12 : 0.90)
                            .opacity(recMicPulse ? 1.0 : 0.35)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true)) {
                                    recMicPulse = true
                                }
                            }
                            .onDisappear {
                                recMicPulse = false
                            }

                        Text("0:\(String(format: "%02d", audioManager.recordingSeconds))")
                            .font(.inter(13, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                            .monospacedDigit()

                        HStack(spacing: 2.5) {
                            let bars = Array(audioManager.liveLevels.suffix(26))
                            ForEach(Array(bars.enumerated()), id: \.offset) { _, lvl in
                                Capsule()
                                    .fill(JuntoColors.textMuted.opacity(0.75))
                                    .frame(width: 2.5, height: max(4, lvl * 24))
                            }
                        }
                        .animation(.easeOut(duration: 0.12), value: audioManager.liveLevels)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(JuntoColors.surfaceSubtle)
                    .clipShape(Capsule())

                    // Enviar áudio gravado
                    Button {
                        recMicPulse = false
                        let recorded = audioManager.finishRecording()
                        store.sendChatMessage(
                            to: friend.username,
                            kind: .audio(
                                duration: recorded.duration,
                                waveform: recorded.waveform.map { Double($0) },
                                fileURL: recorded.fileURL
                            )
                        )
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(JuntoColors.primary)
                            .clipShape(Circle())
                    }
                } else {
                    Button {
                        showAttachmentMenu = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(JuntoColors.primary)
                            .frame(width: 40, height: 40)
                            .background(JuntoColors.surfaceSubtle)
                            .clipShape(Circle())
                    }

                    TextField("Mensagem...", text: $inputText, axis: .vertical)
                        .font(.inter(15, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                        .lineLimit(1...4)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(JuntoColors.surfaceSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                audioManager.startRecording()
                            }
                        } label: {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 42, height: 42)
                                .background(JuntoColors.primary)
                                .clipShape(Circle())
                        }
                    } else {
                        Button {
                            let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !text.isEmpty else { return }
                            inputText = ""
                            if let editId = editingMessageId {
                                store.editChatMessage(username: friend.username, messageId: editId, newText: text)
                                editingMessageId = nil
                            } else {
                                let rAuthor = replyingToMessage.map { $0.isFromMe ? "Você" : currentFriend.name }
                                let rPreview = replyingToMessage?.previewText
                                replyingToMessage = nil
                                store.sendChatMessage(
                                    to: friend.username,
                                    kind: .text(text),
                                    replyToAuthor: rAuthor,
                                    replyToPreview: rPreview
                                )
                            }
                        } label: {
                            Image(systemName: editingMessageId != nil ? "checkmark" : "paperplane.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 42, height: 42)
                                .background(JuntoColors.primary)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white)
            .overlay(Rectangle().fill(JuntoColors.border).frame(height: 0.8), alignment: .top)
            }

            // Menu customizado ao segurar mensagem (visual do app estilo WhatsApp, sem cara nativa iOS)
            if let menuMsg = selectedMessageForMenu {
                let canEdit: Bool = {
                    if menuMsg.isFromMe, case .text = menuMsg.kind { return true }
                    return false
                }()
                CustomMessageMenuOverlay(
                    previewText: menuMsg.previewText,
                    authorName: menuMsg.isFromMe ? "Você" : currentFriend.name,
                    canEdit: canEdit,
                    onReply: {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            replyingToMessage = menuMsg
                            selectedMessageForMenu = nil
                        }
                    },
                    onEdit: {
                        if case .text(let original) = menuMsg.kind {
                            editingMessageId = menuMsg.id
                            replyingToMessage = nil
                            inputText = original
                        }
                        withAnimation(.easeInOut(duration: 0.15)) { selectedMessageForMenu = nil }
                    },
                    onDelete: {
                        withAnimation {
                            store.deleteChatMessage(username: friend.username, messageId: menuMsg.id)
                            selectedMessageForMenu = nil
                        }
                    },
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.15)) { selectedMessageForMenu = nil }
                    }
                )
            }
        }
        .onAppear {
            // Marca áudio como escutado (ondas ficam laranja) e toca o próximo áudio consecutivo automaticamente
            audioManager.onPlaybackFinished = { finishedId in
                store.markAudioListened(username: friend.username, messageId: finishedId)
                let list = store.messages(for: friend.username)
                guard let idx = list.firstIndex(where: { $0.id == finishedId }),
                      idx + 1 < list.count else { return }
                let nextMsg = list[idx + 1]
                if case .audio(let nextDur, _, let nextURL) = nextMsg.kind {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        audioManager.togglePlayback(messageId: nextMsg.id, fileURL: nextURL, durationSeconds: nextDur)
                    }
                }
            }
        }
        .onDisappear {
            audioManager.onPlaybackFinished = nil
            audioManager.stopPlayback()
            audioManager.cancelRecording()
        }
        .fullScreenCover(isPresented: $showProfileScreen) {
            FriendProfileScreen(friend: currentFriend) {
                // Se o usuário foi bloqueado, fecha o chat também
                dismiss()
            }
            .environmentObject(store)
        }
        .sheet(isPresented: $showAttachmentMenu) {
            ChatAttachmentMenuSheet(
                onSelectPhoto: {
                    showAttachmentMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        showPhotoPicker = true
                    }
                },
                onSelectDocument: {
                    showAttachmentMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        showDocumentImporter = true
                    }
                },
                onSelectPix: {
                    showAttachmentMenu = false
                    store.sendChatMessage(
                        to: friend.username,
                        kind: .text("Minha chave Pix: \(store.user.pixKey)")
                    )
                }
            )
            .presentationDetents([.height(210)])
            .presentationCornerRadius(22)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    store.sendChatMessage(to: friend.username, kind: .photo(data, ""))
                }
                selectedPhotoItem = nil
            }
        }
        .fileImporter(
            isPresented: $showDocumentImporter,
            allowedContentTypes: [.pdf, .item],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                store.sendChatMessage(to: friend.username, kind: .document(url.lastPathComponent, "Arquivo"))
            }
        }
    }

    @ViewBuilder
    private func chatBubble(_ msg: ChatMessage) -> some View {
        HStack {
            if msg.isFromMe { Spacer(minLength: 48) }

            VStack(alignment: .trailing, spacing: 4) {
                // Citação da mensagem respondida (Reply)
                if let replyAuthor = msg.replyToAuthor, let replyPreview = msg.replyToPreview {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(msg.isFromMe ? JuntoColors.accent : JuntoColors.primary)
                            .frame(width: 3)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(replyAuthor)
                                .font(.inter(11, weight: .medium))
                                .foregroundColor(msg.isFromMe ? JuntoColors.accent : JuntoColors.primary)
                            Text(replyPreview)
                                .font(.inter(11, weight: .regular))
                                .foregroundColor(msg.isFromMe ? .white.opacity(0.78) : JuntoColors.textMuted)
                                .lineLimit(2)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(msg.isFromMe ? Color.white.opacity(0.10) : JuntoColors.surfaceSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                switch msg.kind {
                case .text(let txt):
                    Text(txt)
                        .font(.inter(14, weight: .regular))
                        .foregroundColor(msg.isFromMe ? .white : JuntoColors.textMain)

                case .photo(let data, let caption):
                    VStack(alignment: .leading, spacing: 6) {
                        if let data = data, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 200, height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 180, height: 120)
                                .overlay(Image(systemName: "photo").font(.system(size: 26)))
                        }
                        if !caption.isEmpty {
                            Text(caption)
                                .font(.inter(13, weight: .regular))
                                .foregroundColor(msg.isFromMe ? .white : JuntoColors.textMain)
                        }
                    }

                case .audio(let seconds, let waveform, let fileURL):
                    let isPlaying = audioManager.playingMessageId == msg.id
                    let progress = isPlaying ? audioManager.playbackProgress : 0.0
                    let bars = waveform.isEmpty ? Array(repeating: 0.4, count: 24) : waveform

                    HStack(spacing: 10) {
                        Button {
                            audioManager.togglePlayback(messageId: msg.id, fileURL: fileURL, durationSeconds: seconds)
                        } label: {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14))
                                .foregroundColor(msg.isFromMe ? JuntoColors.primary : .white)
                                .frame(width: 34, height: 34)
                                .background(msg.isFromMe ? Color.white : JuntoColors.primary)
                                .clipShape(Circle())
                        }

                        // Ondas: AZUL enquanto escuta; LARANJA após escutado (sinaliza para ambos que foi ouvido)
                        HStack(spacing: 2.5) {
                            ForEach(Array(bars.enumerated()), id: \.offset) { idx, level in
                                let barFraction = Double(idx + 1) / Double(max(bars.count, 1))
                                let isActiveBar = isPlaying && barFraction <= progress
                                let playingBlue: Color = msg.isFromMe ? Color(hex: "#38BDF8") : Color(hex: "#2563EB")
                                let listenedOrange: Color = JuntoColors.accent
                                let unplayedColor: Color = msg.isFromMe ? Color.white.opacity(0.40) : JuntoColors.primary.opacity(0.24)
                                let barColor: Color = isActiveBar ? playingBlue : (msg.isListened ? listenedOrange : unplayedColor)

                                Capsule()
                                    .fill(barColor)
                                    .frame(width: 2.8, height: max(5, CGFloat(level) * 24))
                                    .animation(.easeOut(duration: 0.1), value: isActiveBar)
                            }
                        }

                        Text("0:\(String(format: "%02d", isPlaying ? audioManager.playbackCurrentSeconds : seconds))")
                            .font(.inter(11, weight: .regular))
                            .monospacedDigit()
                            .foregroundColor(msg.isFromMe ? .white.opacity(0.85) : JuntoColors.textMuted)
                    }

                case .document(let fileName, let sizeText):
                    HStack(spacing: 10) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 20))
                            .foregroundColor(msg.isFromMe ? JuntoColors.accent : JuntoColors.primary)
                            .frame(width: 36, height: 36)
                            .background(msg.isFromMe ? Color.white.opacity(0.14) : JuntoColors.primaryLight)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(fileName)
                                .font(.inter(13, weight: .medium))
                                .foregroundColor(msg.isFromMe ? .white : JuntoColors.textMain)
                                .lineLimit(1)
                            Text(sizeText)
                                .font(.inter(11, weight: .regular))
                                .foregroundColor(msg.isFromMe ? .white.opacity(0.75) : JuntoColors.textMuted)
                        }
                    }

                case .system(let info):
                    Text(info)
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }

                HStack(spacing: 4) {
                    if msg.isEdited {
                        Text("editada")
                            .font(.inter(10, weight: .regular))
                            .italic()
                            .foregroundColor(msg.isFromMe ? .white.opacity(0.65) : JuntoColors.textLight)
                    }
                    Text(msg.timeText)
                        .font(.inter(10, weight: .regular))
                        .foregroundColor(msg.isFromMe ? .white.opacity(0.72) : JuntoColors.textLight)
                    if msg.isFromMe {
                        messageStatusTicks(msg.status)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(msg.isFromMe ? JuntoColors.primary : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(msg.isFromMe ? Color.clear : JuntoColors.border, lineWidth: 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if !msg.isFromMe { Spacer(minLength: 48) }
        }
    }

    private var groupedMessagesByDate: [(date: String, items: [ChatMessage])] {
        var order: [String] = []
        var map: [String: [ChatMessage]] = [:]
        for m in messages {
            if map[m.dateLabel] == nil { order.append(m.dateLabel) }
            map[m.dateLabel, default: []].append(m)
        }
        return order.map { ($0, map[$0] ?? []) }
    }

    private func datePillHeader(_ label: String) -> some View {
        HStack {
            Spacer()
            Text(label)
                .font(.inter(11, weight: .medium))
                .foregroundColor(JuntoColors.textMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.95))
                .overlay(Capsule().stroke(JuntoColors.border, lineWidth: 0.7))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 1)
            Spacer()
        }
        .padding(.vertical, 6)
    }

    /// 1 traço (não entregue/enviado), 2 traços (entregue), 2 traços coloridos (lido)
    @ViewBuilder
    private func messageStatusTicks(_ status: MessageDeliveryStatus) -> some View {
        switch status {
        case .sent:
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.65))
        case .delivered:
            HStack(spacing: -5) {
                Image(systemName: "checkmark")
                Image(systemName: "checkmark")
            }
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(Color.white.opacity(0.70))
        case .read:
            HStack(spacing: -5) {
                Image(systemName: "checkmark")
                Image(systemName: "checkmark")
            }
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(Color(hex: "#38BDF8")) // Dois traços azuis de lido!
        }
    }
}

// MARK: - Tela de Perfil do Usuário Estilo WhatsApp (voltar só no topo, sem fundo vermelho no bloquear)
struct FriendProfileScreen: View {
    @EnvironmentObject var store: JuntoStore
    let friend: FriendItem
    var onBlocked: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var showBlockConfirm = false

    private var liveFriend: FriendItem {
        store.friends.first(where: { $0.username == friend.username }) ?? friend
    }

    var body: some View {
        ZStack {
            JuntoColors.warmBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Topo estilo WhatsApp: apenas botão voltar para a conversa + título
                HStack {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .medium))
                            Text("Conversa")
                                .font(.inter(15, weight: .regular))
                        }
                        .foregroundColor(JuntoColors.primary)
                    }
                    Spacer()
                    Text("Dados do contato")
                        .font(.inter(16, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Spacer()
                    Spacer().frame(width: 78)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .overlay(Rectangle().fill(JuntoColors.border).frame(height: 0.7), alignment: .bottom)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // Cabeçalho centralizado limpo estilo WhatsApp
                        VStack(spacing: 10) {
                            GeometricAvatarView(seed: liveFriend.username, size: 104)
                                .padding(.top, 18)

                            Text(liveFriend.name)
                                .font(.inter(22, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)

                            Text("@\(liveFriend.username)")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)

                            Text(liveFriend.isOnline ? "online" : liveFriend.lastSeenText)
                                .font(.inter(13, weight: .regular))
                                .foregroundColor(liveFriend.isOnline ? JuntoColors.pixGreen : JuntoColors.textLight)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 8)

                        // Grupo de informações (Amigos desde + Silenciar notificações)
                        VStack(spacing: 0) {
                            HStack(spacing: 14) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                    .frame(width: 26)

                                Text("Amigos desde")
                                    .font(.inter(15, weight: .regular))
                                    .foregroundColor(JuntoColors.textMain)

                                Spacer()

                                Text(liveFriend.friendsSinceText)
                                    .font(.inter(14, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            Divider().padding(.leading, 56)

                            HStack(spacing: 14) {
                                Image(systemName: liveFriend.isMuted ? "bell.slash" : "bell")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                    .frame(width: 26)

                                Toggle("Silenciar notificações", isOn: Binding(
                                    get: { liveFriend.isMuted },
                                    set: { _ in store.toggleMuteFriend(username: liveFriend.username) }
                                ))
                                .font(.inter(15, weight: .regular))
                                .foregroundColor(JuntoColors.textMain)
                                .tint(JuntoColors.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(JuntoColors.border, lineWidth: 0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Ação Bloquear estilo WhatsApp (fundo branco limpo, ícone nosign, texto vermelho discreto)
                        Button {
                            showBlockConfirm = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "nosign")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(JuntoColors.danger)
                                    .frame(width: 26)

                                Text("Bloquear \(liveFriend.name.split(separator: " ").first.map(String.init) ?? liveFriend.name)")
                                    .font(.inter(15, weight: .regular))
                                    .foregroundColor(JuntoColors.danger)

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 15)
                            .background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(JuntoColors.border, lineWidth: 0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 32)
                }
            }
        }
        .alert("Bloquear \(liveFriend.name)?", isPresented: $showBlockConfirm) {
            Button("Cancelar", role: .cancel) {}
            Button("Bloquear", role: .destructive) {
                store.blockAndUnfriend(username: liveFriend.username)
                dismiss()
                onBlocked()
            }
        } message: {
            Text("Essa pessoa não poderá mais enviar mensagens para você.")
        }
    }
}

// MARK: - Balão animado "digitando..." (3 pontinhos saltando na parte inferior do chat)
struct TypingDotsBubble: View {
    @State private var phase: Int = 0
    private let timer = Timer.publish(every: 0.34, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(JuntoColors.textMuted)
                    .frame(width: 7, height: 7)
                    .scaleEffect(phase == index ? 1.25 : 0.78)
                    .opacity(phase == index ? 1.0 : 0.45)
                    .offset(y: phase == index ? -3 : 0)
                    .animation(.easeInOut(duration: 0.28), value: phase)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(JuntoColors.border, lineWidth: 0.8))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
    }
}

// MARK: - Menu "+" estilo WhatsApp (Imagens, Documentos, Pix)
struct ChatAttachmentMenuSheet: View {
    let onSelectPhoto: () -> Void
    let onSelectDocument: () -> Void
    let onSelectPix: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("Enviar na conversa")
                    .font(.inter(16, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(JuntoColors.textMuted)
                        .frame(width: 30, height: 30)
                        .background(JuntoColors.surfaceSubtle)
                        .clipShape(Circle())
                }
            }
            .padding(.top, 18)

            HStack(spacing: 18) {
                attachmentOption(icon: "photo.on.rectangle.angled", label: "Imagens", color: Color(hex: "#2563EB"), action: onSelectPhoto)
                attachmentOption(icon: "doc.text", label: "Documentos", color: Color(hex: "#7C3AED"), action: onSelectDocument)
                attachmentOption(icon: "qrcode", label: "Pix", color: JuntoColors.pixGreen, action: onSelectPix)
            }

            Spacer()
        }
        .padding(.horizontal, 22)
        .background(JuntoColors.warmBg.ignoresSafeArea())
    }

    private func attachmentOption(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(color)
                    .frame(width: 58, height: 58)
                    .background(Color.white)
                    .overlay(Circle().stroke(JuntoColors.border, lineWidth: 1))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.04), radius: 5, y: 2)

                Text(label)
                    .font(.inter(12, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Gesto Arrastar para o Lado para Responder (estilo WhatsApp)
struct SwipeToReplyContainer<Content: View>: View {
    let onReply: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var dragOffset: CGFloat = 0
    @State private var didTriggerHaptic = false

    var body: some View {
        ZStack(alignment: .leading) {
            // Ícone de resposta que aparece suavemente ao arrastar para a direita
            if dragOffset > 8 {
                Image(systemName: "arrowshape.turn.up.left.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(dragOffset >= 42 ? .white : JuntoColors.primary)
                    .frame(width: 30, height: 30)
                    .background(dragOffset >= 42 ? JuntoColors.primary : JuntoColors.primaryLight)
                    .clipShape(Circle())
                    .scaleEffect(min(1.0, dragOffset / 40.0))
                    .opacity(min(1.0, dragOffset / 30.0))
                    .padding(.leading, 4)
            }

            content()
                .offset(x: dragOffset)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 16, coordinateSpace: .local)
                .onChanged { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    guard dx > 0, abs(dx) > abs(dy) * 1.25 else { return }
                    let damped = min(dx * 0.65, 58)
                    dragOffset = damped
                    if damped >= 42 && !didTriggerHaptic {
                        didTriggerHaptic = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                .onEnded { _ in
                    let shouldReply = dragOffset >= 42
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        dragOffset = 0
                    }
                    didTriggerHaptic = false
                    if shouldReply {
                        onReply()
                    }
                }
        )
    }
}

// MARK: - Menu Customizado ao Segurar Mensagem (visual do app estilo WhatsApp, sem cara nativa)
struct CustomMessageMenuOverlay: View {
    let previewText: String
    let authorName: String
    let canEdit: Bool
    let onReply: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 12) {
                // Prévia da mensagem selecionada
                VStack(alignment: .leading, spacing: 4) {
                    Text(authorName)
                        .font(.inter(12, weight: .medium))
                        .foregroundColor(JuntoColors.primary)
                    Text(previewText)
                        .font(.inter(14, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Card de ações do app (Responder · Editar · Apagar)
                VStack(spacing: 0) {
                    actionRow(icon: "arrowshape.turn.up.left", title: "Responder", color: JuntoColors.textMain, action: onReply)

                    if canEdit {
                        Divider().padding(.leading, 48)
                        actionRow(icon: "pencil", title: "Editar", color: JuntoColors.textMain, action: onEdit)
                    }

                    Divider().padding(.leading, 48)
                    actionRow(icon: "trash", title: "Apagar", color: JuntoColors.danger, action: onDelete)
                }
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.black.opacity(0.14), radius: 18, y: 8)
            }
            .padding(.horizontal, 28)
            .transition(.scale(scale: 0.94).combined(with: .opacity))
        }
    }

    private func actionRow(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(color)
                    .frame(width: 22)
                Text(title)
                    .font(.inter(15, weight: .medium))
                    .foregroundColor(color)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
        }
    }
}
