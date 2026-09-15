import SwiftUI

struct ProductCard: View {
    var product: Product
    var onFavorite: () -> Void
    @State private var isFavorite: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                // Placeholder para imagem
                Rectangle()
                    .fill(Theme.lightGreen)
                    .aspectRatio(1, contentMode: .fill)
                    .overlay(
                        Image(systemName: "photo.on.rectangle.angled")
                            .foregroundColor(Theme.primary.opacity(0.3))
                            .font(.system(size: 40))
                    )
                    .clipped()
                
                Button(action: {
                    isFavorite.toggle()
                    onFavorite()
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isFavorite ? .red : .white)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(10)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(product.title)
                    .font(AppFont.medium(14))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(2)
                    .frame(height: 38, alignment: .topLeading)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textSecondary)
                    Text("\(product.condition.rawValue) • \(product.location)")
                        .font(AppFont.regular(11))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }
                
                Text(Formatters.formatCurrency(product.price))
                    .font(AppFont.bold(17))
                    .foregroundColor(Theme.primary)
                    .padding(.top, 4)
            }
            .padding(12)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Theme.shadowColor, radius: 10, x: 0, y: 5)
    }
}
