import SwiftUI

/// Reserved brand configuration.
/// Intentionally left without a name or logo so the final brand identity can be plugged in later.
enum BrandIdentitySlot {
    static let appName: String? = nil
    static let logoImageName: String? = nil
}

/// Reserved slot in the top header for the future logo.
struct ReservedLogoSlot: View {
    var body: some View {
        Group {
            if let logoName = BrandIdentitySlot.logoImageName {
                Image(logoName)
                    .resizable()
                    .scaledToFit()
            } else {
                // Intentionally neutral reserved space for future brand mark
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                    )
            }
        }
        .frame(width: 36, height: 36)
        .accessibilityHidden(BrandIdentitySlot.logoImageName == nil)
    }
}

/// Reserved slot in the center of the top header for the future app name.
struct ReservedAppNameSlot: View {
    var body: some View {
        Group {
            if let name = BrandIdentitySlot.appName {
                Text(name)
                    .font(AppTheme.Typography.headline())
                    .foregroundStyle(AppTheme.Colors.darkGray)
            } else {
                // Intentionally empty space reserved for future app name
                Color.clear
                    .frame(width: 120, height: 22)
            }
        }
        .accessibilityHidden(BrandIdentitySlot.appName == nil)
    }
}
