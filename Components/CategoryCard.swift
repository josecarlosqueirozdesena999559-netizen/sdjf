import SwiftUI

struct CategoryCard: View {
    var category: Category
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 68, height: 68)
                    .shadow(color: Theme.shadowColor, radius: 8, x: 0, y: 4)
                
                Image(systemName: category.iconName)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(Theme.primary)
            }
            
            Text(category.name)
                .font(AppFont.medium(12))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 84)
    }
}
