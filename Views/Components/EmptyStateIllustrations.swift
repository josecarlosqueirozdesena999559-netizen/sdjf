import SwiftUI

// MARK: - Paleta compartilhada
private enum IlloColors {
    static let navy    = Color(hex: "#14213D")          // primary Juntô
    static let navySoft = Color(hex: "#1D2E50")         // variação
    static let orange  = Color(hex: "#FCA311")          // accent Juntô
    static let skin    = Color(hex: "#F5CBA7")          // tom de pele
    static let skinDark = Color(hex: "#E8A87C")         // sombra pele
    static let hairDark = Color(hex: "#14213D")         // cabelo = navy
    static let bg      = Color(hex: "#EEF1F6")          // fundo suave primaryLight
    static let white   = Color.white
    static let paperLine = Color(hex: "#CBD5E1")        // linhas papel
}

// MARK: - Ilustração: Tela de Mensagens Vazia
// Personagem flat estilo ReceiptScanHero segurando smartphone com balão de chat
struct EmptyChatsIllustration: View {
    var size: CGFloat = 220

    var body: some View {
        let s = size / 220.0
        ZStack(alignment: .center) {
            // Fundo círculo suave
            Circle()
                .fill(IlloColors.bg)
                .frame(width: size * 0.92, height: size * 0.92)

            // ---- BALÃO DE CHAT (atrás do personagem) ----
            // Balão grande
            RoundedRectangle(cornerRadius: 16 * s)
                .fill(IlloColors.navy)
                .frame(width: 90 * s, height: 54 * s)
                .offset(x: 36 * s, y: -52 * s)

            // Cauda do balão
            Path { p in
                let ox: CGFloat = 36 * s
                let oy: CGFloat = -52 * s
                p.move(to: CGPoint(x: ox - 10 * s, y: oy + 27 * s))
                p.addLine(to: CGPoint(x: ox - 20 * s, y: oy + 44 * s))
                p.addLine(to: CGPoint(x: ox + 2 * s,  y: oy + 27 * s))
                p.closeSubpath()
            }
            .fill(IlloColors.navy)
            .frame(width: size, height: size)
            .offset(x: size / 2, y: size / 2)

            // Linhas dentro do balão (texto simulado)
            VStack(spacing: 6 * s) {
                Capsule().fill(Color.white.opacity(0.6)).frame(width: 56 * s, height: 5 * s)
                Capsule().fill(Color.white.opacity(0.4)).frame(width: 36 * s, height: 5 * s)
            }
            .offset(x: 36 * s, y: -52 * s)

            // Balão secundário menor (resposta)
            RoundedRectangle(cornerRadius: 10 * s)
                .fill(IlloColors.orange)
                .frame(width: 58 * s, height: 32 * s)
                .offset(x: -40 * s, y: -28 * s)

            Capsule()
                .fill(Color.white.opacity(0.7))
                .frame(width: 34 * s, height: 5 * s)
                .offset(x: -40 * s, y: -28 * s)

            // ---- PERSONAGEM ----
            // Corpo (moletom navy)
            RoundedRectangle(cornerRadius: 22 * s)
                .fill(IlloColors.navy)
                .frame(width: 68 * s, height: 62 * s)
                .offset(y: 48 * s)

            // Pescoço
            RoundedRectangle(cornerRadius: 4 * s)
                .fill(IlloColors.skin)
                .frame(width: 16 * s, height: 14 * s)
                .offset(y: 12 * s)

            // Braço esquerdo
            RoundedRectangle(cornerRadius: 10 * s)
                .fill(IlloColors.navy)
                .frame(width: 20 * s, height: 48 * s)
                .rotationEffect(.degrees(10))
                .offset(x: -38 * s, y: 44 * s)

            // Mão esquerda
            Circle()
                .fill(IlloColors.skin)
                .frame(width: 16 * s, height: 16 * s)
                .offset(x: -40 * s, y: 70 * s)

            // Braço direito (segurando o celular)
            RoundedRectangle(cornerRadius: 10 * s)
                .fill(IlloColors.navy)
                .frame(width: 20 * s, height: 44 * s)
                .rotationEffect(.degrees(-15))
                .offset(x: 36 * s, y: 36 * s)

            // Celular
            RoundedRectangle(cornerRadius: 6 * s)
                .fill(IlloColors.hairDark)
                .frame(width: 22 * s, height: 34 * s)
                .offset(x: 46 * s, y: 24 * s)

            // Tela do celular (azul claro simulando chat aberto)
            RoundedRectangle(cornerRadius: 4 * s)
                .fill(Color(hex: "#3B82F6"))
                .frame(width: 16 * s, height: 26 * s)
                .offset(x: 46 * s, y: 24 * s)

            // Cabelo (coque ou curto navy)
            Ellipse()
                .fill(IlloColors.hairDark)
                .frame(width: 46 * s, height: 20 * s)
                .offset(y: -18 * s)

            // Cabeça
            Circle()
                .fill(IlloColors.skin)
                .frame(width: 44 * s, height: 44 * s)
                .offset(y: -2 * s)

            // Cabelo sobre a cabeça
            Ellipse()
                .fill(IlloColors.hairDark)
                .frame(width: 44 * s, height: 22 * s)
                .offset(y: -13 * s)

            // Óculos — aro esquerdo
            RoundedRectangle(cornerRadius: 4 * s)
                .stroke(IlloColors.navy, lineWidth: 2 * s)
                .frame(width: 14 * s, height: 10 * s)
                .offset(x: -8 * s, y: -1 * s)

            // Óculos — aro direito
            RoundedRectangle(cornerRadius: 4 * s)
                .stroke(IlloColors.navy, lineWidth: 2 * s)
                .frame(width: 14 * s, height: 10 * s)
                .offset(x: 8 * s, y: -1 * s)

            // Ponte dos óculos
            Rectangle()
                .fill(IlloColors.navy)
                .frame(width: 4 * s, height: 2 * s)
                .offset(y: -1 * s)

            // Sorriso
            Arc(startAngle: .degrees(10), endAngle: .degrees(170), clockwise: false)
                .stroke(IlloColors.hairDark, lineWidth: 2 * s)
                .frame(width: 12 * s, height: 6 * s)
                .offset(y: 8 * s)
        }
        .frame(width: size, height: size)
        .clipped()
    }
}

