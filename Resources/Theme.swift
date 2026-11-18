import SwiftUI
import UIKit

enum AppTheme {
    private static func dynamic(lightHex: String, darkHex: String) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: darkHex)) : UIColor(Color(hex: lightHex))
        })
    }

    enum Colors {
        static let primaryRed = Color(hex: "FF1764")
        static let secondaryRed = Color(hex: "D90E52")
        static let white = dynamic(lightHex: "FFFFFF", darkHex: "1C1C22")
        static let background = dynamic(lightHex: "F6F6F8", darkHex: "0F0F13")
        static let textGray = dynamic(lightHex: "85858D", darkHex: "9E9EA8")
        static let darkGray = dynamic(lightHex: "292932", darkHex: "F4F4F7")

        static let inputBackground = dynamic(lightHex: "FFFFFF", darkHex: "1C1C22")
        static let borderSubtle = Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.12)
                : UIColor(Color(hex: "292932")).withAlphaComponent(0.08)
        })
        static let glassBorder = Color.white.opacity(0.55)
        static let chipUnselected = dynamic(lightHex: "EBEBF0", darkHex: "2A2A33")
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
