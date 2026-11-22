import SwiftUI

struct WelcomeAuthView: View {
    @EnvironmentObject var store: JuntoStore

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()

            // Base geométrica minimalista (inspirada no modelo, paleta própria Juntô)
            GeometricFooterFacets()
                .frame(height: 82)
                .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 0) {
                Spacer()

                // Logo Geométrica Autoral + Nome Juntô (sem bold pesado)
                VStack(spacing: 14) {
                    JuntoLogoMark(size: 92)

                    Text("Juntô")
                        .font(.inter(24, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                }

                Spacer().frame(height: 64)

                // Botões em pílula exatamente como no modelo
                VStack(spacing: 20) {
                    JuntoPillButton(title: "Cadastrar-se", color: JuntoColors.primary) {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            store.route = .registerStep1
                        }
                    }

                    JuntoPillButton(title: "Entrar", color: JuntoColors.darkButton) {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            store.route = .login
                        }
                    }
                }
                .padding(.horizontal, 48)

                // Links legais discretos
                HStack(spacing: 8) {
                    Text("Termos").underline()
                    Text("|")
                    Text("Política de privacidade").underline()
                    Text("|")
                    Text("Fale conosco").underline()
                }
                .font(.inter(12, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
                .padding(.top, 30)

                Spacer()
                Spacer().frame(height: 60)
            }
        }
    }
}

private struct GeometricFooterFacets: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Esquerda grafite
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.22))
                    p.addLine(to: CGPoint(x: w * 0.22, y: h))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.closeSubpath()
                }
                .fill(Color(hex: "#32373D"))

                // Centro-esquerda lilás suave
                Path { p in
                    p.move(to: CGPoint(x: w * 0.11, y: h))
                    p.addLine(to: CGPoint(x: w * 0.34, y: h * 0.28))
                    p.addLine(to: CGPoint(x: w * 0.56, y: h))
                    p.closeSubpath()
                }
                .fill(Color(hex: "#A569E6"))

                Path { p in
                    p.move(to: CGPoint(x: w * 0.34, y: h * 0.28))
                    p.addLine(to: CGPoint(x: w * 0.56, y: h))
                    p.addLine(to: CGPoint(x: w * 0.34, y: h))
                    p.closeSubpath()
                }
                .fill(Color(hex: "#C59BF2"))

                // Centro-direita esmeralda
                Path { p in
                    p.move(to: CGPoint(x: w * 0.49, y: h))
                    p.addLine(to: CGPoint(x: w * 0.62, y: h * 0.36))
                    p.addLine(to: CGPoint(x: w * 0.77, y: h))
                    p.closeSubpath()
                }
                .fill(Color(hex: "#19B68E"))

                Path { p in
                    p.move(to: CGPoint(x: w * 0.62, y: h * 0.36))
                    p.addLine(to: CGPoint(x: w * 0.77, y: h))
                    p.addLine(to: CGPoint(x: w * 0.62, y: h))
                    p.closeSubpath()
                }
                .fill(Color(hex: "#138067"))

                // Direita coral
                Path { p in
                    p.move(to: CGPoint(x: w * 0.68, y: h))
                    p.addLine(to: CGPoint(x: w * 0.88, y: h * 0.25))
                    p.addLine(to: CGPoint(x: w * 1.05, y: h))
                    p.closeSubpath()
                }
                .fill(Color(hex: "#FF6B47"))

                Path { p in
                    p.move(to: CGPoint(x: w * 0.88, y: h * 0.25))
                    p.addLine(to: CGPoint(x: w * 1.05, y: h))
                    p.addLine(to: CGPoint(x: w * 0.88, y: h))
                    p.closeSubpath()
                }
                .fill(Color(hex: "#F2441D"))
            }
        }
    }
}
