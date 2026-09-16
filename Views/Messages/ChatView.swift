import SwiftUI

struct ChatView: View {
    let conversation: Conversation
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var messageText = ""
    @State private var messages: [Message] = []
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(messages) { message in
                        HStack {
                            if message.senderId == authViewModel.currentUser?.id || message.senderId == UUID(uuidString: "00000000-0000-0000-0000-000000000000") /* Fallback mock */ {
                                Spacer()
                                Text(message.text)
                                    .padding()
                                    .background(Theme.primary)
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                            } else {
                                Text(message.text)
                                    .padding()
                                    .background(Theme.border)
                                    .foregroundColor(Theme.textPrimary)
                                    .cornerRadius(16)
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            
            HStack(spacing: 12) {
                Button(action: {}) {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.textSecondary)
                }
                
                HStack(spacing: 8) {
                    TextField("Mensagem...", text: $messageText)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                    
                    if messageText.isEmpty {
                        Button(action: {}) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Theme.textSecondary)
                                .padding(.trailing, 12)
                        }
                    } else {
                        Button(action: {
                            if !messageText.isEmpty {
                                let newMsg = Message(id: UUID(), senderId: authViewModel.currentUser?.id ?? UUID(), receiverId: conversation.participantId, text: messageText, timestamp: Date(), isRead: true)
                                messages.append(newMsg)
                                messageText = ""
                            }
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(Theme.primary)
                                .padding(.trailing, 4)
                        }
                    }
                }
                .background(Color.black.opacity(0.05))
                .cornerRadius(20)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.white)
        }
        .background(Theme.background.ignoresSafeArea())
        
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let user = MockData.users.first(where: { $0.id == conversation.participantId }) {
                    NavigationLink(destination: SellerProfileView(seller: Seller(id: UUID(), user: user, isVerified: true, rating: 4.8, reviewCount: 15, salesCount: 30, averageResponseTime: "Responde em 1h", bio: "Vendedor de confiabilidade."))) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Theme.inputBackground)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "person.crop.circle.fill")
                                        .foregroundColor(Theme.textSecondary)
                                )
                            Text(user.visibleName ?? user.name)
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                        }
                    }
                } else {
                    Text("Chat")
                }
            }
        }

        .onAppear {
            messages = [conversation.lastMessage]
        }
    }
}
