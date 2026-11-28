import SwiftUI

enum TrilhaColors {
    static let pureWhite = Color(hex: "#FFFFFF")
    static let surfaceGray = Color(hex: "#F8FAFC")
    static let border = Color(hex: "#E2E8F0")
    static let emerald = Color(hex: "#10B981")
    static let emeraldDark = Color(hex: "#059669")
    static let emeraldSoft = Color(hex: "#D1FAE5")
    static let darkText = Color(hex: "#0F172A")
    static let mutedText = Color(hex: "#64748B")
    static let goldPremium = Color(hex: "#FFB703")
    static let goldSoft = Color(hex: "#FEF3C7")

    // Mapa 3D
    static let mapMintGround = Color(hex: "#BCEBCB")
    static let mapRoadSlate = Color(hex: "#546878")
    static let mapRoadYellow = Color(hex: "#FDE68A")
}

enum TrilhaFont {
    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func metric(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .default).monospacedDigit()
    }
}

struct EmeraldPillButton: View {
    let title: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(TrilhaFont.title(15))
                .tracking(0.8)
                .foregroundStyle(TrilhaColors.pureWhite)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isDisabled
                            ? [Color.gray.opacity(0.45), Color.gray.opacity(0.55)]
                            : [TrilhaColors.emerald, TrilhaColors.emeraldDark],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: TrilhaColors.emerald.opacity(isDisabled ? 0 : 0.28), radius: 10, y: 5)
        }
        .disabled(isDisabled)
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}
