import SwiftUI

struct Theme {
    static let primary = Color(hex: "159A68")
    static let darkGreen = Color(hex: "087A53")
    static let lightGreen = Color(hex: "EAF7F1")
    static let background = Color.white // Fundo branco como na imagem original
    static let textPrimary = Color.primary
    static let textSecondary = Color.gray
    static let border = Color(hex: "E5E7EB")
    static let error = Color.red
    static let inputBackground = Color(hex: "F3F4F6")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: 
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: 
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: 
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


struct AppFont {
    static func regular(_ size: CGFloat) -> Font { .system(size: size) }
    static func medium(_ size: CGFloat) -> Font { .system(size: size, weight: .medium) }
    static func semibold(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold) }
    static func bold(_ size: CGFloat) -> Font { .system(size: size, weight: .bold) }
}
