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
    @State private var editingMessageId: UUID? = nil
    @State private var replyingToMessage: ChatMessage? = nil
    @State private var showAttachmentMenu = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showDocumentImporter = false
    @State private var recMicPulse = false

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
                                        groupMessageRow(msg)
                                            .id(msg.id)
                                            .contextMenu {
                                                Button {
                                                    withAnimation(.easeInOut(duration: 0.16)) {
                                                        replyingToMessage = msg
                                                    }
                                                } label: {
                                                    Label("Responder", systemImage: "arrowshape.turn.up.left")
                                                }

                                                if msg.isFromMe, case .text(let original) = msg.kind {
                                                    Button {
                                                        editingMessageId = msg.id
                                                        replyingToMessage = nil
                                                        inputText = original
                                                    } label: {
                                                        Label("Editar mensagem", systemImage: "pencil")
                                                    }
                                                }

                                                Button(role: .destructive) {
                                                    withAnimation {
                                                        store.deleteGroupChatMessage(groupId: groupId, messageId: msg.id)
                                                    }
                                                } label: {
                                                    Label("Excluir mensagem", systemImage: "trash")
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
                .background(JuntoColors.warmBg)
                .onChange(of: messages.count) { _, _ in
                    if let lastId = messages.last?.id {
                        withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                    }
                }
            }

            // Banner de Resposta (Reply) ou Edição acima da barra de texto
            if let replyMsg = replyingToMessage {
                let author = replyMsg.isFromMe ? "Você" : (replyMsg.senderName ?? "Participante")
                let authorColor = replyMsg.isFromMe ? JuntoColors.primary : colorForMember(replyMsg.senderUsername ?? author)

                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(authorColor)
                        .frame(width: 3.5, height: 34)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Respondendo a \(author)")
                            .font(.inter(12, weight: .medium))
                            .foregroundColor(authorColor)
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

            // Barra Inferior (estilo WhatsApp: + menu, texto, áudio)
            HStack(alignment: .center, spacing: 10) {
                if audioManager.isRecording {
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
                            .onDisappear { recMicPulse = false }

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

                    Button {
                        recMicPulse = false
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

                    TextField("Mensagem no grupo...", text: $inputText, axis: .vertical)
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
                onSelectPix: {
                    showAttachmentMenu = false
                    store.sendGroupChatMessage(
                        groupId: groupId,
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

                // Conteúdo da mensagem
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

                case .system:
                    EmptyView()
                }

                // Rodapé: editada + hora
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
