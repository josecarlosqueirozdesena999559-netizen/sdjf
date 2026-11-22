import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// Chat completo estilo WhatsApp com texto, foto, áudio, documento, status online / visto por último (SEM bolinha online no avatar)
struct FriendChatScreen: View {
    @EnvironmentObject var store: JuntoStore
    let friend: FriendItem
    @Environment(\.dismiss) private var dismiss

    @State private var inputText = ""
    @State private var showAttachmentMenu = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showDocumentImporter = false

    // Gravação e reprodução de áudio
    @State private var isRecordingAudio = false
    @State private var recordingSeconds = 0
    @State private var playingMessageId: UUID? = nil

    private let recordTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    private var messages: [ChatMessage] {
        store.messages(for: friend.username)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Topo do Chat estilo WhatsApp (SEM bolinha online no avatar!)
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                        .frame(width: 34, height: 34)
                }

                GeometricAvatarView(seed: friend.username, size: 40)

                VStack(alignment: .leading, spacing: 1) {
                    Text(friend.name)
                        .font(.inter(16, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                        .lineLimit(1)

                    Text(friend.isOnline ? "online" : friend.lastSeenText)
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(friend.isOnline ? JuntoColors.pixGreen : JuntoColors.textMuted)
                        .lineLimit(1)
                }

                Spacer()

                // Atalho financeiro discreto no topo (se houver dívida)
                if friend.balance < 0 {
                    Button {
                        dismiss()
                        store.openPixPayment(
                            title: "Acerto com \(friend.name)",
                            recipient: friend.name,
                            amount: abs(friend.balance)
                        )
                    } label: {
                        Text("Pagar \(JuntoStore.formatBRL(abs(friend.balance)))")
                            .font(.inter(12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(JuntoColors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } else if friend.balance > 0 {
                    Text("Te deve \(JuntoStore.formatBRL(friend.balance))")
                        .font(.inter(11, weight: .medium))
                        .foregroundColor(JuntoColors.pixGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(JuntoColors.pixGreenLight)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
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
                        LazyVStack(spacing: 10) {
                            ForEach(messages) { msg in
                                chatBubble(msg)
                                    .id(msg.id)
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

            // Barra Inferior de Envio (Clipe/Anexos + Campo de Texto + Áudio/Enviar)
            HStack(alignment: .bottom, spacing: 8) {
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

                if isRecordingAudio {
                    // Estado de gravação de áudio ao vivo
                    HStack(spacing: 10) {
                        Circle()
                            .fill(JuntoColors.danger)
                            .frame(width: 10, height: 10)
                        Text("Gravando áudio  0:\(String(format: "%02d", recordingSeconds))")
                            .font(.inter(14, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)
                        Spacer()
                        Button("Cancelar") {
                            isRecordingAudio = false
                            recordingSeconds = 0
                        }
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.danger)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 42)
                    .background(JuntoColors.dangerLight)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    TextField("Mensagem...", text: $inputText, axis: .vertical)
                        .font(.inter(15, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                        .lineLimit(1...4)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(JuntoColors.surfaceSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                if isRecordingAudio {
                    Button {
                        let secs = max(recordingSeconds, 1)
                        isRecordingAudio = false
                        recordingSeconds = 0
                        store.sendChatMessage(to: friend.username, kind: .audio(secs))
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 42, height: 42)
                            .background(JuntoColors.pixGreen)
                            .clipShape(Circle())
                    }
                } else if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        recordingSeconds = 0
                        isRecordingAudio = true
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
                        store.sendChatMessage(to: friend.username, kind: .text(text))
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 42, height: 42)
                            .background(JuntoColors.primary)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white)
            .overlay(Rectangle().fill(JuntoColors.border).frame(height: 0.8), alignment: .top)
        }
        .onReceive(recordTimer) { _ in
            if isRecordingAudio { recordingSeconds += 1 }
        }
        .confirmationDialog("Enviar anexo", isPresented: $showAttachmentMenu, titleVisibility: .visible) {
            Button("Foto da galeria") { showPhotoPicker = true }
            Button("Documento (PDF / arquivo)") { showDocumentImporter = true }
            Button("Enviar comprovante rápido (PDF)") {
                store.sendChatMessage(to: friend.username, kind: .document("Comprovante_Pix.pdf", "124 KB"))
            }
            Button("Cancelar", role: .cancel) {}
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

                case .audio(let seconds):
                    let isPlaying = playingMessageId == msg.id
                    HStack(spacing: 10) {
                        Button {
                            playingMessageId = isPlaying ? nil : msg.id
                        } label: {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14))
                                .foregroundColor(msg.isFromMe ? JuntoColors.primary : .white)
                                .frame(width: 32, height: 32)
                                .background(msg.isFromMe ? Color.white : JuntoColors.primary)
                                .clipShape(Circle())
                        }

                        // Ondas de áudio minimalistas
                        HStack(spacing: 3) {
                            ForEach(0..<14, id: \.self) { i in
                                Capsule()
                                    .fill(msg.isFromMe ? Color.white.opacity(0.75) : JuntoColors.primary.opacity(0.55))
                                    .frame(width: 3, height: CGFloat([8, 14, 18, 10, 20, 14, 9, 17, 12, 19, 11, 15, 9, 12][i]))
                            }
                        }

                        Text("0:\(String(format: "%02d", seconds))")
                            .font(.inter(12, weight: .regular))
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
                }

                // Horário + check de leitura
                HStack(spacing: 3) {
                    Text(msg.timeText)
                        .font(.inter(10, weight: .regular))
                        .foregroundColor(msg.isFromMe ? .white.opacity(0.72) : JuntoColors.textLight)
                    if msg.isFromMe {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(JuntoColors.accent)
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
}
