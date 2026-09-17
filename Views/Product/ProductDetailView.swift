import SwiftUI

struct ProductOffer: Identifiable {
    let id = UUID()
    let bidderName: String
    let bidderId: UUID
    let amount: Double
    let time: Date
}

struct ProductDetailView: View {
    let product: Product
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var offers: [ProductOffer] = []
    @State private var offerAmount: String = ""
    
    var seller: Seller? {
        MockData.sellers.first { $0.user.id == product.sellerId }
    }
    
    var isOwner: Bool {
        authViewModel.currentUser?.id == product.sellerId
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Image Placeholder
                Rectangle()
                    .fill(Theme.lightGreen)
                    .frame(height: 300)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(Theme.primary.opacity(0.5))
                    )
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(product.condition.rawValue) • \(Formatters.dateFormatter.string(from: product.createdAt))")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    
                    Text(product.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text(Formatters.formatCurrency(product.price))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.primary)
                    
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                        Text(product.location)
                    }
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    
                    Divider()
                    
                    // NEW: IMPROVED DESCRIPTION
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(Theme.primary)
                            Text("Descrição do Produto")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        
                        Text(product.description)
                            .font(.body)
                            .foregroundColor(Theme.textSecondary)
                            .lineSpacing(4)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.inputBackground)
                            .cornerRadius(12)
                    }
                    
                    Divider()
                    
                    // NEW: NEGOTIATION / BIDS SECTION
                    if product.acceptsNegotiation {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "hand.thumbsup.fill")
                                    .foregroundColor(Theme.primary)
                                Text("Negociação e Lances")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            
                            if isOwner {
                                Text("Como dono deste anúncio, você pode ver os lances e iniciar uma negociação.")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                                
                                if offers.isEmpty {
                                    Text("Nenhum lance recebido ainda.")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.textSecondary)
                                        .padding()
                                } else {
                                    ForEach(offers) { offer in
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(offer.bidderName)
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                Text(Formatters.formatCurrency(offer.amount))
                                                    .foregroundColor(Theme.primary)
                                                    .fontWeight(.bold)
                                            }
                                            Spacer()
                                            
                                            NavigationLink(destination: ChatView(conversation: Conversation(
                                                id: UUID(),
                                                productId: product.id,
                                                participantId: offer.bidderId,
                                                lastMessage: Message(id: UUID(), senderId: product.sellerId, receiverId: offer.bidderId, text: "Olá! Vi seu lance de \(Formatters.formatCurrency(offer.amount)). Vamos negociar?", timestamp: Date(), isRead: true),
                                                unreadCount: 0
                                            ), currentUser: authViewModel.currentUser ?? User(id: UUID(), name: "Visitante", email: "", phone: "", location: "", memberSince: Date(), isProfessional: false))) {
                                                Text("Negociar")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Theme.primary)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(8)
                                            }
                                        }
                                        .padding()
                                        .background(Theme.inputBackground)
                                        .cornerRadius(8)
                                    }
                                }
                            } else {
                                // If not owner, user can place bids
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("R$")
                                            .foregroundColor(Theme.textSecondary)
                                            .fontWeight(.bold)
                                        TextField("0,00", text: $offerAmount)
                                            .keyboardType(.decimalPad)
                                            .font(.headline)
                                        
                                        Button(action: {
                                            if let amount = Double(offerAmount.replacingOccurrences(of: ",", with: ".")) {
                                                let newOffer = ProductOffer(bidderName: authViewModel.currentUser?.name ?? "Você", bidderId: authViewModel.currentUser?.id ?? UUID(), amount: amount, time: Date())
                                                offers.append(newOffer)
                                                offerAmount = ""
                                            }
                                        }) {
                                            Text("Enviar Lance")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(offerAmount.isEmpty ? Theme.textSecondary : Theme.primary)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                        .disabled(offerAmount.isEmpty)
                                    }
                                    .padding()
                                    .background(Theme.inputBackground)
                                    .cornerRadius(8)
                                    
                                    if !offers.filter({ $0.bidderId == authViewModel.currentUser?.id }).isEmpty {
                                        Text("Seus lances:")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .padding(.top, 4)
                                        
                                        ForEach(offers.filter({ $0.bidderId == authViewModel.currentUser?.id })) { offer in
                                            HStack {
                                                Text("Você ofereceu:")
                                                    .font(.caption)
                                                    .foregroundColor(Theme.textSecondary)
                                                Spacer()
                                                Text(Formatters.formatCurrency(offer.amount))
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(Theme.primary)
                                            }
                                            .padding()
                                            .background(Theme.inputBackground.opacity(0.5))
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                        
                        Divider()
                    }
                    
                    if let seller = seller {
                        Text("Sobre o vendedor")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        NavigationLink(destination: SellerProfileView(seller: seller)) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Theme.lightGreen)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(String(seller.user.name.prefix(1)))
                                            .foregroundColor(Theme.primary)
                                            .font(.headline)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(seller.user.name)
                                            .font(.headline)
                                            .foregroundColor(Theme.textPrimary)
                                        if seller.isVerified {
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundColor(.blue)
                                                .font(.caption)
                                        }
                                    }
                                    
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text(String(format: "%.1f", seller.rating))
                                        Text("(\(seller.reviewCount))")
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                    .font(.caption)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .customBackButton()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    favoritesViewModel.toggleFavorite(product: product)
                }) {
                    Image(systemName: favoritesViewModel.isFavorite(product) ? "heart.fill" : "heart")
                        .foregroundColor(favoritesViewModel.isFavorite(product) ? Theme.primary : Theme.textPrimary)
                }
            }
        }
        .onAppear {
            if offers.isEmpty && isOwner {
                // Mock some initial offers for demonstration to the owner
                offers = [
                    ProductOffer(bidderName: "Carlos Silva", bidderId: UUID(), amount: product.price * 0.9, time: Date()),
                    ProductOffer(bidderName: "Amanda Costa", bidderId: UUID(), amount: product.price * 0.85, time: Date())
                ]
            }
            
            // Increment view count in Supabase (unique per user)
            Task {
                guard let userId = authViewModel.currentUser?.id else { return }
                do {
                    struct IncrementParams: Codable {
                        let p_product_id: UUID
                        let p_user_id: UUID
                    }
                    let params = IncrementParams(p_product_id: product.id, p_user_id: userId)
                    try await supabase.database.rpc("increment_product_views", params: params).execute()
                } catch {
                    print("Failed to increment views: \(error)")
                }
            }
        }
        .overlay(
            VStack {
                Spacer()
                if !isOwner {
                    HStack(spacing: 16) {
                        NavigationLink(destination: ChatView(conversation: Conversation(
                            id: UUID(),
                            productId: product.id,
                            participantId: product.sellerId,
                            lastMessage: Message(
                                id: UUID(),
                                senderId: authViewModel.currentUser?.id ?? UUID(),
                                receiverId: product.sellerId,
                                text: "Olá! Gostaria de conversar sobre o produto \(product.title).",
                                timestamp: Date(),
                                isRead: true
                            ),
                            unreadCount: 0
                                            ), currentUser: authViewModel.currentUser ?? User(id: UUID(), name: "Visitante", email: "", phone: "", location: "", memberSince: Date(), isProfessional: false))) {
                            Text("Conversar com vendedor")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.primary)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.white.shadow(color: Color.black.opacity(0.1), radius: 10, y: -5))
                }
            }
            , alignment: .bottom
        )
    }
}
