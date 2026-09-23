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
            return "Visto por último: \(df.string(from: last))"
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
            .frame(width: 52, height: 52)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(participantName).font(.custom("Inter-Bold", size: 20))
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
            Spacer()
        }
    }

    private func loadParticipant() async {
        do {
            let profile: User = try await supabase.database
                .from("profiles")
                .select()
                .eq("id", value: viewModel.conversation.participantId)
                .single()
                .execute()
                .value
            participantUser = profile
            participantName = profile.visibleName ?? profile.name
            participantAvatarURL = profile.avatarURL
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