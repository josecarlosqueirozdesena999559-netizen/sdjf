import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// Chat de Grupo organizado: foto e nome do usuário com cores únicas por participante, respostas (reply), áudios, imagens, documentos e Pix
struct GroupChatScreen: View {
    @EnvironmentObject var store: JuntoStore
    let groupId: UUID
    var onOpenGroupDetails: (() -> Void)? = nil
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

    private var group: RoleGroup? {
        store.groups.first(where: { $0.id == groupId })
    }

    private var messages: [ChatMessage] {
        store.groupMessages(for: groupId)
    }

    /// Paleta curada de cores distintas e legíveis para os nomes dos participantes no grupo
    private static let memberNameColors: [Color] = [
        Color(hex: "#2563EB"), // Cobalto
        Color(hex: "#7C3AED"), // Violeta
        Color(hex: "#0D9488"), // Turquesa
        Color(hex: "#D97706"), // Âmbar
        Color(hex: "#DB2777"), // Magenta
        Color(hex: "#059669"), // Esmeralda
        Color(hex: "#E2711D"), // Terracota
        Color(hex: "#4F46E5"), // Índigo
        Color(hex: "#0284C7")  // Oceano
    ]

    private func colorForMember(_ username: String) -> Color {
        var hash = 5381
        for byte in username.lowercased().utf8 {
            hash = ((hash << 5) &+ hash) &+ Int(byte)
        }
        return Self.memberNameColors[abs(hash) % Self.memberNameColors.count]
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
            // Cabeçalho do Grupo: Voltar + Capa + Nome + Lista de participantes
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

                if let g = group {
                    Button {
                        onOpenGroupDetails?()
                    } label: {
                        HStack(spacing: 10) {
                            groupCoverThumb(g)
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            VStack(alignment: .leading, spacing: 1) {
                                Text(g.title)
                                    .font(.inter(16, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                                    .lineLimit(1)

                                let names = g.participants.map { $0.name.split(separator: " ").first.map(String.init) ?? $0.name }
                                Text(names.joined(separator: ", "))
                                    .font(.inter(12, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                Spacer()

                if onOpenGroupDetails != nil {
                    Button {
                        onOpenGroupDetails?()
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(JuntoColors.primary)
                            .frame(width: 34, height: 34)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white)
            .overlay(Rectangle().fill(JuntoColors.border).frame(height: 0.8), alignment: .bottom)

            // Área de Mensagens do Grupo
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedMessagesByDate, id: \.date) { section in
                            Section(header: datePillHeader(section.date)) {
                                ForEach(section.items) { msg in
                                    if case .system(let infoText) = msg.kind {
                                        systemPill(infoText)
                                            .id(msg.id)
                                    } else {
                                        SwipeToReplyContainer(
                                            onReply: {
                                                withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                                                    replyingToMessage = msg
                                                    isInputFocused = true
                                                }
                                            }
                                        ) {
                                            groupMessageRow(msg)
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
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
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

            // Snackbar flutuante de Desfazer Exclusão no grupo (estilo WhatsApp: 5 segundos com cronômetro para cancelar)
            if pendingDeleteMessageId != nil {
                UndoDeleteSnackbar(secondsRemaining: undoCountdown) {
                    undoDelete()
                }
            }

            // Banner de Resposta (Reply) com visual amplo e nítido
            if let replyMsg = replyingToMessage {
                let author = replyMsg.isFromMe ? "Você" : (replyMsg.senderName ?? "Participante")
                let authorColor = replyMsg.isFromMe ? JuntoColors.primary : colorForMember(replyMsg.senderUsername ?? author)

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

            // Barra Inferior: estilo WhatsApp com cronômetro em cima, "Gravando" ao lado das ondas e "Excluir" para cancelar
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

                    TextField("Mensagem no grupo...", text: $inputText, axis: .vertical)
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
                                store.editGroupChatMessage(groupId: groupId, messageId: editId, newText: text)
                                editingMessageId = nil
                            } else {
                                let rAuthor = replyingToMessage.map { $0.isFromMe ? "Você" : ($0.senderName ?? "Participante") }
                                let rPreview = replyingToMessage?.previewText
                                replyingToMessage = nil
                                store.sendGroupChatMessage(
                                    groupId: groupId,
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

            // Menu customizado ao segurar mensagem no grupo (visual do app estilo WhatsApp)
            if let menuMsg = selectedMessageForMenu {
                let canEdit: Bool = {
                    if menuMsg.isFromMe, case .text = menuMsg.kind { return true }
                    return false
                }()
                CustomMessageMenuOverlay(
                    previewText: menuMsg.previewText,
                    authorName: menuMsg.isFromMe ? "Você" : (menuMsg.senderName ?? "Participante"),
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
            audioManager.onPlaybackFinished = { finishedId in
                store.markGroupAudioListened(groupId: groupId, messageId: finishedId)
                let list = store.groupMessages(for: groupId)
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
        .sheet(isPresented: $showAttachmentMenu) {
            ChatAttachmentMenuSheet(
                onSelectPhoto: {
                    showAttachmentMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { showPhotoPicker = true }
                },
                onSelectDocument: {
                    showAttachmentMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { showDocumentImporter = true }
                },
                onSelectPoll: {
                    showAttachmentMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { showCreatePollSheet = true }
                },
                onSelectPix: {
                    showAttachmentMenu = false
                    store.sendGroupChatMessage(
                        groupId: groupId,
                        kind: .text("Minha chave Pix: \(store.user.pixKey)")
                    )
                }
            )
            .presentationDetents([.height(225)])
            .presentationCornerRadius(22)
        }
        .sheet(isPresented: $showCreatePollSheet) {
            CreateChatPollSheet { pollData in
                store.sendGroupChatMessage(groupId: groupId, kind: .poll(pollData))
            }
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(20)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    store.sendGroupChatMessage(groupId: groupId, kind: .photo(data, ""))
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
                store.sendGroupChatMessage(groupId: groupId, kind: .document(url.lastPathComponent, "Arquivo"))
            }
        }
    }

    // MARK: - Bolha de Mensagem do Grupo (Avatar + Nome colorido do participante + Citação de Resposta)
    @ViewBuilder
    private func groupMessageRow(_ msg: ChatMessage) -> some View {
        let senderSeed = msg.senderUsername ?? msg.senderName ?? "membro"
        let senderDisplayName = msg.senderName ?? "Participante"
        let nameColor = colorForMember(senderSeed)

        HStack(alignment: .bottom, spacing: 8) {
            if msg.isFromMe {
                Spacer(minLength: 48)
            } else {
                // Foto do usuário no grupo ao lado esquerdo da bolha
                GeometricAvatarView(seed: senderSeed, displayName: senderDisplayName, size: 30)
            }

            VStack(alignment: .leading, spacing: 5) {
                // Nome do participante em cor única (somente para mensagens de outros membros)
                if !msg.isFromMe {
                    Text(senderDisplayName)
                        .font(.inter(12, weight: .medium))
                        .foregroundColor(nameColor)
                }

                // Bloco de resposta citada (Reply)
                if let replyAuthor = msg.replyToAuthor, let replyPreview = msg.replyToPreview {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(msg.isFromMe ? JuntoColors.accent : colorForMember(replyAuthor))
                            .frame(width: 3)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(replyAuthor)
                                .font(.inter(11, weight: .medium))
                                .foregroundColor(msg.isFromMe ? JuntoColors.accent : colorForMember(replyAuthor))
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

                // Conteúdo da mensagem responsivo para qualquer tamanho de tela
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
                            .font(.system(size: 18))
                            .foregroundColor(msg.isFromMe ? JuntoColors.accent : JuntoColors.primary)
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
                        store.voteInGroupPoll(groupId: groupId, messageId: msg.id, optionId: optionId)
                    }

                case .system:
                    EmptyView()
                }

                // Rodapé: editada + hora + traços de entregue / lido no grupo
                HStack(spacing: 4) {
                    Spacer()
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
                        groupMessageStatusTicks(msg.status)
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

            if !msg.isFromMe { Spacer(minLength: 42) }
        }
    }

    private func systemPill(_ text: String) -> some View {
        HStack {
            Spacer()
            Text(text)
                .font(.inter(11, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.9))
                .overlay(Capsule().stroke(JuntoColors.border, lineWidth: 0.6))
                .clipShape(Capsule())
            Spacer()
        }
        .padding(.vertical, 4)
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

    // MARK: - Ações de Envio e Desfazer Exclusão no Grupo
    private func sendRecordedAudio() {
        recMicPulse = false
        isMicLocked = false
        isDraggingMic = false
        micDragOffsetY = 0
        let recorded = audioManager.finishRecording()
        let rAuthor = replyingToMessage.map { $0.isFromMe ? "Você" : ($0.senderName ?? "Participante") }
        let rPreview = replyingToMessage?.previewText
        replyingToMessage = nil
        store.sendGroupChatMessage(
            groupId: groupId,
            kind: .audio(
                duration: recorded.duration,
                waveform: recorded.waveform.map { Double($0) },
                fileURL: recorded.fileURL
            ),
            replyToAuthor: rAuthor,
            replyToPreview: rPreview
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
            store.deleteGroupChatMessage(groupId: groupId, messageId: id)
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

    /// 1 traço (enviado), 2 traços (entregue no grupo), 2 traços azuis (lido no grupo)
    @ViewBuilder
    private func groupMessageStatusTicks(_ status: MessageDeliveryStatus) -> some View {
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
            .foregroundColor(Color(hex: "#38BDF8"))
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
            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func groupCoverThumb(_ g: RoleGroup) -> some View {
        if let data = g.coverImageData, let uiImg = UIImage(data: data) {
            Image(uiImage: uiImg).resizable().scaledToFill()
        } else {
            Image(g.coverImageName).resizable().scaledToFill()
        }
    }
}
