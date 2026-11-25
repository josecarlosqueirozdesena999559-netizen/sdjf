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
    static let dangerRed = Color(hex: "#C62828")
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

// MARK: - Selo de Usuário Verificado (Assinante Mensal Roxo / Assinante Anual Dourado)
struct VerifiedBadgeView: View {
    var type: ProPlanType = .none
    var size: CGFloat = 13

    var body: some View {
        switch type {
        case .monthly:
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(Color(hex: "#7C3AED")) // Roxo exclusivo para assinante mensal
                .accessibilityLabel("Assinante Mensal Verificado")
        case .yearly:
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(Color(hex: "#F59E0B")) // Dourado exclusivo para assinante anual
                .accessibilityLabel("Assinante Anual Verificado")
        case .none:
            EmptyView()
        }
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

// MARK: - Ícone Oficial do Pix (Banco Central do Brasil — Vetor SVG Oficial Flat)
struct PixOfficialShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 24.0
        let sy = rect.height / 24.0
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }

        var p = Path()
        // Parte inferior
        p.move(to: pt(5.283, 18.360))
        p.addCurve(to: pt(7.776, 17.328), control1: pt(6.218, 18.362), control2: pt(7.116, 17.991))
        p.addLine(to: pt(11.376, 13.728))
        p.addCurve(to: pt(12.322, 13.728), control1: pt(11.641, 13.475), control2: pt(12.057, 13.475))
        p.addLine(to: pt(15.935, 17.341))
        p.addCurve(to: pt(18.428, 18.373), control1: pt(16.595, 18.004), control2: pt(17.493, 18.376))
        p.addLine(to: pt(19.138, 18.373))
        p.addLine(to: pt(14.578, 22.933))
        p.addCurve(to: pt(9.422, 22.933), control1: pt(13.154, 24.356), control2: pt(10.846, 24.356))
        p.addLine(to: pt(4.850, 18.360))
        p.closeSubpath()

        // Parte superior
        p.move(to: pt(18.428, 5.627))
        p.addCurve(to: pt(15.935, 6.659), control1: pt(17.493, 5.625), control2: pt(16.595, 5.996))
        p.addLine(to: pt(12.322, 10.273))
        p.addCurve(to: pt(11.376, 10.273), control1: pt(12.061, 10.534), control2: pt(11.637, 10.534))
        p.addLine(to: pt(7.776, 6.673))
        p.addCurve(to: pt(5.283, 5.640), control1: pt(7.116, 6.010), control2: pt(6.219, 5.638))
        p.addLine(to: pt(4.849, 5.640))
        p.addLine(to: pt(9.422, 1.068))
        p.addCurve(to: pt(14.578, 1.068), control1: pt(10.846, -0.356), control2: pt(13.154, -0.356))
        p.addLine(to: pt(19.137, 5.627))
        p.closeSubpath()

        // Corpo lateral contínuo oficial (esquerda + centro + direita)
        p.move(to: pt(1.068, 9.422))
        p.addLine(to: pt(3.790, 6.699))
        p.addLine(to: pt(5.282, 6.699))
        p.addCurve(to: pt(7.026, 7.421), control1: pt(5.936, 6.701), control2: pt(6.562, 6.960))
        p.addLine(to: pt(10.626, 11.021))
        p.addCurve(to: pt(13.069, 11.021), control1: pt(11.301, 11.694), control2: pt(12.394, 11.694))
        p.addLine(to: pt(16.683, 7.408))
        p.addCurve(to: pt(18.427, 6.685), control1: pt(17.146, 6.947), control2: pt(17.773, 6.687))
        p.addLine(to: pt(20.194, 6.685))
        p.addLine(to: pt(22.931, 9.422))
        p.addCurve(to: pt(22.931, 14.578), control1: pt(24.355, 10.846), control2: pt(24.355, 13.154))
        p.addLine(to: pt(20.195, 17.314))
        p.addLine(to: pt(18.427, 17.314))
        p.addCurve(to: pt(16.683, 16.592), control1: pt(17.773, 17.312), control2: pt(17.147, 17.053))
        p.addLine(to: pt(13.070, 12.979))
        p.addCurve(to: pt(10.626, 12.979), control1: pt(12.386, 12.326), control2: pt(11.310, 12.326))
        p.addLine(to: pt(7.026, 16.579))
        p.addCurve(to: pt(5.282, 17.301), control1: pt(6.562, 17.040), control2: pt(5.936, 17.299))
        p.addLine(to: pt(3.791, 17.301))
        p.addLine(to: pt(1.068, 14.578))
        p.addCurve(to: pt(1.068, 9.422), control1: pt(-0.356, 13.154), control2: pt(-0.356, 10.846))
        p.closeSubpath()

