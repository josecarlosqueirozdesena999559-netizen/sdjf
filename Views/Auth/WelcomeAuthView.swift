import SwiftUI

struct WelcomeAuthView: View {
    @EnvironmentObject var store: JuntoStore

    var body: some View {
        ZStack {
            JuntoColors.warmBg.ignoresSafeArea()

            // Ondas presas no rodapé real da tela (cobre a safe area, sem faixa branca)
            VStack(spacing: 0) {
                Spacer()
                JuntoBottomWaves()
                    .frame(height: 150)
            }
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    JuntoLogoMark(size: 88)

                    Text("Juntô")
                        .font(.inter(28, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)

                    Text("Divida rolês, viagens e contas\nsem estresse.")
                        .font(.inter(15, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                        .multilineTextAlignment(.center)
                }

                Spacer().frame(height: 52)

                VStack(spacing: 12) {
                    JuntoPillButton(title: "Criar conta", color: JuntoColors.primary) {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            store.route = .registerFlow
                        }
                    }

                    JuntoOutlineButton(title: "Entrar", color: JuntoColors.primary) {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            store.route = .login
                        }
                    }
                }
                .padding(.horizontal, 32)

                HStack(spacing: 8) {
                    Text("Termos").underline()
                    Text("·")
                    Text("Privacidade").underline()
                    Text("·")
                    Text("Fale conosco").underline()
                }
                .font(.inter(12, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
                .padding(.top, 24)

                Spacer()
                Spacer().frame(height: 150)
            }
        }
    }
}

private struct JuntoBottomWaves: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Camada areia
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.30))
                    p.addCurve(
                        to: CGPoint(x: w, y: h * 0.22),
                        control1: CGPoint(x: w * 0.30, y: h * 0.02),
                        control2: CGPoint(x: w * 0.65, y: h * 0.48)
                    )
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.closeSubpath()
                }
                .fill(JuntoColors.sand)

                // Camada manga
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.55))
                    p.addCurve(
                        to: CGPoint(x: w, y: h * 0.42),
                        control1: CGPoint(x: w * 0.35, y: h * 0.30),
                        control2: CGPoint(x: w * 0.70, y: h * 0.70)
                    )
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.closeSubpath()
                }
                .fill(JuntoColors.accent)

                // Camada azul-noite
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.78))
                    p.addCurve(
                        to: CGPoint(x: w, y: h * 0.66),
                        control1: CGPoint(x: w * 0.40, y: h * 0.58),
                        control2: CGPoint(x: w * 0.72, y: h * 0.90)
                    )
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.closeSubpath()
                }
                .fill(JuntoColors.primary)
            }
        }
    }
}
