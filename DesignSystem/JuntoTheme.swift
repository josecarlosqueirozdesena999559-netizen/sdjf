import SwiftUI

// MARK: - Paleta Autoral do Juntô (Azul-Noite + Manga + Areia) — profissional e única
enum JuntoColors {
    static let primary = Color(hex: "#14213D")         // Azul-noite (marca / botões principais)
    static let primaryLight = Color(hex: "#EEF1F6")    // Névoa azulada
    static let accent = Color(hex: "#FCA311")          // Manga (destaques da marca)
    static let accentLight = Color(hex: "#FFF4DE")
    static let primaryAccent = Color(hex: "#FCA311")
    static let sand = Color(hex: "#F5EBDD")            // Areia
    static let warmBg = Color(hex: "#FAF8F5")          // Off-white quente (onboarding)
    static let pixGreen = Color(hex: "#16A34A")        // Receber / Pix
    static let pixGreenLight = Color(hex: "#EAF7EE")
    static let darkButton = Color(hex: "#14213D")
    static let proIndigo = Color(hex: "#14213D")       // Juntô Pro em azul-noite + manga
    static let proBgLight = Color(hex: "#FFF4DE")
    static let orangeSave = Color(hex: "#E2711D")      // Você deve / pendente
    static let linkBlue = Color(hex: "#1D4E89")
    static let danger = Color(hex: "#C62828")
    static let dangerLight = Color(hex: "#FDECEC")

    static let bgMain = Color.white
    static let surface = Color.white
    static let surfaceSubtle = Color(hex: "#F4F4F2")
    static let border = Color(hex: "#E6E4E0")
    static let inputBorder = Color(hex: "#A8A6A1")
    static let inputBorderFocus = Color(hex: "#14213D")

    static let textMain = Color(hex: "#1B1F27")
    static let textMuted = Color(hex: "#6B6E76")
    static let textLight = Color(hex: "#A3A5AA")
}

// MARK: - Tipografia Inter Limpa (SEM bolds pesados — apenas Regular e Medium)
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
            (r, g, b) = (37, 99, 235)
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

// MARK: - Logo Autoral do Juntô (Elos Entrelaçados Minimalistas + Núcleo Pix)
struct JuntoLogoMark: View {
    var size: CGFloat = 86

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .fill(JuntoColors.primary)
                .frame(width: size, height: size)

            // Elo esquerdo (Branco)
            Circle()
                .stroke(Color.white, lineWidth: size * 0.09)
                .frame(width: size * 0.42, height: size * 0.42)
                .offset(x: -size * 0.12)

            // Elo direito (Celeste)
            Circle()
                .stroke(JuntoColors.primaryAccent, lineWidth: size * 0.09)
                .frame(width: size * 0.42, height: size * 0.42)
                .offset(x: size * 0.12)

            // Núcleo de união (Branco + ponto Pix esmeralda)
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.14, height: size * 0.14)
            Circle()
                .fill(JuntoColors.primary)
                .frame(width: size * 0.07, height: size * 0.07)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Avatar Ilustrado Flat Estilo "Praia" (Personagens minimalistas sem rosto de todas as cores)
struct GeometricAvatarView: View {
    var seed: String = "junto"
    var avatarData: Data? = nil
    var size: CGFloat = 56

    private static let bgColors: [Color] = [
        Color(hex: "#F5EBDD"), // Areia
        Color(hex: "#E8F0FE"), // Azul névoa
        Color(hex: "#E6F7EE"), // Menta suave
        Color(hex: "#FFF1DF"), // Pêssego claro
        Color(hex: "#F3E8FF"), // Lavanda suave
        Color(hex: "#FCE7F3"), // Rosa claro
        Color(hex: "#E0F2FE"), // Celeste claro
        Color(hex: "#FEF3C7")  // Sol suave
    ]

    private static let shirtColors: [Color] = [
        Color(hex: "#14213D"), // Azul-noite
        Color(hex: "#FCA311"), // Manga
        Color(hex: "#16A34A"), // Esmeralda
        Color(hex: "#E2711D"), // Terracota
        Color(hex: "#2563EB"), // Cobalto
        Color(hex: "#7C3AED"), // Violeta
        Color(hex: "#0D9488"), // Turquesa
        Color(hex: "#DB2777")  // Magenta
    ]

    private static let skinColors: [Color] = [
        Color(hex: "#5C3A28"), // Pele retinta
        Color(hex: "#8D5B3E"), // Pele parda escura
        Color(hex: "#B88462"), // Pele parda clara
        Color(hex: "#D7A988"), // Pele oliva
        Color(hex: "#ECC6AA")  // Pele clara
    ]

    private static let hairColors: [Color] = [
        Color(hex: "#14213D"), // Azul-noite (mesmo estilo da praia!)
        Color(hex: "#1E1B18"), // Preto suave
        Color(hex: "#3B281F"), // Castanho escuro
        Color(hex: "#5A3E2B")  // Castanho médio
    ]

    private var hashValueStable: Int {
        var hash = 5381
        for byte in seed.lowercased().utf8 {
            hash = ((hash << 5) &+ hash) &+ Int(byte)
        }
        return abs(hash)
    }

    private var bg: Color { Self.bgColors[hashValueStable % Self.bgColors.count] }
    private var shirt: Color { Self.shirtColors[(hashValueStable / 3) % Self.shirtColors.count] }
    private var skin: Color { Self.skinColors[(hashValueStable / 7) % Self.skinColors.count] }
    private var hair: Color { Self.hairColors[(hashValueStable / 11) % Self.hairColors.count] }
    private var hairStyle: Int { (hashValueStable / 13) % 4 }

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
                    Circle().fill(bg)

