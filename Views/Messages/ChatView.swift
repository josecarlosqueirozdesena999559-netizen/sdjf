import SwiftUI
import PhotosUI

struct ChatView: View {
    @StateObject var viewModel: ChatViewModel
    @State private var messageText = ""
    @State private var selectedAttachment: PhotosPickerItem? = nil
    @State private var isRecordingAudio = false
    
    @State private var showRatingSheet = false
    @State private var selectedStars = 0
    @State private var ratingFeedback = ""
    @State private var showRatingSuccess = false
    
    init(conversation: Conversation, currentUser: User) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(conversation: conversation, currentUser: currentUser))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // BANNER DE AVALIAÇÃO - Movido para fora da NavigationBar
            Button(action: {
                showRatingSheet = true
            }) {
                HStack(spacing: 8) {
                    Image("lucide_star").resizable().renderingMode(.template).frame(width: 18, height: 18)
                        .font(.system(size: 18))
                    Text("Avaliar Vendedor")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Image("lucide_chevron-right").resizable().renderingMode(.template).frame(width: 14, height: 14)
                        .font(.caption)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.yellow.opacity(0.15))
                .foregroundColor(.orange)
            }
            
            Divider()
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        HStack {
                            if message.senderId == viewModel.currentUser.id {
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    if message.imageName != nil {
                                        Rectangle()
                                            .fill(Theme.lightGreen)
                                            .frame(width: 200, height: 150)
                                            .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(Theme.primary))
                                            .cornerRadius(12)
                                    } else {
                                        Text(message.text)
                                            .padding()
                                            .background(Theme.primary)
                                            .foregroundColor(.white)
                                            .cornerRadius(16)
                                    }
                                    
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
                                    if message.text.contains("🎤") {
                                        HStack {
                                            Image(systemName: "play.fill")
                                                .foregroundColor(Theme.primary)
                                            AudioWaveView()
                                                .frame(height: 20)
                                                .padding(.horizontal, 8)
                                            Text("0:12")
                                                .font(.caption)
                                                .foregroundColor(Theme.textPrimary)
                                        }
                                        .padding()
                                        .background(Theme.border)
                                        .cornerRadius(16)
                                    } else {
                                        Text(message.text)
                                            .padding()
                                            .background(Theme.border)
                                            .foregroundColor(Theme.textPrimary)
                                            .cornerRadius(16)
                                    }
                                    
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
                PhotosPicker(selection: $selectedAttachment, matching: .any(of: [.images, .videos])) {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.textSecondary)
                }
                .onChange(of: selectedAttachment) { _ in
                    if selectedAttachment != nil {
                        Task {
                            await viewModel.sendMessage(text: "📷 Mídia", mediaUrl: "mock_image")
                        }
                        selectedAttachment = nil
                    }
                }
                
                HStack(spacing: 8) {
                    if isRecordingAudio {
                        AudioWaveView()
                            .frame(height: 40)
                            .padding(.horizontal)
                        Spacer()
                    } else {
                        TextField("Mensagem...", text: $messageText)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .onChange(of: messageText) { _ in
                                viewModel.sendTypingEvent()
                            }
                    }
                    
                    if messageText.isEmpty {
                        Button(action: {
                            if isRecordingAudio {
                                Task {
                                    await viewModel.sendMessage(text: "🎤 Mensagem de Voz")
                                }
                                isRecordingAudio = false
                            } else {
                                isRecordingAudio = true
                            }
                        }) {
                            Image(systemName: isRecordingAudio ? "paperplane.fill" : "mic.fill")
                                .font(.system(size: 20))
                                .foregroundColor(isRecordingAudio ? Theme.primary : Theme.textSecondary)
                                .padding(.trailing, 12)
                        }
                    } else {
                        Button(action: {
                            if !messageText.isEmpty {
                                let text = messageText
                                messageText = ""
                                Task {
                                    await viewModel.sendMessage(text: text)
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
        
        .customBackButton()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let user = MockData.users.first(where: { $0.id == viewModel.conversation.participantId }) {
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
                                
                                let statusText = viewModel.isTyping ? "digitando..." : (viewModel.otherUserOnline ? "online" : (viewModel.lastSeen != nil ? "visto por último hoje" : "offline"))
                                Text(statusText)
                                    .font(.caption)
                                    .foregroundColor(viewModel.isTyping || viewModel.otherUserOnline ? Theme.primary : Theme.textSecondary)
                            }
                        }
                    }
                } else {
                    Text("Chat")
                }
            }
            // Removed trailing icon from here.
        }
        .sheet(isPresented: $showRatingSheet) {
            VStack(spacing: 24) {
                Text("Avaliar Vendedor")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Como foi sua experiência com este vendedor?")
                    .multilineTextAlignment(.center)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal)
                
                HStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= selectedStars ? "star.fill" : "star")
                            .font(.system(size: 40))
                            .foregroundColor(star <= selectedStars ? .yellow : Theme.textSecondary.opacity(0.3))
                            .onTapGesture {
                                selectedStars = star
                            }
                    }
                }
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $ratingFeedback)
                        .frame(height: 100)
                        .padding(8)
                        .background(Theme.inputBackground)
                        .cornerRadius(12)
                    
                    if ratingFeedback.isEmpty {
                        Text("Deixe um comentário (opcional)...")
                            .foregroundColor(Theme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal)
                
                Button(action: {
                    showRatingSheet = false
                    showRatingSuccess = true
                }) {
                    Text("Enviar Avaliação")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedStars > 0 ? Theme.primary : Theme.textSecondary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .disabled(selectedStars == 0)
                
                Spacer()
            }
            .padding(.top, 40)
            .presentationDetents([.fraction(0.55)])
        }
        .alert("Avaliação Enviada", isPresented: $showRatingSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Muito obrigado! Sua avaliação ajuda a manter a comunidade segura e confiável.")
        }
        .onAppear {
            // ChatViewModel takes care of fetching messages
        }
    }
}

struct AudioWaveView: View {
    @State private var drawingHeight = true
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<10, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.primary)
                    .frame(width: 4, height: drawingHeight ? CGFloat.random(in: 10...30) : CGFloat.random(in: 10...30))
                    .animation(
                        Animation.easeInOut(duration: 0.2)
                            .repeatForever()
                            .delay(Double(index) * 0.05),
                        value: drawingHeight
                    )
            }
        }
        .onAppear {
            drawingHeight.toggle()
        }
    }
}
