import SwiftUI
import AVFoundation

struct ChatView: View {
    @StateObject var viewModel: ChatViewModel
    @State private var messageText = ""
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var participantName = "Usuário"
    @State private var participantAvatarURL: String?
    @State private var audioPlayer: AVPlayer?

    init(conversation: Conversation, currentUser: User) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(conversation: conversation, currentUser: currentUser))
    }

    var body: some View {
        VStack(spacing: 0) {
            chatHeader
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
        .customBackButton()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task { await loadParticipant() }
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
                Text(participantName).font(.subheadline.weight(.semibold))
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(viewModel.otherUserOnline || viewModel.isTyping ? Theme.primary : Theme.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var composer: some View {
        HStack {
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
                    .font(.system(size: 24))
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
        return viewModel.lastSeen == nil ? "visto por último indisponível" : "visto por último hoje"
    }

    @ViewBuilder private func messageBubble(_ message: Message, isMine: Bool) -> some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
            if let path = message.imageName, path.hasSuffix(".m4a") {
                Button { Task { await playAudio(path: path) } } label: {
                    Label("Mensagem de voz", systemImage: "play.fill").padding(12)
                }
            } else {
                Text(message.text).padding(12)
            }
            HStack(spacing: 4) {
                Text(Formatters.timeFormatter.string(from: message.timestamp)).font(.caption2)
                if isMine {
                    Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                        .foregroundColor(message.isRead ? .blue : .secondary)
                }
            }
            .foregroundColor(.secondary)
        }
        .foregroundColor(isMine ? .white : Theme.textPrimary)
        .background(isMine ? Theme.primary : Theme.border)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func playAudio(path: String) async {
        do {
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