import SwiftUI

struct ConversationsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var activeConversation: Conversation?

    var body: some View {
        ScrollView {
            if appState.conversations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(AppTheme.Colors.textGray)
                    Text("Nenhuma conversa ainda")
                        .font(AppTheme.Typography.headline())
                        .foregroundStyle(AppTheme.Colors.darkGray)
                    Text("Quando der match, você poderá iniciar uma conversa aqui.")
                        .font(AppTheme.Typography.subheadline())
                        .foregroundStyle(AppTheme.Colors.textGray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 80)
                .padding(.horizontal, 24)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(appState.conversations) { conversation in
                        Button {
                            activeConversation = conversation
                        } label: {
                            HStack(spacing: 14) {
                                if let firstPhoto = conversation.profile.photos.first {
                                    PhotoContentView(photo: firstPhoto)
                                        .frame(width: 58, height: 58)
                                        .clipShape(Circle())
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(conversation.profile.firstName)
                                            .font(AppTheme.Typography.headline())
                                            .foregroundStyle(AppTheme.Colors.darkGray)

                                        if conversation.profile.isVerified {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.system(size: 13))
                                                .foregroundStyle(AppTheme.Colors.primaryRed)
                                        }
                                    }

                                    Text(conversation.lastMessage?.text ?? "Diga olá para \(conversation.profile.firstName)!")
                                        .font(AppTheme.Typography.subheadline())
                                        .foregroundStyle(AppTheme.Colors.textGray)
                                        .lineLimit(1)
                                }

                                Spacer()

                                if conversation.unreadCount > 0 {
                                    Circle()
                                        .fill(AppTheme.Colors.primaryRed)
                                        .frame(width: 10, height: 10)
                                }
                            }
                            .padding(14)
                            .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                                    .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .sheet(item: $activeConversation) { conversation in
            ChatDetailView(conversationId: conversation.id, chatService: appState.services.chatService)
        }
    }
}

struct ChatDetailView: View {
    let conversationId: UUID
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    init(conversationId: UUID, chatService: ChatServiceProtocol) {
        self.conversationId = conversationId
        _viewModel = StateObject(wrappedValue: ChatViewModel(chatService: chatService))
    }

    private var conversation: Conversation? {
        appState.conversations.first { $0.id == conversationId }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        if let messages = conversation?.messages, !messages.isEmpty {
                            ForEach(messages) { message in
                                HStack {
                                    if message.senderIsCurrentUser { Spacer(minLength: 48) }

                                    Text(message.text)
                                        .font(AppTheme.Typography.body())
                                        .foregroundStyle(message.senderIsCurrentUser ? .white : AppTheme.Colors.darkGray)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .fill(message.senderIsCurrentUser ? AppTheme.Colors.primaryRed : AppTheme.Colors.white)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .strokeBorder(message.senderIsCurrentUser ? .clear : AppTheme.Colors.borderSubtle, lineWidth: 1)
                                        )

                                    if !message.senderIsCurrentUser { Spacer(minLength: 48) }
                                }
                            }
                        } else {
                            Text("Envie a primeira mensagem!")
                                .font(AppTheme.Typography.subheadline())
                                .foregroundStyle(AppTheme.Colors.textGray)
                                .padding(.top, 48)
                        }
                    }
                    .padding(16)
                }

                HStack(spacing: 10) {
                    TextField("Escreva uma mensagem...", text: $viewModel.draftText)
                        .font(AppTheme.Typography.body())
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                        .background(AppTheme.Colors.white, in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                        )

                    Button {
                        Task {
                            await viewModel.sendMessage(in: conversationId, appState: appState)
                        }
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.Colors.primaryRed, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle(conversation?.profile.firstName ?? "Conversa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.Colors.primaryRed)
                }
            }
        }
    }
}
