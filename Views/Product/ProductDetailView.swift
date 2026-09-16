import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    
    var seller: Seller? {
        MockData.sellers.first { $0.user.id == product.sellerId }
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
                    
                    Text("Descrição")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(product.description)
                        .font(.body)
                        .foregroundColor(Theme.textSecondary)
                    
                    Divider()
                    
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
        .overlay(
            VStack {
                Spacer()
                HStack(spacing: 16) {
                    NavigationLink(destination: ChatView(conversation: Conversation(
                        id: UUID(),
                        productId: product.id,
                        participantId: product.sellerId,
                        lastMessage: Message(
                            id: UUID(),
                            senderId: product.sellerId,
                            receiverId: UUID(),
                            text: "Olá! Gostaria de tirar dúvidas sobre o produto \(product.title).",
                            timestamp: Date(),
                            isRead: true
                        ),
                        unreadCount: 0
                    ))) {
                        Text("Mensagem")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Theme.primary)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.primary, lineWidth: 2))
                    }
                    
                    NavigationLink(destination: ChatView(conversation: Conversation(
                        id: UUID(),
                        productId: product.id,
                        participantId: product.sellerId,
                        lastMessage: Message(
                            id: UUID(),
                            senderId: product.sellerId,
                            receiverId: UUID(),
                            text: "Olá! Gostaria de comprar o produto \(product.title).",
                            timestamp: Date(),
                            isRead: true
                        ),
                        unreadCount: 0
                    ))) {
                        Text("Comprar")
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
            , alignment: .bottom
        )
    }
}
