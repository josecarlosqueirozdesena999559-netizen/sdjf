import SwiftUI

struct WelcomeAuthView: View {
    @EnvironmentObject var store: JuntoStore

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()

            // Base autoral do Juntô: arcos suaves minimalistas (sem montanhas do Splitwise!)
            JuntoBottomWaves()
                .frame(height: 92)
                .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    JuntoLogoMark(size: 90)

                    Text("Juntô")
                        .font(.inter(26, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)

                    Text("Divida rolês, viagens e contas sem estresse.")
                        .font(.inter(14, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }

                Spacer().frame(height: 54)

                VStack(spacing: 16) {
                    JuntoPillButton(title: "Cadastrar-se", color: JuntoColors.primary) {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            store.route = .registerFlow
                        }
                    }

                    JuntoPillButton(title: "Entrar", color: JuntoColors.darkButton) {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            store.route = .login
                        }
                    }
                }
                .padding(.horizontal, 44)

                HStack(spacing: 8) {
                    Text("Termos").underline()
                    Text("|")
                    Text("Política de privacidade").underline()
                    Text("|")
                    Text("Fale conosco").underline()
                }
                .font(.inter(12, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
                .padding(.top, 28)

                Spacer()
                Spacer().frame(height: 64)
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
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.45))
                    p.addQuadCurve(to: CGPoint(x: w * 0.58, y: h * 0.32), control: CGPoint(x: w * 0.26, y: 0))
                    p.addQuadCurve(to: CGPoint(x: w, y: h * 0.52), control: CGPoint(x: w * 0.82, y: h * 0.60))
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.closeSubpath()
                }
                .fill(JuntoColors.primaryLight)

                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.72))
                    p.addQuadCurve(to: CGPoint(x: w * 0.52, y: h * 0.44), control: CGPoint(x: w * 0.25, y: h * 0.30))
                    p.addQuadCurve(to: CGPoint(x: w, y: h * 0.28), control: CGPoint(x: w * 0.78, y: h * 0.55))
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.closeSubpath()
                }
                .fill(JuntoColors.primary.opacity(0.18))

                Path { p in
                    p.move(to: CGPoint(x: w * 0.25, y: h))
                    p.addQuadCurve(to: CGPoint(x: w, y: h * 0.48), control: CGPoint(x: w * 0.68, y: h * 0.34))
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.closeSubpath()
                }
                .fill(JuntoColors.primary.opacity(0.88))
            }
        }
    }
}
