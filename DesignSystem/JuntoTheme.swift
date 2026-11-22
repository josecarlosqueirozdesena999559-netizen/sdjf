import SwiftUI

// MARK: - Paleta Minimalista & Limpa (Juntô)
enum JuntoColors {
    static let primary = Color(hex: "#1B7F6B")         // Esmeralda calmo & financeiro
    static let primaryLight = Color(hex: "#E6F5F1")
    static let primaryMint = Color(hex: "#9CE2D2")
    static let darkButton = Color(hex: "#1E2022")      // Grafite elegante (Entrar)
    static let proPurple = Color(hex: "#7841C8")       // Roxo suave Juntô Pro
    static let proBgLight = Color(hex: "#F3ECFA")
    static let orangeSave = Color(hex: "#EA5B27")      // Laranja salvar / destaque
    static let linkBlue = Color(hex: "#1E88C7")        // Azul editar discreto
    static let danger = Color(hex: "#DC2626")
    static let dangerLight = Color(hex: "#FEF2F2")

    static let bgMain = Color.white                    // Branco puro
    static let surface = Color.white
    static let surfaceSubtle = Color(hex: "#F4F5F7")   // Cinza nuvem bem leve
    static let border = Color(hex: "#E5E7EB")
    static let inputBorder = Color(hex: "#8E95A0")
    static let inputBorderFocus = Color(hex: "#26292E")

    static let textMain = Color(hex: "#22252A")        // Grafite suave (sem preto duro)
    static let textMuted = Color(hex: "#6B7280")
    static let textLight = Color(hex: "#9CA3AF")
}

// MARK: - Tipografia Inter Limpa (SEM bolds exagerados — apenas Regular e Medium)
extension Font {
    static func inter(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .medium, .semibold:
            name = "Inter-Medium"
        case .bold:
            name = "Inter-SemiBold"
        default:
            name = "Inter-Regular"
        }
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight == .bold ? .medium : weight, design: .default)
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
            (r, g, b) = (27, 127, 107)
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

// MARK: - Logo Geométrica Autoral do Juntô (Facetada Flat Minimalista)
struct JuntoLogoMark: View {
    var size: CGFloat = 86

