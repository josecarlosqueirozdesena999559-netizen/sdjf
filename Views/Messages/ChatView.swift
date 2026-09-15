import SwiftUI

struct ChatView: View {
    let conversation: Conversation
    @State private var messageText = ""
    @State private var messages: [Message] = []
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(messages) { message in
                        HStack {
                            if message.senderId == UUID() /* Mock current user */ {
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
            
            HStack {
                TextField("Digite uma mensagem...", text: $messageText)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 1))
                
                Button(action: {
                    if !messageText.isEmpty {
                        let newMsg = Message(id: UUID(), senderId: UUID(), receiverId: conversation.participantId, text: messageText, timestamp: Date(), isRead: true)
                        messages.append(newMsg)
                        messageText = ""
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(Theme.primary)
                        .padding()
                }
            }
            .padding()
            .background(Color.white)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(MockData.users.first(where: { $0.id == conversation.participantId })?.name ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            messages = [conversation.lastMessage]
        }
    }
}
