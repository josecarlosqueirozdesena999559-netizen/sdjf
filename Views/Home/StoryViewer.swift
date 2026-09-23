import SwiftUI

struct StoryViewer: View {
    let profile: Profile
    let stories: [Story]
    let onDismiss: () -> Void
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var currentIndex = 0
    @State private var progress: CGFloat = 0
    @State private var timer: Timer?
    @State private var commentText = ""
    @State private var isSendingComment = false
    
    private let storyDuration: TimeInterval = 30.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if !stories.isEmpty {
                // Image layer
                AsyncImage(url: URL(string: stories[currentIndex].mediaUrl)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        ProgressView().tint(.white)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Tap areas for navigation
                HStack(spacing: 0) {
                    Color.white.opacity(0.001)
                        .onTapGesture {
                            if currentIndex > 0 {
                                currentIndex -= 1
                                resetTimer()
                            } else {
                                onDismiss()
                            }
                        }
                    
                    Color.white.opacity(0.001)
                        .onTapGesture {
                            if currentIndex < stories.count - 1 {
                                currentIndex += 1
                                resetTimer()
                            } else {
                                onDismiss()
                            }
                        }
                }
                
                VStack {
                    // Progress Bars
                    HStack(spacing: 4) {
                        ForEach(0..<stories.count, id: \.self) { index in
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.3))
                                    if index < currentIndex {
                                        Capsule().fill(Color.white)
                                    } else if index == currentIndex {
                                        Capsule().fill(Color.white)
                                            .frame(width: geo.size.width * progress)
                                    }
                                }
                            }
                            .frame(height: 3)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 44)
                    
                    // Header
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: profile.avatar_url ?? "")) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Image(systemName: "person.crop.circle.fill").resizable().foregroundColor(.gray)
                            }
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        Text(profile.visible_name ?? profile.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Comment input (if not own story)
                    if profile.id != authViewModel.currentUser?.id {
                        HStack {
                            TextField("Responder...", text: $commentText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.black.opacity(0.5))
                                .foregroundColor(.white)
                                .cornerRadius(24)
                                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.5), lineWidth: 1))
                            
                            if !commentText.isEmpty {
                                Button(action: {
                                    Task { await sendComment() }
                                }) {
                                    if isSendingComment {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: "paperplane.fill")
                                            .foregroundColor(.white)
                                            .padding(10)
                                            .background(Theme.primary)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        progress = 0
        let interval = 0.05
        let step = CGFloat(interval / storyDuration)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            if self.progress < 1.0 {
                self.progress += step
            } else {
                if self.currentIndex < self.stories.count - 1 {
                    self.currentIndex += 1
                    self.progress = 0
                } else {
                    self.timer?.invalidate()
                    self.onDismiss()
                }
            }
        }
    }
    
    private func resetTimer() {
        startTimer()
    }
    
    private func sendComment() async {
        guard let currentUser = authViewModel.currentUser, !commentText.isEmpty else { return }
        isSendingComment = true
        defer { isSendingComment = false; onDismiss() } // Fechar dps de mandar
        
        do {
            // Find or create conversation
            struct ConversationRow: Codable { let id: UUID; let buyer_id: UUID; let seller_id: UUID; let product_id: UUID? }
            let allConvs: [ConversationRow] = try await supabase.database.from("conversations").select().execute().value
            let existing = allConvs.first(where: {
                ($0.buyer_id == currentUser.id && $0.seller_id == profile.id) ||
                ($0.buyer_id == profile.id && $0.seller_id == currentUser.id)
            })
            
            let convId: UUID
            if let e = existing {
                convId = e.id
            } else {
                convId = UUID()
                let insert = ConversationRow(id: convId, buyer_id: currentUser.id, seller_id: profile.id, product_id: nil)
                try await supabase.database.from("conversations").insert(insert).execute()
            }
            
            struct MsgInsert: Codable {
                let id: UUID
                let conversation_id: UUID
                let sender_id: UUID
                let text: String
                let media_url: String?
                let is_read: Bool
            }
            let msgId = UUID()
            let insertData = MsgInsert(id: msgId, conversation_id: convId, sender_id: currentUser.id, text: "Respondendo ao story: " + commentText, media_url: nil, is_read: false)
            try await supabase.database.from("messages").insert(insertData).execute()
            
        } catch {
            print("Failed to send comment: \(error)")
        }
    }
}
