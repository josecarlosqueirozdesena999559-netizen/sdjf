import SwiftUI

enum AppTheme {
    enum Colors {
        static let primaryRed = Color(hex: "EA1D2C")
        static let secondaryRed = Color(hex: "FF3344")
        static let white = Color(hex: "FFFFFF")
        static let background = Color(hex: "F6F6F8")
        static let textGray = Color(hex: "85858D")
        static let darkGray = Color(hex: "292932")

        static let inputBackground = Color(hex: "FFFFFF")
        static let borderSubtle = Color(hex: "292932").opacity(0.08)
        static let glassBorder = Color.white.opacity(0.55)
        static let chipUnselected = Color(hex: "EBEBF0")
        static let successGreen = Color(hex: "1F9D55")
        static let warningAmber = Color(hex: "D97706")
    }

    enum Typography {
        static func largeTitle() -> Font { .system(size: 28, weight: .bold, design: .default) }
        static func title() -> Font { .system(size: 22, weight: .bold, design: .default) }
        static func headline() -> Font { .system(size: 17, weight: .semibold, design: .default) }
        static func body() -> Font { .system(size: 15, weight: .regular, design: .default) }
        static func subheadline() -> Font { .system(size: 14, weight: .medium, design: .default) }
        static func caption() -> Font { .system(size: 12, weight: .medium, design: .default) }
        static func micro() -> Font { .system(size: 11, weight: .semibold, design: .default) }
    }

    enum Radius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 14
        static let large: CGFloat = 20
        static let card: CGFloat = 26
        static let pill: CGFloat = 999
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
}
