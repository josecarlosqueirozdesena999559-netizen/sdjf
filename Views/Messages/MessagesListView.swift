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
                            .font(.system(size: 48))
                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                        Text("Nenhuma mensagem ainda")
                            .font(.custom("Inter-SemiBold", size: 20, relativeTo: .title3))
                            
                            .foregroundColor(Theme.textPrimary)
                        Text("Quando você iniciar ou receber uma conversa, ela aparecerá aqui.")
                            .font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline))
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
            .task(id: authViewModel.currentUser?.id) {
                guard let userID = authViewModel.currentUser?.id else { return }
                while !Task.isCancelled {
                    await viewModel.fetchConversations(for: userID)
                    try? await Task.sleep(for: .seconds(2))
                }
            }
        }
    }
}

struct MessageRowView: View {
    let conversation: Conversation
    @State private var participantName = "Usuário"
    @State private var productTitle = "Produto"
    
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
                    Text(participantName)
                        .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Text(Formatters.timeFormatter.string(from: conversation.lastMessage.timestamp))
                        .font(.custom("Inter-Regular", size: 12, relativeTo: .caption))
                        .foregroundColor(conversation.unreadCount > 0 ? Theme.primary : Theme.textSecondary)
                        .fontWeight(conversation.unreadCount > 0 ? .bold : .regular)
                }
                
                HStack {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.primary)
                    Text(productTitle)
                        .font(.custom("Inter-Regular", size: 12, relativeTo: .caption))
                        .foregroundColor(Theme.primary)
                        .lineLimit(1)
                }
                
                HStack {
                    Text(conversation.lastMessage.text)
                        .font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline))
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
                                .font(.custom("Inter-Regular", size: 11, relativeTo: .caption2))
                                
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(conversation.unreadCount > 0 ? Theme.primary.opacity(0.05) : Color.clear)        .task {
            struct ProfileName: Codable { let visible_name: String?; let name: String }
            struct ProductName: Codable { let title: String }
            if let profile: ProfileName = try? await supabase.database.from("profiles").select("name,visible_name").eq("id", value: conversation.participantId).single().execute().value { participantName = profile.visible_name ?? profile.name }
            if let product: ProductName = try? await supabase.database.from("products").select("title").eq("id", value: conversation.productId).single().execute().value { productTitle = product.title }
        }
    }
}
