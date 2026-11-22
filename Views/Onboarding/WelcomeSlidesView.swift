import SwiftUI

/// Onboarding com ilustrações próprias do Juntô (no estilo do vídeo de referência, não cópia)
struct WelcomeSlidesView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var currentPage = 0
    @State private var appear = false

    private struct Slide {
        let image: String
        let title: String
        let text: String
        let chipIcon: String
        let chipTitle: String
        let chipValue: String
        let chipColor: Color
    }

    private var slides: [Slide] {
        [
            Slide(
                image: "OnbFriends",
                title: "Bem-vindo ao Juntô, \(store.user.firstName)",
                text: "Viagens, rolês e contas de casa organizados num só lugar, com saldos sempre claros.",
                chipIcon: "arrow.down.left",
                chipTitle: "No total, você recebe",
                chipValue: "R$ 134,64",
                chipColor: JuntoColors.pixGreen
            ),
            Slide(
                image: "OnbExpenses",
                title: "Lance despesas em segundos",
                text: "Escaneie a comanda, escolha quem participou e use o Pote Coletivo para juntar antes do rolê.",
                chipIcon: "flame.fill",
                chipTitle: "Pote do churrasco",
                chipValue: "R$ 180,00",
                chipColor: JuntoColors.accent
            ),
            Slide(
                image: "OnbPix",
                title: "Acerte tudo com Pix",
                text: "Um toque gera o Pix com o valor exato e a dívida é baixada automaticamente.",
                chipIcon: "checkmark.seal.fill",
                chipTitle: "Pagamento confirmado",
                chipValue: "R$ 105,36",
                chipColor: JuntoColors.pixGreen
            )
        ]
    }

    var body: some View {
        ZStack {
            JuntoColors.warmBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Topo limpo sem a logo do Juntô (apenas Pular)
                HStack {
                    Spacer()
                    if currentPage < slides.count - 1 {
                        Button("Pular") { store.finishSlidesToGetStarted() }
                            .font(.inter(14, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                    } else {
                        Text(" ").font(.inter(14))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)

                TabView(selection: $currentPage) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { idx, slide in
                        slideView(slide).tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Indicadores retangulares
                HStack(spacing: 6) {
                    ForEach(0..<slides.count, id: \.self) { idx in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(currentPage == idx ? JuntoColors.primary : JuntoColors.border)
                            .frame(width: currentPage == idx ? 24 : 10, height: 4)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, 22)

                JuntoPillButton(
                    title: currentPage == slides.count - 1 ? "Começar" : "Continuar",
                    color: JuntoColors.primary
                ) {
                    if currentPage < slides.count - 1 {
                        withAnimation(.easeInOut(duration: 0.25)) { currentPage += 1 }
                    } else {
                        store.finishSlidesToGetStarted()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func slideView(_ slide: Slide) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Image(slide.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)

                // Cartão flutuante com dado vivo
                HStack(spacing: 10) {
                    Image(systemName: slide.chipIcon)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(slide.chipColor)
                        .frame(width: 32, height: 32)
                        .background(slide.chipColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(slide.chipTitle)
                            .font(.inter(12, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                        Text(slide.chipValue)
                            .font(.inter(15, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.07), radius: 12, y: 4)
                .padding(.leading, 28)
                .offset(y: 18)
            }
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 10) {
                Text(slide.title)
                    .font(.inter(26, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                    .fixedSize(horizontal: false, vertical: true)

                Text(slide.text)
                    .font(.inter(15, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 26)
            .padding(.top, 44)

            Spacer()
        }
    }
}
