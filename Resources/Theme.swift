import SwiftUI

enum AppTheme {
    enum Colors {
        static let primaryRed = Color(hex: "FF1764")
        static let secondaryRed = Color(hex: "D90E52")
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
        static func jakartaExtraBold(_ size: CGFloat) -> Font {
            .custom("PlusJakartaSans-ExtraBold", size: size)
        }
        static func jakartaBold(_ size: CGFloat) -> Font {
            .custom("PlusJakartaSans-Bold", size: size)
        }
        static func jakartaSemiBold(_ size: CGFloat) -> Font {
            .custom("PlusJakartaSans-SemiBold", size: size)
        }
        static func jakartaRegular(_ size: CGFloat) -> Font {
            .custom("PlusJakartaSans-Regular", size: size)
        }

        static func largeTitle() -> Font { jakartaExtraBold(28) }
        static func title() -> Font { jakartaBold(22) }
        static func headline() -> Font { jakartaSemiBold(17) }
        static func body() -> Font { jakartaRegular(15) }
        static func subheadline() -> Font { jakartaSemiBold(14) }
        static func caption() -> Font { jakartaRegular(12) }
        static func micro() -> Font { jakartaSemiBold(11) }
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
