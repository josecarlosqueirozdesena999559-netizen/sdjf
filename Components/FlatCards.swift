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
    
    var body: some View {
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
                
                Text(Formatters.formatCurrency(product.price))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.primary)
            }
        }
        .background(Color.white)
    }
}
