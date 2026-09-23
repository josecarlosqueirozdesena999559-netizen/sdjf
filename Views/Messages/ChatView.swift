import SwiftUI
import AVFoundation
import AVKit
import PhotosUI

struct ChatView: View {
    @StateObject var viewModel: ChatViewModel
    @State private var messageText = ""
    @AppStorage("hideFloatingButton") private var hideFloatingButton = false
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var participantName = "Usuário"
    @State private var participantAvatarURL: String?
    @State private var audioPlayer: AVPlayer?
    @State private var selectedItem: PhotosPickerItem? = nil

    init(conversation: Conversation, currentUser: User) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(conversation: conversation, currentUser: currentUser))
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            HStack {
                                if message.senderId == viewModel.currentUser.id { Spacer(minLength: 48) }
                                messageBubble(message, isMine: message.senderId == viewModel.currentUser.id)
                                if message.senderId != viewModel.currentUser.id { Spacer(minLength: 48) }
                            }
                            .padding(.horizontal)
                            .id(message.id)
                        }
                        Color.clear.frame(height: 1).id("chat-bottom")
                    }
                    .padding(.vertical, 12)
                }
                .onAppear { proxy.scrollTo("chat-bottom", anchor: .bottom) }
                .onChange(of: viewModel.messages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("chat-bottom", anchor: .bottom)
                    }
                }
            }
            composer
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task { await loadParticipant() }
        .onAppear { hideFloatingButton = true }
        .onDisappear { hideFloatingButton = false }
        .toolbar {
            ToolbarItem(placement: .principal) {
                chatHeader
            }
        }
    }

    private var chatHeader: some View {
        HStack(spacing: 10) {
            Group {
                if let value = participantAvatarURL, let url = URL(string: value) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image { image.resizable().scaledToFill() }
                        else { Image(systemName: "person.crop.circle.fill") }
                    }
                } else { Image(systemName: "person.crop.circle.fill") }
            }
            .foregroundColor(Theme.textSecondary)
            .frame(width: 36, height: 36)
            .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(participantName).typographyButton()
                if !statusText.isEmpty {
                    HStack(spacing: 4) {
                        if viewModel.otherUserOnline {
                            Circle().fill(Theme.primary).frame(width: 8, height: 8)
                        } else if viewModel.isTyping {
                            Image(systemName: "ellipsis.bubble.fill").foregroundColor(Theme.primary).typographyCaption()
                        }
                        Text(statusText)
                            .typographyLabel()
                            .foregroundColor(viewModel.otherUserOnline || viewModel.isTyping ? Theme.primary : Theme.textSecondary)
                    }
                }
            }
        }
    }

    private var composer: some View {
        HStack {
            PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                Image(systemName: "plus")
                    .typographyScreenTitle()
                    .foregroundColor(Theme.primary)
                    .padding(.leading, 10)
            }
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        let isVideo = newItem.supportedContentTypes.contains(where: { it in it.conforms(to: .movie) || it.conforms(to: .video) })
                        await viewModel.sendMedia(data: data, isVideo: isVideo)
                    }
                    selectedItem = nil
                }
            }

            if audioRecorder.isRecording {
                Label("Gravando áudio…", systemImage: "waveform")
                    .foregroundColor(.red)
                    .padding(.leading, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                TextField("Mensagem...", text: $messageText)
                    .padding(.horizontal, 14)
                    .onChange(of: messageText) { _, _ in viewModel.sendTypingEvent() }
            }

            Button {
                if audioRecorder.isRecording {
                    guard let fileURL = audioRecorder.stop() else { return }
                    Task { await viewModel.sendAudio(fileURL: fileURL) }
                } else if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Task { _ = await audioRecorder.start() }
                } else {
                    let text = messageText
                    messageText = ""
                    Task { await viewModel.sendMessage(text: text) }
                }
            } label: {
                Image(systemName: audioRecorder.isRecording ? "stop.circle.fill" : (messageText.isEmpty ? "mic.fill" : "arrow.up.circle.fill"))
                    .typographyScreenTitle()
                    .foregroundColor(audioRecorder.isRecording ? .red : Theme.primary)
                    .padding(8)
            }
            .accessibilityLabel(audioRecorder.isRecording ? "Parar gravação" : "Enviar ou gravar áudio")
        }
        .padding(6)
        .background(Color.black.opacity(0.05))
        .clipShape(Capsule())
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.white)
    }

    private var statusText: String {
        if viewModel.isTyping { return "digitando..." }
        if viewModel.otherUserOnline { return "online" }
        guard let lastSeen = viewModel.lastSeen else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "pt_BR")
        return "visto " + formatter.localizedString(for: lastSeen, relativeTo: Date())
    }

    @ViewBuilder private func messageBubble(_ message: Message, isMine: Bool) -> some View {
        HStack {
            if isMine { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 2) {
                                if let path = message.imageName {
                    if path.hasSuffix(".m4a") {
                        Button { Task { await playAudio(path: path) } } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "play.circle.fill")
                                    .font(.custom("Inter-Regular", size: 32))
                                Text("Áudio")
                                    .typographyBody()
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 4)
                        }
                    } else {
                        ChatMediaRenderer(path: path)
                    }
                } else {
                    Text(message.text)
                        .typographyBody()
                }
                
                HStack(spacing: 4) {
                    Text(Formatters.timeFormatter.string(from: message.timestamp))
                        .typographyCaption()
                        .foregroundColor(isMine ? Color.white.opacity(0.8) : Theme.textSecondary)
                    
                    if isMine {
                        Image(systemName: message.isRead ? "checkmark" : "checkmark")
                            .typographyCaption()
                            .foregroundColor(message.isRead ? .blue : Color.white.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundColor(isMine ? .white : Theme.textPrimary)
            .background(isMine ? Theme.primary : Theme.inputBackground)
            .cornerRadius(16, corners: isMine ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
            .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
            
            if !isMine { Spacer(minLength: 40) }
        }
    }

    private func playAudio(path: String) async {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let url = try await supabase.storage.from("chat-media").createSignedURL(path: path, expiresIn: 3_600)
            let player = AVPlayer(url: url)
            audioPlayer = player
            player.play()
        } catch {
            print("Erro ao reproduzir áudio: \(error)")
        }
    }

    private func loadParticipant() async {
        struct Profile: Decodable { let name: String?; let visible_name: String?; let avatar_url: String? }
        do {
            let profile: Profile = try await supabase.database
                .from("profiles")
                .select("name,visible_name,avatar_url")
                .eq("id", value: viewModel.conversation.participantId)
                .single()
                .execute()
                .value
            participantName = profile.visible_name ?? profile.name ?? "Usuário"
            participantAvatarURL = profile.avatar_url
        } catch {
            print("Erro ao carregar participante: \(error)")
        }
    }
}

struct ChatMediaRenderer: View {
    let path: String
    @State private var url: URL?
    var body: some View {
        Group {
            if let url = url {
                if path.hasSuffix(".mp4") {
                    VideoPlayer(player: AVPlayer(url: url))
                        .frame(width: 250, height: 250)
                        .cornerRadius(10)
                } else {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill().frame(maxWidth: 250, maxHeight: 250).clipped().cornerRadius(10)
                        } else {
                            ProgressView()
                        }
                    }
                }
            } else {
                ProgressView().onAppear { loadURL() }
            }
        }
    }
    func loadURL() {
        Task {
            url = try? await supabase.storage.from("chat-media").createSignedURL(path: path, expiresIn: 3600)
        }
    }
}