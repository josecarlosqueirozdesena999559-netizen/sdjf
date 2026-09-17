import SwiftUI

struct FlatCategoryCard: View {
    var category: Category
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.inputBackground)
                    .frame(width: 60, height: 60)
                
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundColor(Theme.primary)
            }
            
            Text(category.name)
                .font(.caption)
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
        }
    }
}

struct FlatProductCard: View {
    var product: Product
    
    var seller: Seller? {
        MockData.sellers.first { $0.user.id == product.sellerId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Navigate to Product Detail when tapping the main card content
            NavigationLink(destination: ProductDetailView(product: product)) {
                VStack(alignment: .leading, spacing: 8) {
                    Rectangle()
                        .fill(Theme.inputBackground)
                        .aspectRatio(1, contentMode: .fill)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray.opacity(0.5))
                                .font(.system(size: 40))
                        )
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.title)
                            .font(.subheadline)
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(2)
                        
                        Text("\(product.condition.rawValue) • \(product.location)")
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)
                        HStack {
                            Text(Formatters.formatCurrency(product.price))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.primary)
                                
                            Spacer()
                            
                            HStack(spacing: 2) {
                                Image("lucide_eye")
                                    .resizable()
                                    .renderingMode(.template)
                                    .scaledToFit()
                                    .frame(width: 12, height: 12)
                                    .foregroundColor(Theme.textSecondary)
                                Text("\(product.views)")
                                    .font(.caption2)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Navigate to Seller Profile when tapping the seller info
            if let seller = seller {
                NavigationLink(destination: SellerProfileView(seller: seller)) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.lightGreen)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.primary)
                            )
                        
                        Text("Vendido por \(seller.user.visibleName ?? seller.user.name)")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)
                    }
                    .padding(.top, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color.white)
    }
}