// MARK: - Ilustração: Tela de Grupos Vazia
// Dois personagens flat lado a lado com ícone de grupo
struct EmptyGroupsIllustration: View {
    var size: CGFloat = 220

    var body: some View {
        let s = size / 220.0
        ZStack(alignment: .center) {
            // Fundo
            Circle()
                .fill(IlloColors.bg)
                .frame(width: size * 0.92, height: size * 0.92)

            // ---- PERSONAGEM ESQUERDO (menor / navy softer) ----
            // Corpo esq
            RoundedRectangle(cornerRadius: 16 * s)
                .fill(IlloColors.navy.opacity(0.55))
                .frame(width: 50 * s, height: 48 * s)
                .offset(x: -52 * s, y: 50 * s)

            // Cabeça esq
            Circle()
                .fill(IlloColors.skin)
                .frame(width: 34 * s, height: 34 * s)
                .offset(x: -52 * s, y: 8 * s)

            // Cabelo esq
            Ellipse()
                .fill(IlloColors.hairDark.opacity(0.7))
                .frame(width: 34 * s, height: 18 * s)
                .offset(x: -52 * s, y: -4 * s)

            // ---- PERSONAGEM DIREITO (menor / orange accent) ----
            // Corpo dir
            RoundedRectangle(cornerRadius: 16 * s)
                .fill(IlloColors.orange.opacity(0.75))
                .frame(width: 50 * s, height: 48 * s)
                .offset(x: 52 * s, y: 50 * s)

            // Cabeça dir
            Circle()
                .fill(IlloColors.skin)
                .frame(width: 34 * s, height: 34 * s)
                .offset(x: 52 * s, y: 8 * s)

            // Cabelo dir (mais curto)
            Ellipse()
                .fill(IlloColors.hairDark.opacity(0.7))
                .frame(width: 34 * s, height: 14 * s)
                .offset(x: 52 * s, y: -4 * s)

            // ---- PERSONAGEM CENTRAL (protagonista navy) ----
            // Corpo
            RoundedRectangle(cornerRadius: 20 * s)
                .fill(IlloColors.navy)
                .frame(width: 64 * s, height: 60 * s)
                .offset(y: 50 * s)

            // Pescoço
            RoundedRectangle(cornerRadius: 4 * s)
                .fill(IlloColors.skin)
                .frame(width: 16 * s, height: 12 * s)
                .offset(y: 15 * s)

            // Braço esq (aberto/aberto para os lados)
            RoundedRectangle(cornerRadius: 8 * s)
                .fill(IlloColors.navy)
                .frame(width: 18 * s, height: 42 * s)
                .rotationEffect(.degrees(25))
                .offset(x: -38 * s, y: 44 * s)

            // Braço dir
            RoundedRectangle(cornerRadius: 8 * s)
                .fill(IlloColors.navy)
                .frame(width: 18 * s, height: 42 * s)
                .rotationEffect(.degrees(-25))
                .offset(x: 38 * s, y: 44 * s)

            // Mãos
            Circle()
                .fill(IlloColors.skin)
                .frame(width: 14 * s, height: 14 * s)
                .offset(x: -52 * s, y: 68 * s)
            Circle()
                .fill(IlloColors.skin)
                .frame(width: 14 * s, height: 14 * s)
                .offset(x: 52 * s, y: 68 * s)

            // Cabeça central
            Circle()
                .fill(IlloColors.skin)
                .frame(width: 46 * s, height: 46 * s)
                .offset(y: -4 * s)

            // Cabelo (coque navy)
            Ellipse()
                .fill(IlloColors.hairDark)
                .frame(width: 46 * s, height: 24 * s)
                .offset(y: -16 * s)

            // Topinho coque
            Circle()
                .fill(IlloColors.hairDark)
                .frame(width: 14 * s, height: 14 * s)
                .offset(y: -28 * s)

            // Óculos
            RoundedRectangle(cornerRadius: 4 * s)
                .stroke(IlloColors.navy, lineWidth: 2 * s)
                .frame(width: 14 * s, height: 10 * s)
                .offset(x: -8 * s, y: -4 * s)
            RoundedRectangle(cornerRadius: 4 * s)
                .stroke(IlloColors.navy, lineWidth: 2 * s)
                .frame(width: 14 * s, height: 10 * s)
                .offset(x: 8 * s, y: -4 * s)
            Rectangle()
                .fill(IlloColors.navy)
                .frame(width: 4 * s, height: 2 * s)
                .offset(y: -4 * s)

            // Sorriso
            Arc(startAngle: .degrees(10), endAngle: .degrees(170), clockwise: false)
                .stroke(IlloColors.hairDark, lineWidth: 2 * s)
                .frame(width: 14 * s, height: 7 * s)
                .offset(y: 6 * s)

            // Badge grupo (badge laranja no topo)
            ZStack {
                Circle()
                    .fill(IlloColors.orange)
                    .frame(width: 30 * s, height: 30 * s)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 12 * s, weight: .bold))
                    .foregroundColor(.white)
            }
            .offset(y: -74 * s)
        }
        .frame(width: size, height: size)
        .clipped()
    }
}