    var body: some View {
        ZStack {
            // Topo menta
            Path { p in
                p.move(to: CGPoint(x: size * 0.50, y: size * 0.04))
                p.addLine(to: CGPoint(x: size * 0.92, y: size * 0.27))
                p.addLine(to: CGPoint(x: size * 0.50, y: size * 0.50))
                p.addLine(to: CGPoint(x: size * 0.08, y: size * 0.27))
                p.closeSubpath()
            }
            .fill(JuntoColors.primaryMint)

            // Esquerda esmeralda
            Path { p in
                p.move(to: CGPoint(x: size * 0.08, y: size * 0.27))
                p.addLine(to: CGPoint(x: size * 0.50, y: size * 0.50))
                p.addLine(to: CGPoint(x: size * 0.50, y: size * 0.96))
                p.addLine(to: CGPoint(x: size * 0.08, y: size * 0.73))
                p.closeSubpath()
            }
            .fill(JuntoColors.primary)

            // Direita superior grafite médio
            Path { p in
                p.move(to: CGPoint(x: size * 0.92, y: size * 0.27))
                p.addLine(to: CGPoint(x: size * 0.92, y: size * 0.73))
                p.addLine(to: CGPoint(x: size * 0.50, y: size * 0.50))
                p.closeSubpath()
            }
            .fill(Color(hex: "#565D66"))

            // Direita inferior grafite escuro
            Path { p in
                p.move(to: CGPoint(x: size * 0.50, y: size * 0.50))
                p.addLine(to: CGPoint(x: size * 0.92, y: size * 0.73))
                p.addLine(to: CGPoint(x: size * 0.50, y: size * 0.96))
                p.closeSubpath()
            }
            .fill(Color(hex: "#32383E"))

            // Letra "J" geométrica limpa recortada em branco
            Text("J")
                .font(.system(size: size * 0.52, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .offset(x: -size * 0.09, y: size * 0.14)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Avatar Circular Geométrico Minimalista (como na aba Conta)
struct GeometricAvatarView: View {
    var avatarData: Data? = nil
    var size: CGFloat = 56
    var primaryColor: Color = Color(hex: "#8E0E2C")
    var secondaryColor: Color = Color(hex: "#C84B62")

    var body: some View {
        Group {
            if let data = avatarData, let uiImg = UIImage(data: data) {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle().fill(secondaryColor)
                    Path { p in
                        p.move(to: CGPoint(x: size * 0.22, y: 0))
                        p.addLine(to: CGPoint(x: size, y: size * 0.50))
                        p.addLine(to: CGPoint(x: size * 0.22, y: size))
                        p.closeSubpath()
                    }
                    .fill(primaryColor)

                    Path { p in
                        p.move(to: CGPoint(x: size * 0.22, y: 0))
                        p.addLine(to: CGPoint(x: size, y: 0))
                        p.addLine(to: CGPoint(x: size, y: size * 0.50))
                        p.closeSubpath()
                    }
                    .fill(Color(hex: "#A91234"))
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            }
        }
    }
}

// MARK: - Botão Circular Flutuante (Voltar, Fechar, Lupa, Check)
struct CircleNavButton: View {
    let icon: String
    var bgColor: Color = .white
    var fgColor: Color = JuntoColors.textMain
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(fgColor)
                .frame(width: 44, height: 44)
                .background(bgColor)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                .overlay(
                    Circle()
                        .stroke(bgColor == .white ? JuntoColors.border.opacity(0.6) : Color.clear, lineWidth: 0.6)
                )
        }
    }
}

// MARK: - Inputs Limpos com Borda Fina (Exatamente como no modelo)
struct CleanOutlineInput: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var leadingPrefix: String? = nil
    var helperText: String? = nil
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            if !label.isEmpty {
                Text(label)
                    .font(.inter(13, weight: .regular))
                    .foregroundColor(JuntoColors.textMain)
            }

            HStack(spacing: 4) {
                if let prefix = leadingPrefix {
                    Text(prefix)
                        .font(.inter(15, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }
                TextField(placeholder, text: $text)
                    .font(.inter(15, weight: .regular))
                    .foregroundColor(JuntoColors.textMain)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
                    .focused($isFocused)
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .stroke(isFocused ? JuntoColors.inputBorderFocus : JuntoColors.inputBorder, lineWidth: isFocused ? 1.5 : 1)
            )

            if let helper = helperText {
                Text(helper)
                    .font(.inter(12, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
            }
        }
    }
}

struct CleanOutlineSecureInput: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var helperText: String? = nil
    @State private var isVisible = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.inter(13, weight: .regular))
                .foregroundColor(JuntoColors.textMain)

            HStack {
                if isVisible {
                    TextField(placeholder, text: $text)
                        .font(.inter(15, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                } else {
                    SecureField(placeholder, text: $text)
                        .font(.inter(15, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                        .focused($isFocused)
                }

                Button {
                    isVisible.toggle()
                } label: {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .stroke(isFocused ? JuntoColors.inputBorderFocus : JuntoColors.inputBorder, lineWidth: isFocused ? 1.5 : 1)
            )

            if let helper = helperText {
                Text(helper)
                    .font(.inter(12, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
            }
        }
    }
}

// MARK: - Botão Pílula Limpo (Estilo Referência)
struct JuntoPillButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = JuntoColors.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .regular))
                }
                Text(title)
                    .font(.inter(16, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(color)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Padrão Geométrico Ultra Sutil no Fundo (como na tela de Amigos)
struct SubtleFacetBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Color.white
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.25))
                    p.addLine(to: CGPoint(x: w * 0.45, y: h * 0.08))
                    p.addLine(to: CGPoint(x: w * 0.35, y: h * 0.42))
                    p.closeSubpath()
                }
                .fill(Color(hex: "#F6F7F9"))

                Path { p in
                    p.move(to: CGPoint(x: w * 0.45, y: h * 0.08))
                    p.addLine(to: CGPoint(x: w, y: h * 0.22))
                    p.addLine(to: CGPoint(x: w * 0.65, y: h * 0.48))
                    p.closeSubpath()
                }
                .fill(Color(hex: "#F9FAFB"))

                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.60))
                    p.addLine(to: CGPoint(x: w * 0.55, y: h * 0.45))
                    p.addLine(to: CGPoint(x: w * 0.30, y: h * 0.88))
                    p.closeSubpath()
                }
                .fill(Color(hex: "#F5F7F8"))

                Path { p in
                    p.move(to: CGPoint(x: w, y: h * 0.55))
                    p.addLine(to: CGPoint(x: w * 0.55, y: h * 0.72))
                    p.addLine(to: CGPoint(x: w, y: h * 0.95))
                    p.closeSubpath()
                }
                .fill(Color(hex: "#F7F8FA"))
            }
        }
        .ignoresSafeArea()
    }
}
