import SwiftUI

enum Typography {
    static let display = Font.custom("Inter-Bold", size: 34, relativeTo: .largeTitle)
    static let screenTitle = Font.custom("Inter-Bold", size: 26, relativeTo: .title)
    static let subtitle = Font.custom("Inter-SemiBold", size: 20, relativeTo: .title3)
    static let sectionTitle = Font.custom("Inter-SemiBold", size: 17, relativeTo: .headline)
    static let body = Font.custom("Inter-Regular", size: 15, relativeTo: .body)
    static let bodySecondary = Font.custom("Inter-Regular", size: 13, relativeTo: .subheadline)
    static let label = Font.custom("Inter-Medium", size: 13, relativeTo: .callout)
    static let button = Font.custom("Inter-SemiBold", size: 15, relativeTo: .subheadline)
    static let caption = Font.custom("Inter-Regular", size: 11.5, relativeTo: .caption)
}

struct TypographyModifier: ViewModifier {
    let font: Font
    let tracking: CGFloat
    let lineSpacing: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(font)
            .tracking(tracking)
            .lineSpacing(lineSpacing)
    }
}

extension View {
    func typographyDisplay() -> some View { self.modifier(TypographyModifier(font: Typography.display, tracking: -0.8, lineSpacing: 4)) }
    func typographyScreenTitle() -> some View { self.modifier(TypographyModifier(font: Typography.screenTitle, tracking: -0.5, lineSpacing: 4)) }
    func typographySubtitle() -> some View { self.modifier(TypographyModifier(font: Typography.subtitle, tracking: -0.3, lineSpacing: 4)) }
    func typographySectionTitle() -> some View { self.modifier(TypographyModifier(font: Typography.sectionTitle, tracking: 0, lineSpacing: 4)) }
    func typographyBody() -> some View { self.modifier(TypographyModifier(font: Typography.body, tracking: 0, lineSpacing: 6)) }
    func typographyBodySecondary() -> some View { self.modifier(TypographyModifier(font: Typography.bodySecondary, tracking: 0, lineSpacing: 5)) }
    func typographyLabel() -> some View { self.modifier(TypographyModifier(font: Typography.label, tracking: 0.1, lineSpacing: 3)) }
    func typographyButton() -> some View { self.modifier(TypographyModifier(font: Typography.button, tracking: 0.2, lineSpacing: 3)) }
    func typographyCaption() -> some View { self.modifier(TypographyModifier(font: Typography.caption, tracking: 0, lineSpacing: 2)) }
}