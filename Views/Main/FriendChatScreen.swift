import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// Chat estilo WhatsApp: sem saldo no topo, lixeira no lugar do "+" ao gravar áudio, e tela de perfil ao tocar no topo
struct FriendChatScreen: View {
    @EnvironmentObject var store: JuntoStore
    let friend: FriendItem
    @Environment(\.dismiss) private var dismiss

    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @State private var editingMessageId: UUID? = nil
    @State private var replyingToMessage: ChatMessage? = nil
    @State private var selectedMessageForMenu: ChatMessage? = nil
    @State private var showAttachmentMenu = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showDocumentImporter = false
    @State private var showCreatePollSheet = false
    @State private var showProfileScreen = false
    @State private var recMicPulse = false

    // Desfazer exclusão com cronômetro de 5 segundos estilo WhatsApp
    @State private var pendingDeleteMessageId: UUID? = nil
    @State private var undoCountdown = 5
    @State private var undoTimer: Timer? = nil

    // Gravação de áudio com trava arrastando para cima estilo WhatsApp
    @State private var isMicLocked = false
    @State private var isDraggingMic = false
    @State private var micDragOffsetY: CGFloat = 0

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
                                VerifiedBadgeView(type: currentFriend.proPlanType, size: 14)
                                if currentFriend.isMuted {
                                    Image(systemName: "bell.slash.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(JuntoColors.textLight)
                                }
                            }

