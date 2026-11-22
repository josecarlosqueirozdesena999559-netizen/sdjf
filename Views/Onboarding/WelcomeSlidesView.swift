import SwiftUI

struct WelcomeSlidesView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var currentPage = 0
    @State private var floatAnim = false

    private let slides: [(icon: String, tint: Color, bg: Color, title: String, desc: String)] = [
        (
            "tray.and.arrow.down.fill",
            JuntoColors.primary,
            JuntoColors.primaryLight,
            "O Pote Coletivo do Rolê",
            "A galera junta a grana antes da festa ou viagem. O que sobrar no final volta por Pix automaticamente."
        ),
        (
            "doc.text.viewfinder",
            JuntoColors.secondary,
            JuntoColors.secondaryLight,
            "Comanda Visual com IA",
            "Tirou foto da conta do bar? Cada amigo toca só no chopp e petisco que consumiu, com 10% automático."
        ),
        (
            "bolt.circle.fill",
            JuntoColors.accent,
            JuntoColors.accentLight,
            "Pix Instantâneo Sem Estresse",
            "Acabou a vergonha de cobrar. Um toque gera o Pix exato e dá baixa automática em segundos."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Cabeçalho de Boas-Vindas Personalizado
            VStack(spacing: 8) {
                Text("✨ Tudo pronto!")
                    .font(.inter(12, weight: .bold))
                    .foregroundColor(JuntoColors.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(JuntoColors.primaryLight)
                    .cornerRadius(99)

                Text("Bem-vindo ao Juntô,\n\(store.user.firstName)!")
                    .font(.inter(26, weight: .heavy))
                    .foregroundColor(JuntoColors.textMain)
                    .multilineTextAlignment(.center)

                Text("Deslize para conhecer o novo jeito de curtir sem treta.")
                    .font(.inter(14))
                    .foregroundColor(JuntoColors.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 36)
            .padding(.horizontal, 24)

            // Carrossel de Slides com Animação Flat
            TabView(selection: $currentPage) {
                ForEach(Array(slides.enumerated()), id: \.offset) { idx, slide in
                    VStack(spacing: 22) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 28)
                                .fill(slide.bg)
                                .frame(width: 190, height: 190)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28)
                                        .stroke(slide.tint.opacity(0.2), lineWidth: 1.5)
                                )

                            // Animação flat suave de flutuação
                            Image(systemName: slide.icon)
                                .font(.system(size: 74, weight: .semibold))
                                .foregroundColor(slide.tint)
                                .offset(y: floatAnim ? -8 : 8)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: floatAnim)
                        }

                        VStack(spacing: 10) {
                            Text(slide.title)
                                .font(.inter(20, weight: .heavy))
                                .foregroundColor(JuntoColors.textMain)
                                .multilineTextAlignment(.center)

                            Text(slide.desc)
                                .font(.inter(14))
                                .foregroundColor(JuntoColors.textMuted)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                                .padding(.horizontal, 28)
                        }
                    }
                    .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onAppear { floatAnim = true }

            // Indicadores Flat
            HStack(spacing: 8) {
                ForEach(0..<slides.count, id: \.self) { idx in
                    Capsule()
                        .fill(currentPage == idx ? JuntoColors.primary : JuntoColors.border)
                        .frame(width: currentPage == idx ? 26 : 8, height: 8)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
            .padding(.bottom, 26)

            // Botão Ir ao Início
            VStack(spacing: 12) {
                JuntoPrimaryButton(title: "Ir ao Início", icon: "arrow.right") {
                    store.finishWelcome()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .background(JuntoColors.surface.ignoresSafeArea())
    }
}
