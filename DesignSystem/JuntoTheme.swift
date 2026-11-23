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

// MARK: - Logo Oficial do Juntô (usa imagem real do ícone do app)
struct JuntoLogoMark: View {
    var size: CGFloat = 86
    /// `true` = com o fundo azul-noite arredondado (igual ao ícone). `false` = apenas o símbolo (para fundos escuros).
    var showsBackground: Bool = true

    var body: some View {
        ZStack {
            if showsBackground {
                RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous)
                    .fill(Color(hex: "#14213D"))
                    .frame(width: size, height: size)
            }

            Image("JuntoLogoMark")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous))
        }
        .frame(width: size, height: size)
        .shadow(color: showsBackground ? Color(hex: "#14213D").opacity(0.22) : .clear, radius: size * 0.08, y: size * 0.04)
    }
}

// MARK: - Ícone Nativo iOS do Pote Coletivo (Padronizado com o sistema, sem moedas nem fundos pesados)
struct JuntoPotIcon: View {
    var size: CGFloat = 22
    var color: Color = JuntoColors.primary

    var body: some View {
        Image(systemName: "chart.pie")
            .font(.system(size: min(size, 22), weight: .regular))
            .foregroundColor(color)
    }
}

// MARK: - Ícone Oficial do Pix (Banco Central do Brasil — Losango com encaixes internos)
struct PixOfficialIcon: View {
    var size: CGFloat = 22
    var color: Color = Color(hex: "#32BCAD")

    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width
            let h = sz.height
            let s = min(w, h)

            // Losango arredondado do Pix rotacionado 45°
            var outer = Path()
            let r = s * 0.34
            let rect = CGRect(x: -r, y: -r, width: r * 2, height: r * 2)
            outer.addRoundedRect(in: rect, cornerSize: CGSize(width: s * 0.11, height: s * 0.11))

            var transform = CGAffineTransform(translationX: w / 2, y: h / 2)
                .rotated(by: .pi / 4)
            let diamond = outer.applying(transform)
            ctx.stroke(diamond, with: .color(color), style: StrokeStyle(lineWidth: s * 0.085, lineCap: .round, lineJoin: .round))

            // Linhas internas características do símbolo do Pix (duas chaves opostas que se encontram no centro)
            var inner = Path()
            // Curva superior interna
            inner.move(to: CGPoint(x: w * 0.27, y: h * 0.38))
            inner.addLine(to: CGPoint(x: w * 0.41, y: h * 0.38))
            inner.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.45), control: CGPoint(x: w * 0.46, y: h * 0.38))
            inner.addQuadCurve(to: CGPoint(x: w * 0.59, y: h * 0.38), control: CGPoint(x: w * 0.54, y: h * 0.38))
            inner.addLine(to: CGPoint(x: w * 0.73, y: h * 0.38))

            // Curva inferior interna
            inner.move(to: CGPoint(x: w * 0.27, y: h * 0.62))
            inner.addLine(to: CGPoint(x: w * 0.41, y: h * 0.62))
            inner.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.55), control: CGPoint(x: w * 0.46, y: h * 0.62))
            inner.addQuadCurve(to: CGPoint(x: w * 0.59, y: h * 0.62), control: CGPoint(x: w * 0.54, y: h * 0.62))
            inner.addLine(to: CGPoint(x: w * 0.73, y: h * 0.62))

            ctx.stroke(inner, with: .color(color), style: StrokeStyle(lineWidth: s * 0.075, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Avatar Premium com Cores Misturadas Únicas (mais de 130 combinações diferentes)
struct GeometricAvatarView: View {
    var seed: String = "junto"
    var displayName: String? = nil
    var avatarData: Data? = nil
    var size: CGFloat = 56

    private static let baseColors: [Color] = [
        Color(hex: "#14213D"), // Azul-noite
        Color(hex: "#FCA311"), // Manga
        Color(hex: "#16A34A"), // Esmeralda
        Color(hex: "#2563EB"), // Cobalto
        Color(hex: "#E2711D"), // Terracota
        Color(hex: "#7C3AED"), // Violeta
        Color(hex: "#0D9488"), // Turquesa
        Color(hex: "#DB2777"), // Magenta
        Color(hex: "#0284C7"), // Oceano
        Color(hex: "#D97706"), // Âmbar
        Color(hex: "#4F46E5"), // Índigo
        Color(hex: "#059669")  // Jade
    ]

    private var hashValueStable: Int {
        var hash = 5381
        for byte in seed.lowercased().utf8 {
            hash = ((hash << 5) &+ hash) &+ Int(byte)
        }
        return abs(hash)
    }

    private var color1: Color {
        Self.baseColors[hashValueStable % Self.baseColors.count]
    }

    private var color2: Color {
        let count = Self.baseColors.count
        let idx1 = hashValueStable % count
        let offset = 1 + ((hashValueStable / count) % (count - 1))
        return Self.baseColors[(idx1 + offset) % count]
    }

    private var color3: Color {
        let count = Self.baseColors.count
        let idx1 = hashValueStable % count
        let offset = 2 + ((hashValueStable / (count * 2)) % (count - 2))
        return Self.baseColors[(idx1 + offset) % count]
    }

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
                    // Gradiente misturado de 3 cores únicas por usuário
                    LinearGradient(
                        colors: [color1, color2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Circle()
                        .fill(color3.opacity(0.45))
                        .frame(width: size * 0.85, height: size * 0.85)
                        .offset(x: size * 0.30, y: size * 0.30)
                        .blur(radius: size * 0.14)

                    Circle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: size * 0.80, height: size * 0.80)
                        .offset(x: -size * 0.28, y: -size * 0.32)

                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.44, weight: .regular))
                        .foregroundColor(.white.opacity(0.94))
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            }
        }
    }
}

