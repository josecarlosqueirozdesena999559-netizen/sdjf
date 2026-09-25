import SwiftUI
import AVFoundation
import AVKit
import PhotosUI

struct ChatView: View {
    @StateObject var viewModel: ChatViewModel
    @State private var messageText = ""
    @AppStorage("hideFloatingButton") private var hideFloatingButton = false
    @StateObject private var aÁudioRecorder = AudioRecorder()
    @State private var participantName = "UsuÃ¡rio"
    @State private var participantAvatarURL: String?
    @State private var aÁudioPlayer: AVPlayer?
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var participantUser: User? = nil

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
        Group {
            if let user = participantUser {
                NavigationLink(destination: SellerProfileView(seller: Seller(id: user.id, user: user, isVerified: false, rating: 0, reviewCount: 0, salesCount: 0, averageResponseTime: "", bio: ""))) {
                    headerContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                headerContent
            }
        }
    }

    private var statusText: String {
        if viewModel.isTyping { return "Digitando..." }
        if viewModel.otherUserOnline { return "Online" }
        if let last = viewModel.lastSeen {
            let df = DateFormatter()
            df.dateStyle = .short
            df.timeStyle = .short
            return "Visto por Ãºltimo: \(df.string(from: last))"
        }
        return ""
    }
    
    private var headerContent: some View {
        HStack(spacing: 12) {
            Group {
                if let value = participantAvatarURL, let url = URL(string: value) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image { image.resizable().scaledToFill() }
                        else { Image(systemName: "person.crop.circle.fill").resizable() }
                    }
                } else { Image(systemName: "person.crop.circle.fill").resizable() }
            }
            .foregroundColor(Theme.textSecondary)
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(participantName).font(.custom("Inter-Bold", size: 16))
                if !statusText.isEmpty {
                    Text(statusText)
                        .font(.custom("Inter-Regular", size: 13))
                        .foregroundColor(viewModel.otherUserOnline || viewModel.isTyping ? Theme.primary : Theme.textSecondary)
                }
            }
            Spacer()
        }
    }

        private var composer: some View {
        HStack(spacing: 8) {
            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                    Image(systemName: "plus")
                        .font(.system(size: 22))
                        .foregroundColor(Theme.textSecondary)
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

                if aÁudioRecorder.isRecording {
                    Label("Gravando...", systemImage: "waveform")
                        .foregroundColor(.red)
                        .typographyBody()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    TextField("Mensagem...", text: $messageText)
                        .typographyBody()
                        .onChange(of: messageText) { _, _ in viewModel.sendTypingEvent() }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Theme.inputBackground)
            .clipShape(Capsule())

            Button {
                if aÁudioRecorder.isRecording {
                    guard let fileURL = aÁudioRecorder.stop() else { return }
                    Task { await viewModel.sendAudio(fileURL: fileURL) }
                } else if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Task { _ = await aÁudioRecorder.start() }
                } else {
                    let text = messageText
                    messageText = ""
                    Task { await viewModel.sendMessage(text: text) }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Theme.primary)
                        .frame(width: 44, height: 44)
                    Image(systemName: aÁudioRecorder.isRecording ? "stop.fill" : (messageText.isEmpty ? "mic.fill" : "paperplane.fill"))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.background)
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
                                    .font(.system(size: 32))
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
                        Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(message.isRead ? .blue : Color.white.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
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
            aÁudioPlayer = player
            player.play()
        } catch {
            print("Erro ao reproduzir Ã¡Áudio: \(error)")
        }
    }

    private func loadParticipant() async {
        do {
            let p: Profile = try await supabase.database
                .from("profiles")
                .select()
                .eq("id", value: viewModel.conversation.participantId)
                .single()
                .execute()
                .value
            
            participantUser = User(id: p.id, name: p.name, cpf: p.document, birthDate: nil, email: p.email ?? "", phone: "", username: p.username, visibleName: p.visible_name, avatarURL: p.avatar_url, location: p.location ?? "Desconhecido", latitude: p.latitude, longitude: p.longitude, memberSince: p.created_at ?? Date(), isProfessional: false, rating: p.rating, responseTime: p.avg_response_time, bio: p.bio, isOnline: p.is_online, lastSeen: p.last_seen)
            participantName = p.visible_name ?? p.name
            participantAvatarURL = p.avatar_url
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