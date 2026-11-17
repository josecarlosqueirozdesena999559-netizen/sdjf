import SwiftUI

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.Radius.large
    var material: Material = .ultraThinMaterial

    func body(content: Content) -> some View {
        content
            .background(material, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.Colors.glassBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 6)
    }
}

struct GlassPillModifier: ViewModifier {
    var material: Material = .ultraThinMaterial

    func body(content: Content) -> some View {
        content
            .background(material, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

struct GlassCircleModifier: ViewModifier {
    var size: CGFloat = 58
    var material: Material = .ultraThinMaterial

    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .background(material, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(AppTheme.Colors.glassBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 5)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = AppTheme.Radius.large, material: Material = .ultraThinMaterial) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, material: material))
    }

    func glassPill(material: Material = .ultraThinMaterial) -> some View {
        modifier(GlassPillModifier(material: material))
    }

    func glassCircle(size: CGFloat = 58, material: Material = .ultraThinMaterial) -> some View {
        modifier(GlassCircleModifier(size: size, material: material))
    }
}
