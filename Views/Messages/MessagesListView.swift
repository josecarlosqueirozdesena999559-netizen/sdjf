import SwiftUI

struct MessagesListView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.conversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 64))
                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                        Text("Nenhuma mensagem ainda")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.textPrimary)
                        Text("Quando você iniciar ou receber uma conversa, ela aparecerá aqui.")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.conversations) { conversation in
                            if let user = authViewModel.currentUser {
                                NavigationLink(destination: ChatView(conversation: conversation, currentUser: user)) {
                                    MessageRowView(conversation: conversation)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Divider()
                                    .padding(.leading, 76)
                            }
                        }
                    }
                }
            }
            .background(Theme.background)
            .navigationTitle("Mensagens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { selectedTab = 0 }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Início")
                        }
                        .foregroundColor(Theme.primary)
                    }
                }
            }
            .onAppear {
                if let user = authViewModel.currentUser {
                    Task {
                        await viewModel.fetchConversations(for: user.id)
                    }
                }
            }
        }
    }
}

struct MessageRowView: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Theme.inputBackground)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                    )
                
                // Online badge or similar could go here
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(MockData.users.first(where: { $0.id == conversation.participantId })?.name ?? "Usuário")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Text(Formatters.timeFormatter.string(from: conversation.lastMessage.timestamp))
                        .font(.caption)
                        .foregroundColor(conversation.unreadCount > 0 ? Theme.primary : Theme.textSecondary)
                        .fontWeight(conversation.unreadCount > 0 ? .bold : .regular)
                }
                
                HStack {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.primary)
                    Text(MockData.products.first(where: { $0.id == conversation.productId })?.title ?? "Produto")
                        .font(.caption)
                        .foregroundColor(Theme.primary)
                        .lineLimit(1)
                }
                
                HStack {
                    Text(conversation.lastMessage.text)
                        .font(.subheadline)
                        .foregroundColor(conversation.unreadCount > 0 ? Theme.textPrimary : Theme.textSecondary)
                        .fontWeight(conversation.unreadCount > 0 ? .semibold : .regular)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        ZStack {
                            Circle()
                                .fill(Theme.primary)
                                .frame(width: 22, height: 22)
                            Text("\(conversation.unreadCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(conversation.unreadCount > 0 ? Theme.primary.opacity(0.05) : Color.clear)
    }
}