// MARK: - Ilustração: Tela de Início (Home) Vazia
// Personagem segurando cartão/moeda com confetes — representa o app de finanças sociais
struct EmptyHomeIllustration: View {
    var size: CGFloat = 220

    var body: some View {
        let s = size / 220.0
        ZStack(alignment: .center) {
            // Fundo
            Circle()
                .fill(IlloColors.bg)
                .frame(width: size * 0.92, height: size * 0.92)

            // Confetes / moedas decorativas
            Circle()
                .fill(IlloColors.orange)
                .frame(width: 14 * s, height: 14 * s)
                .offset(x: -72 * s, y: -40 * s)

            Circle()
                .fill(IlloColors.navy.opacity(0.3))
                .frame(width: 10 * s, height: 10 * s)
                .offset(x: 70 * s, y: -55 * s)

            Circle()
                .fill(IlloColors.orange.opacity(0.5))
                .frame(width: 8 * s, height: 8 * s)
                .offset(x: 60 * s, y: 20 * s)

            RoundedRectangle(cornerRadius: 2 * s)
                .fill(IlloColors.orange)
                .frame(width: 8 * s, height: 8 * s)
                .rotationEffect(.degrees(30))
                .offset(x: -60 * s, y: 10 * s)

            RoundedRectangle(cornerRadius: 2 * s)
                .fill(IlloColors.navy.opacity(0.25))
                .frame(width: 6 * s, height: 6 * s)
                .rotationEffect(.degrees(-20))
                .offset(x: 44 * s, y: -68 * s)

            // ---- Cartão Pix / Pagamento (na mão) ----
            RoundedRectangle(cornerRadius: 10 * s)
                .fill(IlloColors.navy)
                .frame(width: 76 * s, height: 50 * s)
                .offset(x: -24 * s, y: -28 * s)

            // Chip do cartão
            RoundedRectangle(cornerRadius: 3 * s)
                .fill(IlloColors.orange)
                .frame(width: 18 * s, height: 13 * s)
                .offset(x: -40 * s, y: -34 * s)

            // Texto no cartão
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 38 * s, height: 4 * s)
                .offset(x: -16 * s, y: -20 * s)

            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 24 * s, height: 4 * s)
                .offset(x: -20 * s, y: -12 * s)