// MARK: - Barra de Pesquisa com Animação "Digitando" (efeito máquina de escrever)
struct AnimatedSearchBar: View {
    @Binding var text: String
    var placeholders: [String] = [
        "Pesquisar @lucas123",
        "Pesquisar @ana.paula",
        "Pesquisar @pedro.santos",
        "Pesquisar @camila.rocha"
    ]

    @FocusState private var isFocused: Bool
    @State private var phraseIndex = 0
    @State private var charCount = 0
    @State private var isDeleting = false
    @State private var pauseTicks = 0
    @State private var showCursor = true

    private let typingTimer = Timer.publish(every: 0.085, on: .main, in: .common).autoconnect()
    private let cursorTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    private var displayedPlaceholder: String {
        guard !placeholders.isEmpty else { return "" }
        let phrase = placeholders[phraseIndex % placeholders.count]
        return String(phrase.prefix(min(charCount, phrase.count)))
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(isFocused ? JuntoColors.primary : JuntoColors.textMuted)

            ZStack(alignment: .leading) {
                if text.isEmpty && !isFocused {
                    HStack(spacing: 1) {
                        Text(displayedPlaceholder)
                            .font(.inter(14, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                        Rectangle()
                            .fill(JuntoColors.primary.opacity(showCursor ? 0.65 : 0))
                            .frame(width: 1.5, height: 15)
                    }
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
        .onReceive(cursorTimer) { _ in
            guard text.isEmpty && !isFocused else { return }
            showCursor.toggle()
        }
        .onReceive(typingTimer) { _ in
            guard text.isEmpty && !isFocused, !placeholders.isEmpty else { return }
            let phrase = placeholders[phraseIndex % placeholders.count]

            if pauseTicks > 0 {
                pauseTicks -= 1
                return
            }

            if !isDeleting {
                if charCount < phrase.count {
                    charCount += 1
                } else {
                    isDeleting = true
                    pauseTicks = 14 // pausa exibindo o texto completo
                }
            } else {
                if charCount > 0 {
                    charCount -= 1
                } else {
                    isDeleting = false
                    phraseIndex = (phraseIndex + 1) % placeholders.count
                    pauseTicks = 4
                }
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
