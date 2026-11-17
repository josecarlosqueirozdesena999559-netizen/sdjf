import SwiftUI

struct InterestChip: View {
    let interest: Interest
    let isSelected: Bool
    var onTap: (() -> Void)? = nil

    var body: some View {
        let chipContent = HStack(spacing: 7) {
            Image(systemName: interest.sfSymbol)
                .font(.system(size: 13, weight: .semibold))
            Text(interest.title)
                .font(AppTheme.Typography.subheadline())
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .foregroundStyle(isSelected ? AppTheme.Colors.white : AppTheme.Colors.darkGray)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.pill, style: .continuous)
                .fill(isSelected ? AppTheme.Colors.primaryRed : AppTheme.Colors.chipUnselected)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.pill, style: .continuous)
                .strokeBorder(
                    isSelected ? AppTheme.Colors.primaryRed : AppTheme.Colors.borderSubtle,
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.18), value: isSelected)

        if let onTap {
            Button(action: onTap) {
                chipContent
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        } else {
            chipContent
        }
    }
}

struct GlassInterestChip: View {
    let interest: Interest

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: interest.sfSymbol)
                .font(.system(size: 11, weight: .semibold))
            Text(interest.title)
                .font(AppTheme.Typography.caption())
                .lineLimit(1)
        }
        .foregroundStyle(AppTheme.Colors.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.8)
        )
    }
}
