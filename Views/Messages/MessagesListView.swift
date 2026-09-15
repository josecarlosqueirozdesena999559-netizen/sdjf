import SwiftUI

struct MessagesListView: View {
    @StateObject private var viewModel = MessagesViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.conversations) { conversation in
                    NavigationLink(destination: ChatView(conversation: conversation)) {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(Theme.lightGreen)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(Theme.primary)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(MockData.users.first(where: { $0.id == conversation.participantId })?.name ?? "Usuário")
                                        .font(.headline)
                                    Spacer()
                                    Text(Formatters.timeFormatter.string(from: conversation.lastMessage.timestamp))
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                }
                                
                                Text(MockData.products.first(where: { $0.id == conversation.productId })?.title ?? "Produto")
                                    .font(.caption)
                                    .foregroundColor(Theme.primary)
                                
                                Text(conversation.lastMessage.text)
                                    .font(.subheadline)
                                    .foregroundColor(conversation.unreadCount > 0 ? Theme.textPrimary : Theme.textSecondary)
                                    .fontWeight(conversation.unreadCount > 0 ? .bold : .regular)
                                    .lineLimit(1)
                            }
                            
                            if conversation.unreadCount > 0 {
                                Circle()
                                    .fill(Theme.primary)
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Mensagens")
            .onAppear {
                viewModel.fetchConversations()
            }
        }
    }
}