                    // Cabelo traseiro (para estilos volumosos / coque / cacheado)
                    if hairStyle == 0 {
                        // Afro redondo estiloso (como na ilustração da praia)
                        Circle()
                            .fill(hair)
                            .frame(width: size * 0.48, height: size * 0.48)
                            .offset(x: -size * 0.03, y: -size * 0.14)
                    } else if hairStyle == 1 {
                        // Coque alto
                        Circle()
                            .fill(hair)
                            .frame(width: size * 0.22, height: size * 0.22)
                            .offset(y: -size * 0.34)
                        Circle()
                            .fill(hair)
                            .frame(width: size * 0.38, height: size * 0.38)
                            .offset(y: -size * 0.12)
                    } else if hairStyle == 2 {
                        // Ondulado médio
                        Capsule()
                            .fill(hair)
                            .frame(width: size * 0.44, height: size * 0.46)
                            .offset(y: -size * 0.05)
                    }

                    // Ombros / Camiseta
                    Ellipse()
                        .fill(shirt)
                        .frame(width: size * 0.72, height: size * 0.46)
                        .offset(y: size * 0.36)

                    // Pescoço
                    RoundedRectangle(cornerRadius: size * 0.06)
                        .fill(skin)
                        .frame(width: size * 0.14, height: size * 0.18)
                        .offset(y: size * 0.10)

                    // Cabeça minimalista sem rosto (faceless)
                    Ellipse()
                        .fill(skin)
                        .frame(width: size * 0.30, height: size * 0.34)
                        .offset(y: -size * 0.09)

                    // Topete / Franja frontal
                    if hairStyle == 3 {
                        // Curto moderno com topete (como o amigo da direita na praia)
                        Path { p in
                            p.move(to: CGPoint(x: size * 0.34, y: size * 0.36))
                            p.addQuadCurve(
                                to: CGPoint(x: size * 0.66, y: size * 0.34),
                                control: CGPoint(x: size * 0.48, y: size * 0.15)
                            )
                            p.addQuadCurve(
                                to: CGPoint(x: size * 0.64, y: size * 0.43),
                                control: CGPoint(x: size * 0.68, y: size * 0.39)
                            )
                            p.addQuadCurve(
                                to: CGPoint(x: size * 0.35, y: size * 0.40),
                                control: CGPoint(x: size * 0.50, y: size * 0.28)
                            )
                            p.closeSubpath()
                        }
                        .fill(hair)
                    } else {
                        // Franja suave no topo da cabeça
                        Path { p in
                            p.addArc(
                                center: CGPoint(x: size * 0.50, y: size * 0.38),
                                radius: size * 0.155,
                                startAngle: .degrees(190),
                                endAngle: .degrees(350),
                                clockwise: false
                            )
                            p.closeSubpath()
                        }
                        .fill(hair)
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            }
        }
    }
}

// MARK: - Barra de Pesquisa Animada (cicla sugestões e limpa ao tocar para digitar)
struct AnimatedSearchBar: View {
    @Binding var text: String
    var placeholders: [String] = [
        "Pesquisando algum nome?",
        "Buscar @pedro.santos...",
        "Procurando um amigo?",
        "Digite um nome ou @usuário..."
    ]

    @FocusState private var isFocused: Bool
    @State private var currentIndex = 0
    private let timer = Timer.publish(every: 2.6, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(isFocused ? JuntoColors.primary : JuntoColors.textMuted)

            ZStack(alignment: .leading) {
                if text.isEmpty && !isFocused {
                    Text(placeholders[currentIndex])
                        .font(.inter(14, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                        .id(currentIndex)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }

                TextField("", text: $text)
                    .font(.inter(14, weight: .regular))
                    .foregroundColor(JuntoColors.textMain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isFocused)
            }
            .clipped()

            if !text.isEmpty || isFocused {
                Button {
                    text = ""
                    isFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(JuntoColors.textLight)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(JuntoColors.surfaceSubtle)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isFocused ? JuntoColors.primary : Color.clear, lineWidth: 1.2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onReceive(timer) { _ in
            guard text.isEmpty && !isFocused else { return }
            withAnimation(.easeInOut(duration: 0.35)) {
                currentIndex = (currentIndex + 1) % placeholders.count
            }
        }
    }
}

// MARK: - Botão Circular Flutuante
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

// MARK: - Inputs Limpos com Borda Fina
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
            if !label.isEmpty {
                Text(label)
                    .font(.inter(13, weight: .regular))
                    .foregroundColor(JuntoColors.textMain)
            }

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

// MARK: - Botão Retangular Profissional (cantos suaves 10pt)
struct JuntoPillButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = JuntoColors.primary
    var textColor: Color = .white
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
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

// MARK: - Botão Retangular Contornado (secundário)
struct JuntoOutlineButton: View {
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
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(color, lineWidth: 1.2)
            )
        }
    }
}

// MARK: - Padrão Geométrico Ultra Sutil no Fundo
struct SubtleFacetBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Color.white
                Circle()
                    .fill(JuntoColors.sand.opacity(0.35))
                    .frame(width: w * 0.9, height: w * 0.9)
                    .offset(x: -w * 0.35, y: -h * 0.15)
                Circle()
                    .fill(JuntoColors.primaryLight.opacity(0.6))
                    .frame(width: w * 0.85, height: w * 0.85)
                    .offset(x: w * 0.42, y: h * 0.35)
            }
        }
        .ignoresSafeArea()
    }
}
