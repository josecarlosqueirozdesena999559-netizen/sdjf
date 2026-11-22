import SwiftUI

// MARK: - Paleta de Cores Flat Clara (Juntô)
enum JuntoColors {
    static let primary = Color(hex: "#4F46E5")
    static let primaryHover = Color(hex: "#4338CA")
    static let primaryLight = Color(hex: "#EEF2FF")
    static let secondary = Color(hex: "#10B981")
    static let secondaryLight = Color(hex: "#ECFDF5")
    static let accent = Color(hex: "#F59E0B")
    static let accentLight = Color(hex: "#FFFBEB")
    static let danger = Color(hex: "#EF4444")
    static let dangerLight = Color(hex: "#FEF2F2")

    static let bgMain = Color(hex: "#F8FAFC")
    static let surface = Color.white
    static let surfaceSubtle = Color(hex: "#F1F5F9")
    static let border = Color(hex: "#E2E8F0")

    static let textMain = Color(hex: "#0F172A")
    static let textMuted = Color(hex: "#64748B")
    static let textLight = Color(hex: "#94A3B8")
}

// MARK: - Fonte Inter (com fallback seguro)
extension Font {
    static func inter(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .medium: name = "Inter-Medium"
        case .semibold: name = "Inter-SemiBold"
        case .bold: name = "Inter-Bold"
        case .heavy, .black: name = "Inter-ExtraBold"
        default: name = "Inter-Regular"
        }
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight, design: .default)
    }
}

// MARK: - Helper Hex Color
extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (79, 70, 229)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: 1
        )
    }
}

// MARK: - Inputs Flat Modernos (Cantos Quadrados Lapidados)
struct FlatInputField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var leadingPrefix: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !label.isEmpty {
                Text(label)
                    .font(.inter(13, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)
            }

            HStack(spacing: 6) {
                if let prefix = leadingPrefix {
                    Text(prefix)
                        .font(.inter(15, weight: .bold))
                        .foregroundColor(JuntoColors.primary)
                }
                TextField(placeholder, text: $text)
                    .font(.inter(14, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(JuntoColors.bgMain)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(JuntoColors.border, lineWidth: 1.2)
            )
            .cornerRadius(8)
        }
    }
}

struct FlatSecureField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.inter(13, weight: .semibold))
                .foregroundColor(JuntoColors.textMain)

            HStack {
                if isVisible {
                    TextField(placeholder, text: $text)
                        .font(.inter(14, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField(placeholder, text: $text)
                        .font(.inter(14, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                }

                Button {
                    isVisible.toggle()
                } label: {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .font(.system(size: 15))
                        .foregroundColor(JuntoColors.textMuted)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(JuntoColors.bgMain)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(JuntoColors.border, lineWidth: 1.2)
            )
            .cornerRadius(8)
        }
    }
}

// MARK: - Botões Flat
struct JuntoPrimaryButton: View {
    let title: String
    var icon: String? = "arrow.right"
    var color: Color = JuntoColors.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.inter(15, weight: .semibold))
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(color)
            .cornerRadius(10)
        }
    }
}

struct JuntoSecondaryButton: View {
    let title: String
    var color: Color = JuntoColors.textMain
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.inter(14, weight: .semibold))
                .foregroundColor(color)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(JuntoColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(JuntoColors.border, lineWidth: 1.2)
                )
                .cornerRadius(10)
        }
    }
}
