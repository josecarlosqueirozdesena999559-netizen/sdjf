import SwiftUI

struct WelcomeSlidesView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var currentPage = 0
    @State private var floatAnim = false

    private let slides: [(icon: String, title: String, desc: String)] = [
        (
            "tray.and.arrow.down",
            "Pote Coletivo do Rolê",
            "Junte o valor com seus amigos antes da viagem ou churrasco. O que sobrar volta por Pix."
        ),
        (
            "doc.text.viewfinder",
            "Comanda Inteligente",
            "Separe os itens do restaurante em segundos e pague apenas o que você realmente consumiu."
        ),
        (
            "bolt.circle",
            "Pix instantâneo",
            "Quite suas partes com um toque via Pix Copia e Cola, com baixa automática e sem constrangimento."
        )
    ]

    var body: some View {
        ZStack {
            SubtleFacetBackground()

            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    JuntoLogoMark(size: 54)
                        .padding(.bottom, 6)

                    Text("Bem-vindo(a) ao Juntô, \(store.user.firstName)!")
                        .font(.inter(20, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 46)
                .padding(.horizontal, 24)

                TabView(selection: $currentPage) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { idx, slide in
                        VStack(spacing: 24) {
                            ZStack {
                                Circle()
                                    .fill(JuntoColors.primaryLight)
                                    .frame(width: 150, height: 150)

                                Image(systemName: slide.icon)
                                    .font(.system(size: 56, weight: .thin))
                                    .foregroundColor(JuntoColors.primary)
                                    .offset(y: floatAnim ? -6 : 6)
                                    .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: floatAnim)
                            }

                            VStack(spacing: 8) {
                                Text(slide.title)
                                    .font(.inter(19, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)

                                Text(slide.desc)
                                    .font(.inter(14, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(3)
                                    .padding(.horizontal, 34)
                            }
                        }
                        .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onAppear { floatAnim = true }

                HStack(spacing: 8) {
                    ForEach(0..<slides.count, id: \.self) { idx in
                        Capsule()
                            .fill(currentPage == idx ? JuntoColors.primary : JuntoColors.border)
                            .frame(width: currentPage == idx ? 22 : 7, height: 7)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, 28)

                JuntoPillButton(title: "Ir ao início", color: JuntoColors.primary) {
                    store.finishWelcome()
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 34)
            }
        }
    }
}