        return p
    }
}

struct PixOfficialIcon: View {
    var size: CGFloat = 24
    var color: Color = Color(hex: "#32BCAD")

    var body: some View {
        PixOfficialShape()
            .fill(color)
            .frame(width: size, height: size)
    }
}

// MARK: - Cartão de Chave Pix no Chat (Estilo Cartão de Contato com Toque para Copiar)
struct PixContactCardView: View {
    let name: String
    let pixKey: String
    let isFromMe: Bool

    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header flat com ícone oficial do Pix (Banco Central)
            HStack(spacing: 10) {
                PixOfficialIcon(size: 24, color: isFromMe ? Color(hex: "#5EEAD4") : Color(hex: "#32BCAD"))

                VStack(alignment: .leading, spacing: 1) {
                    Text("Chave Pix")
                        .font(.inter(13, weight: .semibold))
                        .foregroundColor(isFromMe ? .white : JuntoColors.textMain)
                    Text(name)
                        .font(.inter(11, weight: .regular))
                        .foregroundColor(isFromMe ? .white.opacity(0.80) : JuntoColors.textMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)
            }

            // Caixa com a chave Pix
            VStack(alignment: .leading, spacing: 3) {
                Text("Chave")
                    .font(.inter(10, weight: .medium))
                    .foregroundColor(isFromMe ? .white.opacity(0.70) : JuntoColors.textLight)
                Text(pixKey)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(isFromMe ? .white : JuntoColors.textMain)
                    .lineLimit(1)
                    .textSelection(.enabled)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isFromMe ? Color.white.opacity(0.12) : JuntoColors.surfaceSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Botão Copiar Chave Pix
            Button {
                UIPasteboard.general.string = pixKey
                copied = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    copied = false
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12, weight: .semibold))
                    Text(copied ? "Chave Pix copiada!" : "Copiar chave Pix")
                        .font(.inter(12, weight: .semibold))
                }
                .foregroundColor(isFromMe ? JuntoColors.primary : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isFromMe ? Color.white : Color(hex: "#00B494"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(JuntoTapBounceStyle(scaleAmount: 0.96))
        }
        .frame(minWidth: 190, maxWidth: 245)
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

// MARK: - Barra de Pesquisa Limpa (Nativa iOS, sem animação de digitação)
struct AnimatedSearchBar: View {
    @Binding var text: String
    var placeholders: [String] = ["Pesquisar"]

    @FocusState private var isFocused: Bool

    private var placeholderText: String {
        placeholders.first ?? "Pesquisar"
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(isFocused ? JuntoColors.primary : JuntoColors.textMuted)

            TextField(placeholderText, text: $text)
                .font(.inter(14, weight: .regular))
                .foregroundColor(JuntoColors.textMain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isFocused)

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
    }
}

// MARK: - Botão Fechar de Popups (Apenas o X limpo, sem fundo)
struct PopupCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(JuntoColors.textMain)
                .frame(width: 34, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(JuntoTapBounceStyle(scaleAmount: 0.90))
    }
}

// MARK: - Ícone Quadrado Arredondado por Categoria de Grupo (Cores Juntô, sem imagem genérica)
struct GroupCategoryIconTile: View {
    let category: String
    var size: CGFloat = 50

    private var iconName: String {
        switch category {
        case "Viagem": return "airplane"
        case "Churrasco": return "flame.fill"
        case "Casa": return "house.fill"
        case "Casal": return "heart.fill"
        case "Bar & Drinks": return "wineglass.fill"
        case "Festa": return "sparkles"
        case "Esporte": return "sportscourt.fill"
        case "Presente": return "gift.fill"
        case "Trabalho": return "briefcase.fill"
        default: return "list.bullet.rectangle"
        }
    }

