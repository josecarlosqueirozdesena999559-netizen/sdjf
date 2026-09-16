import SwiftUI

struct ChatView: View {
    let conversation: Conversation
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @State private var chatStatus: String = "online"
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(messages) { message in
                        HStack {
                            if message.senderId == authViewModel.currentUser?.id || message.senderId == UUID(uuidString: "00000000-0000-0000-0000-000000000000") /* Fallback mock */ {
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(message.text)
                                        .padding()
                                        .background(Theme.primary)
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                    
                                    HStack(spacing: 4) {
                                        Text(Formatters.timeFormatter.string(from: message.timestamp))
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                        
                                        // WhatsApp style ticks
                                        HStack(spacing: -4) {
                                            Image(systemName: "checkmark")
                                            Image(systemName: "checkmark")
                                        }
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(message.isRead ? .blue : .gray)
                                    }
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(message.text)
                                        .padding()
                                        .background(Theme.border)
                                        .foregroundColor(Theme.textPrimary)
                                        .cornerRadius(16)
                                    
                                    Text(Formatters.timeFormatter.string(from: message.timestamp))
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
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
                                // Initially sent as unread (gray ticks)
                                let newMsg = Message(id: UUID(), senderId: authViewModel.currentUser?.id ?? UUID(), receiverId: conversation.participantId, text: messageText, timestamp: Date(), isRead: false)
                                messages.append(newMsg)
                                messageText = ""
                                
                                // Mock behavior for status and auto-reply
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    chatStatus = "online"
                                    // Mark all our messages as read (blue ticks) when they come online
                                    for i in 0..<messages.count {
                                        if messages[i].senderId != conversation.participantId {
                                            messages[i].isRead = true
                                        }
                                    }
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    chatStatus = "digitando..."
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                                    let formatter = DateFormatter()
                                    formatter.timeStyle = .short
                                    let timeString = formatter.string(from: Date())
                                    
                                    messages.append(Message(id: UUID(), senderId: conversation.participantId, receiverId: authViewModel.currentUser?.id ?? UUID(), text: "Certo! Podemos fechar negócio.", timestamp: Date(), isRead: true))
                                    chatStatus = "online"
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                        chatStatus = "visto por último hoje às \(timeString)"
                                    }
                                }
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
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.visibleName ?? user.name)
                                    .font(.headline)
                                    .foregroundColor(Theme.textPrimary)
                                
                                Text(chatStatus)
                                    .font(.caption)
                                    .foregroundColor(chatStatus == "online" || chatStatus == "digitando..." ? Theme.primary : Theme.textSecondary)
                            }
                        }
                    }
                } else {
                    Text("Chat")
                }
            }
        }

        .onAppear {
            messages = [conversation.lastMessage]
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let timeString = formatter.string(from: Date().addingTimeInterval(-1800)) // 30 mins ago
            chatStatus = "visto por último hoje às \(timeString)"
        }
    }
}