                            Text(currentFriend.isTyping ? "digitando..." : (currentFriend.isOnline ? "online" : currentFriend.lastSeenText))
                                .font(.inter(12, weight: .regular))
                                .foregroundColor((currentFriend.isOnline || currentFriend.isTyping) ? JuntoColors.pixGreen : JuntoColors.textMuted)
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
                                                withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                                                    replyingToMessage = msg
                                                    isInputFocused = true
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

                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            if abs(value.translation.height) > 16 {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        }
                )
                .background(JuntoColors.warmBg)
                .onAppear {
                    if let lastId = messages.last?.id {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: messages.count) { _, _ in
                    if let lastId = messages.last?.id {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isInputFocused) { _, focused in
                    if focused, let lastId = messages.last?.id {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            // Snackbar flutuante de Desfazer Exclusão (estilo WhatsApp: 5 segundos com cronômetro para cancelar)
            if pendingDeleteMessageId != nil {
                UndoDeleteSnackbar(secondsRemaining: undoCountdown) {
                    undoDelete()
                }
            }

            // Banner de Resposta (Reply) com visual amplo e nítido
            if let replyMsg = replyingToMessage {
                let author = replyMsg.isFromMe ? "Você" : currentFriend.name
                let authorColor = replyMsg.isFromMe ? JuntoColors.primary : Color(hex: "#2563EB")

                HStack(alignment: .center, spacing: 12) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(authorColor)
                        .frame(width: 4, height: 42)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrowshape.turn.up.left")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(authorColor)
                            Text(author)
                                .font(.inter(13, weight: .semibold))
                                .foregroundColor(authorColor)
                        }

                        HStack(spacing: 6) {
                            replyIconForKind(replyMsg.kind)
                            Text(replyMsg.previewText)
                                .font(.inter(13, weight: .regular))
                                .foregroundColor(JuntoColors.textMain.opacity(0.85))
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.8)) {
                            replyingToMessage = nil
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(JuntoColors.textMuted)
                            .frame(width: 28, height: 28)
                            .background(JuntoColors.surfaceSubtle)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white)
                .overlay(Rectangle().fill(JuntoColors.border).frame(height: 0.8), alignment: .top)
            }

            // Barra Inferior de Envio: estilo WhatsApp com cronômetro em cima, "Gravando" ao lado das ondas e "Excluir" para cancelar
            HStack(alignment: .center, spacing: 10) {
                if audioManager.isRecording {
                    // Botão Excluir para cancelar antes de enviar (estilo WhatsApp)
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            recMicPulse = false
                            isMicLocked = false
                            audioManager.cancelRecording()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .medium))
                            Text("Excluir")
                                .font(.inter(13, weight: .medium))
                        }
                        .foregroundColor(JuntoColors.danger)
                        .padding(.horizontal, 10)
                        .frame(height: 40)
                        .background(JuntoColors.dangerLight)
                        .clipShape(Capsule())
                    }

                    // Cronômetro em cima + "Gravando" ao lado das ondas (SEM bola vermelha)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("0:\(String(format: "%02d", audioManager.recordingSeconds))")
                            .font(.inter(11, weight: .semibold))
                            .foregroundColor(JuntoColors.primary)
                            .monospacedDigit()

                        HStack(spacing: 8) {
                            Text("Gravando")
                                .font(.inter(12, weight: .medium))
                                .foregroundColor(JuntoColors.textMuted)

                            HStack(spacing: 2.5) {
                                let bars = Array(audioManager.liveLevels.suffix(18))
                                ForEach(Array(bars.enumerated()), id: \.offset) { _, lvl in
                                    Capsule()
                                        .fill(JuntoColors.primary.opacity(0.75))
                                        .frame(width: 2.4, height: max(4, lvl * 18))
                                }
                            }
                            .animation(.easeOut(duration: 0.12), value: audioManager.liveLevels)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(JuntoColors.surfaceSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    // Enviar áudio gravado
                    Button {
                        sendRecordedAudio()
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(JuntoColors.primary)
                            .clipShape(Circle())
                    }
                } else {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showAttachmentMenu = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(JuntoTapBounceStyle(scaleAmount: 0.90))

                    TextField("Mensagem...", text: $inputText, axis: .vertical)
                        .font(.inter(15, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                        .lineLimit(1...5)
                        .focused($isInputFocused)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(JuntoColors.surfaceSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // Microfone nativo iOS limpo
                        ZStack(alignment: .bottom) {
                            if audioManager.isRecording && !isMicLocked {
                                VStack(spacing: 5) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(JuntoColors.primary)
                                        .scaleEffect(micDragOffsetY < -30 ? 1.25 : 1.0)
                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(JuntoColors.primary)
                                }
                                .frame(width: 36, height: 52)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .shadow(color: Color.black.opacity(0.14), radius: 8, y: -3)
                                .offset(y: -54 + min(0, micDragOffsetY * 0.4))
                                .transition(.scale(scale: 0.85).combined(with: .opacity))
                            }

                            Button {
                                if !audioManager.isRecording {
                                    isMicLocked = true
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        audioManager.startRecording()
                                    }
                                }
                            } label: {
                                Image(systemName: "mic")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(JuntoColors.textMain)
                                    .frame(width: 36, height: 36)
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 4, coordinateSpace: .local)
                                    .onChanged { value in
                                        if !audioManager.isRecording {
                                            audioManager.startRecording()
                                            isDraggingMic = true
                                        }
                                        micDragOffsetY = value.translation.height

                                        if value.translation.height < -36 && !isMicLocked {
                                            isMicLocked = true
                                            micDragOffsetY = 0
                                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                        }
                                        if value.translation.width < -50 {
                                            audioManager.cancelRecording()
                                            isMicLocked = false
                                            isDraggingMic = false
                                            micDragOffsetY = 0
                                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                        }
                                    }
                                    .onEnded { _ in
                                        isDraggingMic = false
                                        micDragOffsetY = 0
                                        if !isMicLocked && audioManager.isRecording {
                                            if audioManager.recordingSeconds >= 1 {
                                                sendRecordedAudio()
                                            } else {
                                                isMicLocked = true
                                            }
                                        }
                                    }
                            )
                        }
                    } else {
                        Button {
                            let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !text.isEmpty else { return }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                            Image(systemName: editingMessageId != nil ? "checkmark" : "arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(JuntoColors.primary)
                                .clipShape(Circle())
                        }
                        .buttonStyle(JuntoTapBounceStyle(scaleAmount: 0.90))
                        .transition(.scale.combined(with: .opacity))
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
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                            replyingToMessage = menuMsg
                            selectedMessageForMenu = nil
                            isInputFocused = true
                        }
                    },
                    onEdit: {
                        if case .text(let original) = menuMsg.kind {
                            editingMessageId = menuMsg.id
                            replyingToMessage = nil
                            inputText = original
                            isInputFocused = true
                        }
                        withAnimation(.easeInOut(duration: 0.15)) { selectedMessageForMenu = nil }
                    },
                    onDelete: {
                        let targetId = menuMsg.id
                        selectedMessageForMenu = nil
                        startUndoDelete(for: targetId)
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
            finalizePendingDelete()
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
                onSelectPoll: {
                    showAttachmentMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        showCreatePollSheet = true
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
            .presentationDetents([.height(225)])
            .presentationCornerRadius(22)
        }
        .sheet(isPresented: $showCreatePollSheet) {
            CreateChatPollSheet { pollData in
                store.sendChatMessage(to: friend.username, kind: .poll(pollData))
            }
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(20)
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
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)

                case .photo(let data, let caption):
                    VStack(alignment: .leading, spacing: 6) {
                        if let data = data, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(minWidth: 160, maxWidth: 235, minHeight: 130, maxHeight: 185)
                                .clipped()
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
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                case .audio(let seconds, let waveform, let fileURL):
                    let isPlaying = audioManager.playingMessageId == msg.id
                    let progress = isPlaying ? audioManager.playbackProgress : 0.0
                    let bars = waveform.isEmpty ? Array(repeating: 0.4, count: 22) : Array(waveform.prefix(22))

                    HStack(spacing: 10) {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            audioManager.togglePlayback(messageId: msg.id, fileURL: fileURL, durationSeconds: seconds)
                        } label: {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14))
                                .foregroundColor(msg.isFromMe ? JuntoColors.primary : .white)
                                .frame(width: 34, height: 34)
                                .background(msg.isFromMe ? Color.white : JuntoColors.primary)
                                .clipShape(Circle())
                        }
                        .buttonStyle(JuntoTapBounceStyle(scaleAmount: 0.90))

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
                                    .frame(width: 2.6, height: max(5, CGFloat(level) * 24))
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

                case .poll(let pollData):
                    ChatPollBubbleView(
                        poll: pollData,
                        isFromMe: msg.isFromMe,
                        currentUsername: store.user.username
                    ) { optionId in
                        store.voteInFriendPoll(username: friend.username, messageId: msg.id, optionId: optionId)
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
        let activeMessages = messages.filter { $0.id != pendingDeleteMessageId }
        var order: [String] = []
        var map: [String: [ChatMessage]] = [:]
        for m in activeMessages {
            if map[m.dateLabel] == nil { order.append(m.dateLabel) }
            map[m.dateLabel, default: []].append(m)
        }
        return order.map { ($0, map[$0] ?? []) }
    }

    // MARK: - Ações de Envio e Desfazer Exclusão
    private func sendRecordedAudio() {
        recMicPulse = false
        isMicLocked = false
        isDraggingMic = false
        micDragOffsetY = 0
        let recorded = audioManager.finishRecording()
        store.sendChatMessage(
            to: friend.username,
            kind: .audio(
                duration: recorded.duration,
                waveform: recorded.waveform.map { Double($0) },
                fileURL: recorded.fileURL
            )
        )
    }

    private func startUndoDelete(for messageId: UUID) {
        finalizePendingDelete()
        withAnimation(.easeInOut(duration: 0.2)) {
            pendingDeleteMessageId = messageId
        }
        undoCountdown = 5
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        undoTimer?.invalidate()
        undoTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if undoCountdown > 1 {
                undoCountdown -= 1
            } else {
                finalizePendingDelete()
            }
        }
    }

    private func undoDelete() {
        undoTimer?.invalidate()
        undoTimer = nil
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
            pendingDeleteMessageId = nil
        }
        store.showToast("Mensagem restaurada.", icon: "checkmark")
    }

    private func finalizePendingDelete() {
        undoTimer?.invalidate()
        undoTimer = nil
        if let id = pendingDeleteMessageId {
            store.deleteChatMessage(username: friend.username, messageId: id)
            pendingDeleteMessageId = nil
        }
    }

    @ViewBuilder
    private func replyIconForKind(_ kind: ChatMessageKind) -> some View {
        switch kind {
        case .audio:
            Image(systemName: "mic.fill")
                .font(.system(size: 11))
                .foregroundColor(JuntoColors.accent)
        case .photo:
            Image(systemName: "photo")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#2563EB"))
        case .document:
            Image(systemName: "doc.text")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#7C3AED"))
        case .poll:
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#D97706"))
        default:
            EmptyView()
        }
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

                            HStack(spacing: 6) {
                                Text(liveFriend.name)
                                    .font(.inter(22, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                                VerifiedBadgeView(type: liveFriend.proPlanType, size: 18)
                            }

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

// MARK: - Menu "+" estilo WhatsApp (Fotos, Arquivos, Enquete, Pix com ícone oficial)
struct ChatAttachmentMenuSheet: View {
    let onSelectPhoto: () -> Void
    let onSelectDocument: () -> Void
    var onSelectPoll: (() -> Void)? = nil
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

            HStack(spacing: 14) {
                attachmentOption(icon: "photo.fill", label: "Fotos", color: Color(hex: "#2563EB"), action: onSelectPhoto)
                attachmentOption(icon: "doc.fill", label: "Arquivos", color: Color(hex: "#7C3AED"), action: onSelectDocument)
                if let onPoll = onSelectPoll {
                    attachmentOption(icon: "chart.bar.xaxis", label: "Enquete", color: Color(hex: "#D97706"), action: onPoll)
                }
                pixAttachmentOption(action: onSelectPix)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color.white.ignoresSafeArea())
    }

    private func attachmentOption(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 56, height: 56)
                    .background(Color.white)
                    .overlay(Circle().stroke(JuntoColors.border, lineWidth: 1))
                    .clipShape(Circle())

                Text(label)
                    .font(.inter(12, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func pixAttachmentOption(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                PixOfficialIcon(size: 24, color: Color(hex: "#32BCAD"))
                    .frame(width: 56, height: 56)
                    .background(Color.white)
                    .overlay(Circle().stroke(JuntoColors.border, lineWidth: 1))
                    .clipShape(Circle())

                Text("Pix")
                    .font(.inter(12, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Bolha de Enquete Interativa no Chat (Votação em tempo real com barras de progresso)
struct ChatPollBubbleView: View {
    let poll: ChatPollData
    let isFromMe: Bool
    let currentUsername: String
    let onVote: (UUID) -> Void

    var body: some View {
        let total = max(poll.totalVotes, 0)
        let myKey = currentUsername.lowercased()

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isFromMe ? JuntoColors.accent : JuntoColors.primary)
                Text("ENQUETE")
                    .font(.inter(10, weight: .bold))
                    .foregroundColor(isFromMe ? JuntoColors.accent : JuntoColors.primary)
            }

            Text(poll.question)
                .font(.inter(15, weight: .medium))
                .foregroundColor(isFromMe ? .white : JuntoColors.textMain)

            VStack(spacing: 8) {
                ForEach(poll.options) { opt in
                    let votesCount = opt.voterUsernames.count
                    let isVotedByMe = opt.voterUsernames.contains(myKey)
                    let ratio = total > 0 ? Double(votesCount) / Double(total) : 0.0
                    let pct = total > 0 ? Int(round(ratio * 100)) : 0

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onVote(opt.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 8) {
                                Image(systemName: isVotedByMe ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 15))
                                    .foregroundColor(isFromMe ? (isVotedByMe ? JuntoColors.accent : .white.opacity(0.75)) : (isVotedByMe ? JuntoColors.primary : JuntoColors.textLight))

                                Text(opt.text)
                                    .font(.inter(13, weight: .medium))
                                    .foregroundColor(isFromMe ? .white : JuntoColors.textMain)
                                    .lineLimit(2)

                                Spacer()

                                Text("\(votesCount) (\(pct)%)")
                                    .font(.inter(11, weight: .regular))
                                    .foregroundColor(isFromMe ? .white.opacity(0.8) : JuntoColors.textMuted)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(isFromMe ? Color.white.opacity(0.18) : JuntoColors.surfaceSubtle)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(isFromMe ? JuntoColors.accent : JuntoColors.primary)
                                        .frame(width: geo.size.width * CGFloat(ratio))
                                }
                            }
                            .frame(height: 5)
                        }
                        .padding(9)
                        .background(isFromMe ? Color.white.opacity(0.08) : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isFromMe ? Color.white.opacity(0.16) : JuntoColors.border, lineWidth: 0.8)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            Text("\(poll.totalVotes) voto(s) • Toque em uma opção para votar")
                .font(.inter(11, weight: .regular))
                .foregroundColor(isFromMe ? .white.opacity(0.7) : JuntoColors.textMuted)
        }
        .frame(minWidth: 200, maxWidth: 265)
    }
}

// MARK: - Sheet para Criar Enquete no Chat
struct CreateChatPollSheet: View {
    let onCreate: (ChatPollData) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var question: String = ""
    @State private var option1: String = ""
    @State private var option2: String = ""
    @State private var option3: String = ""
    @State private var allowMultiple: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Criar enquete")
                    .font(.inter(18, weight: .medium))
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

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    CleanOutlineInput(
                        label: "Pergunta da enquete",
                        placeholder: "Ex: Qual dia vamos para a praia?",
                        text: $question
                    )

                    CleanOutlineInput(
                        label: "Opção 1",
                        placeholder: "Ex: Sexta à noite",
                        text: $option1
                    )

                    CleanOutlineInput(
                        label: "Opção 2",
                        placeholder: "Ex: Sábado cedo",
                        text: $option2
                    )

                    CleanOutlineInput(
                        label: "Opção 3 (opcional)",
                        placeholder: "Ex: Domingo",
                        text: $option3
                    )

                    Toggle("Permitir múltiplas respostas", isOn: $allowMultiple)
                        .font(.inter(14, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                        .tint(JuntoColors.primary)
                        .padding(.vertical, 4)

                    JuntoPillButton(title: "Enviar enquete", color: JuntoColors.primary) {
                        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
                        let o1 = option1.trimmingCharacters(in: .whitespacesAndNewlines)
                        let o2 = option2.trimmingCharacters(in: .whitespacesAndNewlines)
                        let o3 = option3.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !q.isEmpty, !o1.isEmpty, !o2.isEmpty else { return }

                        var opts = [ChatPollOption(text: o1), ChatPollOption(text: o2)]
                        if !o3.isEmpty { opts.append(ChatPollOption(text: o3)) }

                        onCreate(ChatPollData(question: q, options: opts, allowMultipleAnswers: allowMultiple))
                        dismiss()
                    }
                    .padding(.top, 6)
                }
            }
        }
        .padding(.horizontal, 20)
        .background(Color.white.ignoresSafeArea())
    }
}

// MARK: - Snackbar de Desfazer Exclusão (estilo WhatsApp: 5 segundos com cronômetro para cancelar)
struct UndoDeleteSnackbar: View {
    let secondsRemaining: Int
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trash")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white)

            Text("Mensagem apagada para todos")
                .font(.inter(13, weight: .regular))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer(minLength: 4)

            // Badge circular com os segundos restantes
            Text("\(secondsRemaining)s")
                .font(.inter(12, weight: .bold))
                .foregroundColor(JuntoColors.accent)
                .monospacedDigit()
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.14))
                .clipShape(Circle())

            Button(action: onUndo) {
                Text("Desfazer")
                    .font(.inter(13, weight: .semibold))
                    .foregroundColor(JuntoColors.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(hex: "#1E293B"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.24), radius: 10, y: 4)
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Gesto Arrastar para o Lado para Responder Fluido e Macio (estilo WhatsApp)
struct SwipeToReplyContainer<Content: View>: View {
    let onReply: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var dragOffset: CGFloat = 0
    @State private var didTriggerHaptic = false

    var body: some View {
        ZStack(alignment: .leading) {
            // Ícone de resposta suave e fluido
            if dragOffset > 4 {
                let progress = min(1.0, dragOffset / 38.0)
                let isTriggered = dragOffset >= 38
                ZStack {
                    Circle()
                        .fill(isTriggered ? JuntoColors.primary : JuntoColors.primaryLight)
                        .frame(width: 32, height: 32)

                    Image(systemName: "arrowshape.turn.up.left")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isTriggered ? .white : JuntoColors.primary)
                }
                .scaleEffect(isTriggered ? 1.08 : max(0.5, progress))
                .opacity(min(1.0, progress * 1.3))
                .offset(x: min(dragOffset * 0.45, 18))
                .animation(.interactiveSpring(response: 0.22, dampingFraction: 0.75), value: dragOffset)
            }

            content()
                .offset(x: dragOffset)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 6, coordinateSpace: .local)
                .onChanged { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    // Apenas arrasto horizontal para a direita sem conflito vertical
                    guard dx > 0, dx > abs(dy) * 1.15 else { return }
                    // Curva física contínua suave sem degraus
                    let damped = min(pow(dx, 0.86) * 1.7, 54)
                    dragOffset = damped
                    if damped >= 38 && !didTriggerHaptic {
                        didTriggerHaptic = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } else if damped < 38 {
                        didTriggerHaptic = false
                    }
                }
                .onEnded { _ in
                    let shouldReply = dragOffset >= 38
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.72)) {
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