    private var gradientColors: [Color] {
        switch category {
        case "Viagem": return [JuntoColors.primary, Color(hex: "#2563EB")]
        case "Churrasco": return [JuntoColors.orangeSave, Color(hex: "#FCA311")]
        case "Casa": return [JuntoColors.pixGreen, Color(hex: "#0D9488")]
        case "Casal": return [Color(hex: "#DB2777"), Color(hex: "#F43F5E")]
        case "Bar & Drinks": return [Color(hex: "#7C3AED"), Color(hex: "#4F46E5")]
        case "Festa": return [Color(hex: "#9333EA"), Color(hex: "#EC4899")]
        case "Esporte": return [Color(hex: "#0284C7"), Color(hex: "#0EA5E9")]
        default: return [JuntoColors.primary, Color(hex: "#334155")]
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: iconName)
                .font(.system(size: size * 0.44, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Barra de Gravação de Áudio Estilo WhatsApp (2 linhas limpas nas cores Juntô)
struct WhatsAppAudioRecordingBar: View {
    let recordingSeconds: Int
    let liveLevels: [CGFloat]
    let onCancel: () -> Void
    let onSend: () -> Void

    @State private var pulseActive = false

    private var formattedTimer: String {
        let mins = recordingSeconds / 60
        let secs = recordingSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private var symmetricBars: [CGFloat] {
        let count = 24
        let raw = Array(liveLevels.suffix(count))
        var result: [CGFloat] = []
        for i in 0..<count {
            let level: Double = i < raw.count ? Double(raw[i]) : 0.16
            // Envelope suave nas pontas (estilo onda simétrica do WhatsApp)
            let progress = Double(i) / Double(max(1, count - 1))
            let envelope = sin(progress * .pi)
            let height = 3.5 + CGFloat(level * (0.28 + 0.72 * envelope)) * 22.0
            result.append(min(26, max(3.5, height)))
        }
        return result
    }

    var body: some View {
        VStack(spacing: 14) {
            // Linha 1: Cronômetro à esquerda + Onda simétrica animada à direita
            HStack(alignment: .center, spacing: 12) {
                Text(formattedTimer)
                    .font(.inter(20, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)
                    .monospacedDigit()

                Spacer(minLength: 12)

                HStack(alignment: .center, spacing: 2.5) {
                    ForEach(Array(symmetricBars.enumerated()), id: \.offset) { _, h in
                        Capsule()
                            .fill(JuntoColors.primary.opacity(0.82))
                            .frame(width: 2.6, height: h)
                    }
                }
                .frame(height: 28)
                .animation(.easeOut(duration: 0.10), value: liveLevels)
            }
            .padding(.horizontal, 6)

            // Linha 2: Lixeira (sem fundo) à esquerda | Indicador de gravação vermelho no centro | Enviar circular nas cores Juntô à direita
            HStack(alignment: .center) {
                Button(action: onCancel) {
                    Image(systemName: "trash")
                        .font(.system(size: 21, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(JuntoTapBounceStyle(scaleAmount: 0.90))

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color(hex: "#E11D48"), lineWidth: 2.2)
                        .frame(width: 34, height: 34)
                        .scaleEffect(pulseActive ? 1.10 : 0.96)
                        .opacity(pulseActive ? 1.0 : 0.65)
                    Image(systemName: "pause.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "#E11D48"))
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true)) {
                        pulseActive = true
                    }
                }

                Spacer()

                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(JuntoColors.primary)
                        .clipShape(Circle())
                }
                .buttonStyle(JuntoTapBounceStyle(scaleAmount: 0.92))
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 2)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Estilo de Toque Fluido e Responsivo (efeito mola suave em qualquer botão)
struct JuntoTapBounceStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.interactiveSpring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
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
        .buttonStyle(JuntoTapBounceStyle(scaleAmount: 0.92))
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

// MARK: - Botão Retangular Profissional Responsivo (cantos suaves 10pt)
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundColor(textColor)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(JuntoTapBounceStyle())
    }
}

// MARK: - Botão Retangular Contornado Responsivo (secundário)
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundColor(color)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(color, lineWidth: 1.2)
            )
        }
        .buttonStyle(JuntoTapBounceStyle())
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
