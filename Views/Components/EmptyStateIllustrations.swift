import SwiftUI

// MARK: - Ilustração Estado Vazio: Conversas
// Boneco + balão de chat, usando JuntoColors.primary
struct EmptyChatsIllustration: View {
    var size: CGFloat = 220

    var body: some View {
        let s = size / 220
        ZStack {
            // Fundo círculo suave
            Circle()
                .fill(JuntoColors.primaryLight)
                .frame(width: size * 0.88, height: size * 0.88)

            // Balão de chat de fundo (segundo plano)
            RoundedRectangle(cornerRadius: 12 * s)
                .fill(JuntoColors.primary.opacity(0.12))
                .frame(width: 90 * s, height: 60 * s)
                .offset(x: 28 * s, y: -20 * s)

            // Bolinhas dentro do balão
            HStack(spacing: 5 * s) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(JuntoColors.primary.opacity(0.35))
                        .frame(width: 7 * s, height: 7 * s)
                }
            }
            .offset(x: 28 * s, y: -20 * s)

            // Balão de chat principal
            RoundedRectangle(cornerRadius: 14 * s)
                .fill(JuntoColors.primary)
                .frame(width: 100 * s, height: 64 * s)
                .offset(x: -16 * s, y: -30 * s)

            // Bolinhas no balão principal
            HStack(spacing: 6 * s) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8 * s, height: 8 * s)
                }
            }
            .offset(x: -16 * s, y: -30 * s)

            // Corpo do boneco
            Capsule()
                .fill(JuntoColors.primary)
                .frame(width: 44 * s, height: 54 * s)
                .offset(y: 44 * s)

            // Cabeça
            Circle()
                .fill(JuntoColors.primary)
                .frame(width: 38 * s, height: 38 * s)
                .offset(y: 10 * s)

            // Rosto sorridente
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 10 * s, height: 10 * s)
                .offset(x: -6 * s, y: 8 * s)

            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 10 * s, height: 10 * s)
                .offset(x: 6 * s, y: 8 * s)

            // Sorriso
            Arc(startAngle: .degrees(10), endAngle: .degrees(170), clockwise: false)
                .stroke(Color.white, lineWidth: 2 * s)
                .frame(width: 16 * s, height: 8 * s)
                .offset(y: 18 * s)

            // Braços
            RoundedRectangle(cornerRadius: 4 * s)
                .fill(JuntoColors.primary)
                .frame(width: 14 * s, height: 32 * s)
                .rotationEffect(.degrees(25))
                .offset(x: -30 * s, y: 38 * s)

            RoundedRectangle(cornerRadius: 4 * s)
                .fill(JuntoColors.primary)
                .frame(width: 14 * s, height: 32 * s)
                .rotationEffect(.degrees(-25))
                .offset(x: 30 * s, y: 38 * s)

            // Pernas
            RoundedRectangle(cornerRadius: 4 * s)
                .fill(JuntoColors.primary)
                .frame(width: 14 * s, height: 34 * s)
                .rotationEffect(.degrees(-8))
                .offset(x: -11 * s, y: 86 * s)

            RoundedRectangle(cornerRadius: 4 * s)
                .fill(JuntoColors.primary)
                .frame(width: 14 * s, height: 34 * s)
                .rotationEffect(.degrees(8))
                .offset(x: 11 * s, y: 86 * s)
        }
        .frame(width: size, height: size)
        .clipped()
    }
}

// MARK: - Ilustração Estado Vazio: Grupos
// Dois bonecos + ícone de grupo
struct EmptyGroupsIllustration: View {
    var size: CGFloat = 220

    var body: some View {
        let s = size / 220

        ZStack {
            // Fundo círculo
            Circle()
                .fill(JuntoColors.primaryLight)
                .frame(width: size * 0.88, height: size * 0.88)

            // Boneco esquerdo (menor / secundário)
            Group {
                // Cabeça esq
                Circle()
                    .fill(JuntoColors.primary.opacity(0.5))
                    .frame(width: 28 * s, height: 28 * s)
                    .offset(x: -48 * s, y: 0)
                // Corpo esq
                Capsule()
                    .fill(JuntoColors.primary.opacity(0.5))
                    .frame(width: 24 * s, height: 38 * s)
                    .offset(x: -48 * s, y: 36 * s)
            }

            // Boneco direito (menor / secundário)
            Group {
                // Cabeça dir
                Circle()
                    .fill(JuntoColors.primary.opacity(0.5))
                    .frame(width: 28 * s, height: 28 * s)
                    .offset(x: 48 * s, y: 0)
                // Corpo dir
                Capsule()
                    .fill(JuntoColors.primary.opacity(0.5))
                    .frame(width: 24 * s, height: 38 * s)
                    .offset(x: 48 * s, y: 36 * s)
            }

            // Boneco central (principal)
            // Corpo
            Capsule()
                .fill(JuntoColors.primary)
                .frame(width: 44 * s, height: 50 * s)
                .offset(y: 42 * s)

            // Cabeça
            Circle()
                .fill(JuntoColors.primary)
                .frame(width: 40 * s, height: 40 * s)
                .offset(y: 8 * s)

            // Olhos
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 8 * s, height: 8 * s)
                .offset(x: -7 * s, y: 6 * s)

            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 8 * s, height: 8 * s)
                .offset(x: 7 * s, y: 6 * s)

            // Sorriso
            Arc(startAngle: .degrees(10), endAngle: .degrees(170), clockwise: false)
                .stroke(Color.white, lineWidth: 2 * s)
                .frame(width: 14 * s, height: 7 * s)
                .offset(y: 15 * s)

            // Braços
            RoundedRectangle(cornerRadius: 4 * s)
                .fill(JuntoColors.primary)
                .frame(width: 12 * s, height: 28 * s)
                .rotationEffect(.degrees(30))
                .offset(x: -32 * s, y: 36 * s)

            RoundedRectangle(cornerRadius: 4 * s)
                .fill(JuntoColors.primary)
                .frame(width: 12 * s, height: 28 * s)
                .rotationEffect(.degrees(-30))
                .offset(x: 32 * s, y: 36 * s)

            // Pernas
            RoundedRectangle(cornerRadius: 4 * s)
                .fill(JuntoColors.primary)
                .frame(width: 12 * s, height: 30 * s)
                .rotationEffect(.degrees(-6))
                .offset(x: -10 * s, y: 82 * s)

            RoundedRectangle(cornerRadius: 4 * s)
                .fill(JuntoColors.primary)
                .frame(width: 12 * s, height: 30 * s)
                .rotationEffect(.degrees(6))
                .offset(x: 10 * s, y: 82 * s)

            // Ícone de link/grupo acima
            ZStack {
                Circle()
                    .fill(JuntoColors.accent)
                    .frame(width: 28 * s, height: 28 * s)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 12 * s, weight: .medium))
                    .foregroundColor(.white)
            }
            .offset(y: -66 * s)
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