            // ---- CORPO ----
            RoundedRectangle(cornerRadius: 20 * s)
                .fill(IlloColors.navy)
                .frame(width: 66 * s, height: 62 * s)
                .offset(y: 50 * s)

            // Pescoço
            RoundedRectangle(cornerRadius: 4 * s)
                .fill(IlloColors.skin)
                .frame(width: 16 * s, height: 13 * s)
                .offset(y: 15 * s)

            // Braço esquerdo (estendido segurando o cartão)
            RoundedRectangle(cornerRadius: 9 * s)
                .fill(IlloColors.navy)
                .frame(width: 20 * s, height: 50 * s)
                .rotationEffect(.degrees(-30))
                .offset(x: -36 * s, y: 24 * s)

            // Mão esquerda + cartão
            Circle()
                .fill(IlloColors.skin)
                .frame(width: 16 * s, height: 16 * s)
                .offset(x: -52 * s, y: 2 * s)

            // Braço direito
            RoundedRectangle(cornerRadius: 9 * s)
                .fill(IlloColors.navy)
                .frame(width: 20 * s, height: 44 * s)
                .rotationEffect(.degrees(15))
                .offset(x: 36 * s, y: 40 * s)

            Circle()
                .fill(IlloColors.skin)
                .frame(width: 16 * s, height: 16 * s)
                .offset(x: 46 * s, y: 64 * s)

            // ---- CABEÇA ----
            Circle()
                .fill(IlloColors.skin)
                .frame(width: 46 * s, height: 46 * s)
                .offset(y: -4 * s)

            // Cabelo
            Ellipse()
                .fill(IlloColors.hairDark)
                .frame(width: 46 * s, height: 24 * s)
                .offset(y: -16 * s)

            // Topinho
            Circle()
                .fill(IlloColors.hairDark)
                .frame(width: 14 * s, height: 14 * s)
                .offset(y: -28 * s)

            // Óculos
            RoundedRectangle(cornerRadius: 4 * s)
                .stroke(IlloColors.navy, lineWidth: 2 * s)
                .frame(width: 14 * s, height: 10 * s)
                .offset(x: -8 * s, y: -4 * s)
            RoundedRectangle(cornerRadius: 4 * s)
                .stroke(IlloColors.navy, lineWidth: 2 * s)
                .frame(width: 14 * s, height: 10 * s)
                .offset(x: 8 * s, y: -4 * s)
            Rectangle()
                .fill(IlloColors.navy)
                .frame(width: 4 * s, height: 2 * s)
                .offset(y: -4 * s)

            // Sorriso
            Arc(startAngle: .degrees(10), endAngle: .degrees(170), clockwise: false)
                .stroke(IlloColors.hairDark, lineWidth: 2 * s)
                .frame(width: 14 * s, height: 7 * s)
                .offset(y: 6 * s)
        }
        .frame(width: size, height: size)
        .clipped()
    }
}

// MARK: - Arc shape helper
struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: clockwise
        )
        return p
    }
}
