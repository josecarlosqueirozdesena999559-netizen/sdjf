import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// Chat estilo WhatsApp: sem saldo no topo, lixeira no lugar do "+" ao gravar áudio, e tela de perfil ao tocar no topo
struct FriendChatScreen: View {
    @EnvironmentObject var store: JuntoStore
    let friend: FriendItem
    @Environment(\.dismiss) private var dismiss

    @State private var inputText = ""
    @State private var showAttachmentMenu = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showDocumentImporter = false
    @State private var showProfileScreen = false

    // Gravação e reprodução de áudio
    @State private var isRecordingAudio = false
    @State private var recordingSeconds = 0
    @State private var playingMessageId: UUID? = nil

    private let recordTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    private var currentFriend: FriendItem {
        store.friends.first(where: { $0.username == friend.username }) ?? friend
    }

    private var messages: [ChatMessage] {
        store.messages(for: friend.username)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Topo limpo estilo WhatsApp (SEM saldo e SEM bolinha online no avatar — toque no perfil abre FriendProfileScreen!)
            HStack(spacing: 12) {
                Button { dismiss() } label: {
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

            // Barra Inferior de Envio: ao gravar áudio, o botão "+" some e entra a LIXEIRA para cancelar!
            HStack(alignment: .bottom, spacing: 8) {
                if isRecordingAudio {
                    // Lixeira para cancelar o áudio (substitui o "+")
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            isRecordingAudio = false
                            recordingSeconds = 0
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(JuntoColors.danger)
                            .frame(width: 40, height: 40)
                            .background(JuntoColors.dangerLight)
                            .clipShape(Circle())
                    }

                    // Indicador de gravação ao vivo
                    HStack(spacing: 10) {
                        Circle()
                            .fill(JuntoColors.danger)
                            .frame(width: 9, height: 9)
                        Text("Gravando áudio  0:\(String(format: "%02d", recordingSeconds))")
                            .font(.inter(14, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 42)
                    .background(JuntoColors.surfaceSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Enviar áudio
                    Button {
                        let secs = max(recordingSeconds, 1)
                        withAnimation(.easeInOut(duration: 0.18)) {
                            isRecordingAudio = false
                            recordingSeconds = 0
                        }
                        store.sendChatMessage(to: friend.username, kind: .audio(secs))
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 42, height: 42)
                            .background(JuntoColors.pixGreen)
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
                            recordingSeconds = 0
                            withAnimation(.easeInOut(duration: 0.18)) {
                                isRecordingAudio = true
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
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white)
            .overlay(Rectangle().fill(JuntoColors.border).frame(height: 0.8), alignment: .top)
        }
        .onReceive(recordTimer) { _ in
            if isRecordingAudio { recordingSeconds += 1 }
        }
        .fullScreenCover(isPresented: $showProfileScreen) {
            FriendProfileScreen(friend: currentFriend) {
                // Se o usuário foi bloqueado, fecha o chat também
                dismiss()
            }
            .environmentObject(store)
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

// MARK: - Tela de Perfil do Usuário (ao tocar no topo da conversa)
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
                HStack {
                    CircleNavButton(icon: "chevron.left") { dismiss() }
                    Spacer()
                    Text("Perfil")
                        .font(.inter(17, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Spacer()
                    Spacer().frame(width: 44)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 14)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // Cartão de identidade
                        VStack(spacing: 12) {
                            GeometricAvatarView(seed: liveFriend.username, size: 88)

                            VStack(spacing: 4) {
                                Text(liveFriend.name)
                                    .font(.inter(20, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                                Text("@\(liveFriend.username)")
                                    .font(.inter(14, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                Text(liveFriend.isOnline ? "online" : liveFriend.lastSeenText)
                                    .font(.inter(12, weight: .regular))
                                    .foregroundColor(liveFriend.isOnline ? JuntoColors.pixGreen : JuntoColors.textLight)
                                    .padding(.top, 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Informações & Notificações
                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 15))
                                    .foregroundColor(JuntoColors.primary)
                                    .frame(width: 32, height: 32)
                                    .background(JuntoColors.primaryLight)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Amigos desde")
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                    Text(liveFriend.friendsSinceText)
                                        .font(.inter(14, weight: .medium))
                                        .foregroundColor(JuntoColors.textMain)
                                }
                                Spacer()
                            }
                            .padding(14)

                            Divider().padding(.leading, 58)

                            HStack(spacing: 12) {
                                Image(systemName: liveFriend.isMuted ? "bell.slash" : "bell")
                                    .font(.system(size: 15))
                                    .foregroundColor(JuntoColors.primary)
                                    .frame(width: 32, height: 32)
                                    .background(JuntoColors.primaryLight)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                Toggle("Silenciar notificações", isOn: Binding(
                                    get: { liveFriend.isMuted },
                                    set: { _ in store.toggleMuteFriend(username: liveFriend.username) }
                                ))
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMain)
                                .tint(JuntoColors.primary)
                            }
                            .padding(14)
                        }
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Voltar para a conversa
                        JuntoPillButton(title: "Voltar para a conversa", icon: "bubble.left", color: JuntoColors.primary) {
                            dismiss()
                        }

                        // Bloquear usuário (desfaz amizade automaticamente)
                        Button {
                            showBlockConfirm = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "hand.raised")
                                Text("Bloquear usuário")
                                    .font(.inter(15, weight: .medium))
                            }
                            .foregroundColor(JuntoColors.danger)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(JuntoColors.dangerLight)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(JuntoColors.danger.opacity(0.25), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal, 20)
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
            Text("Ao bloquear, a amizade será desfeita automaticamente e essa pessoa não poderá mais falar com você.")
        }
    }
}
