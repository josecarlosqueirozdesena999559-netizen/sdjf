import SwiftUI

/// Onboarding animado inspirado no vídeo enviado, com a identidade própria do Juntô
struct WelcomeSlidesView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var currentPage = 0
    @State private var animateCard = false

    var body: some View {
        ZStack {
            slideBackgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.35), value: currentPage)

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    slide1Welcome
                        .tag(0)
                    slide2Expenses
                        .tag(1)
                    slide3SettlePix
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Indicadores de página (3 pontinhos)
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { idx in
                        Circle()
                            .fill(currentPage == idx ? JuntoColors.primary : JuntoColors.primary.opacity(0.25))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, 16)

                // Botão "Feito" (como no vídeo) ou "Próximo"
                Button {
                    if currentPage < 2 {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentPage += 1
                        }
                    } else {
                        store.finishSlidesToGetStarted()
                    }
                } label: {
                    Text(currentPage == 2 ? "Feito" : "Continuar")
                        .font(.inter(16, weight: .medium))
                        .foregroundColor(JuntoColors.primary)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 28)
                }
                .padding(.bottom, 26)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                animateCard = true
            }
        }
    }

    private var slideBackgroundColor: Color {
        switch currentPage {
        case 0: return Color(hex: "#F5F7FF") // Azul-gelo quente suave
        case 1: return Color(hex: "#F0F9FF") // Celeste pastel
        default: return Color(hex: "#F2FBF7") // Menta pastel ultra suave
        }
    }

    // MARK: - Slide 1: Bem-vindo + Cartão vivo de saldos
    private var slide1Welcome: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Bem-vindo\nao Juntô,\n\(store.user.firstName)!")
                    .font(.inter(30, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                    .lineSpacing(2)

                Text("O Juntô organiza os saldos e o Pote Coletivo entre seus amigos.")
                    .font(.inter(15, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
            }
            .padding(.horizontal, 26)
            .padding(.top, 36)

            // Cartão de prévia vivo (igual ao vídeo, em BRL com nossa paleta!)
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 4) {
                        Text("No total, você recebe")
                            .font(.inter(14, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)
                        Text("R$ 134,64")
                            .font(.inter(14, weight: .medium))
                            .foregroundColor(JuntoColors.pixGreen)
                    }
                    Spacer()
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14))
                        .foregroundColor(JuntoColors.textMuted)
                }

                Divider()

                // Grupo 1
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(JuntoColors.primaryLight)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "sun.max")
                                .foregroundColor(JuntoColors.primary)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Viagem Ubatuba")
                            .font(.inter(14, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                        Text("Pedro te deve R$ 100,00")
                            .font(.inter(12, weight: .regular))
                            .foregroundColor(JuntoColors.pixGreen)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("você recebe")
                            .font(.inter(10, weight: .regular))
                            .foregroundColor(JuntoColors.pixGreen)
                        Text("R$ 100,00")
                            .font(.inter(13, weight: .medium))
                            .foregroundColor(JuntoColors.pixGreen)
                    }
                }

                // Grupo 2
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#FFF7ED"))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "house")
                                .foregroundColor(JuntoColors.orangeSave)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Contas do Apê")
                            .font(.inter(14, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                        Text("Você deve Matheus R$ 35,36")
                            .font(.inter(12, weight: .regular))
                            .foregroundColor(JuntoColors.orangeSave)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("você deve")
                            .font(.inter(10, weight: .regular))
                            .foregroundColor(JuntoColors.orangeSave)
                        Text("R$ 35,36")
                            .font(.inter(13, weight: .medium))
                            .foregroundColor(JuntoColors.orangeSave)
                    }
                }
            }
            .padding(18)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 14, y: 6)
            .padding(.horizontal, 24)
            .offset(y: animateCard ? 0 : 24)
            .opacity(animateCard ? 1 : 0)

            Spacer()

            // Cena flat minimalista de praia / pôr do sol na base
            ZStack(alignment: .bottom) {
                Circle()
                    .fill(Color(hex: "#FDE68A").opacity(0.65))
                    .frame(width: 110, height: 110)
                    .offset(y: -30)

                HStack(alignment: .bottom, spacing: 30) {
                    Image(systemName: "beach.umbrella")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundColor(JuntoColors.primary)
                    Image(systemName: "figure.2.arms.open")
                        .font(.system(size: 42, weight: .thin))
                        .foregroundColor(JuntoColors.textMain)
                    Image(systemName: "water.waves")
                        .font(.system(size: 36, weight: .thin))
                        .foregroundColor(JuntoColors.primaryAccent)
                }
                .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
        }
    }

    // MARK: - Slide 2: Adicione despesas e Pote
    private var slide2Expenses: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Adicione despesas")
                    .font(.inter(28, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)

                Text("Divida gastos com grupos, use o Pote Coletivo ou escaneie a comanda com IA.")
                    .font(.inter(15, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
            }
            .padding(.horizontal, 26)
            .padding(.top, 50)

            Spacer()

            // Cartão ilustrativo animado de Pote + Comanda
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "tray.and.arrow.down")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(JuntoColors.primary)
                        .frame(width: 48, height: 48)
                        .background(JuntoColors.primaryLight)
                        .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Pote Coletivo • Churrasco")
                            .font(.inter(15, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                        Text("Saldo disponível: R$ 180,00")
                            .font(.inter(13, weight: .regular))
                            .foregroundColor(JuntoColors.pixGreen)
                    }
                    Spacer()
                }

                Divider()

                HStack(spacing: 12) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(JuntoColors.proIndigo)
                        .frame(width: 48, height: 48)
                        .background(JuntoColors.proBgLight)
                        .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Comanda Inteligente IA")
                            .font(.inter(15, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                        Text("Toque apenas no que você consumiu")
                            .font(.inter(13, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                    }
                    Spacer()
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 14, y: 6)
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Slide 3: Acerte tudo via Pix (mesa vista de cima + card deslizando!)
    private var slide3SettlePix: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Acerte via Pix")
                    .font(.inter(28, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)

                Text("Pague seus amigos a qualquer hora com Pix instantâneo e baixa automática.")
                    .font(.inter(15, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
            }
            .padding(.horizontal, 26)
            .padding(.top, 50)

            Spacer()

            ZStack {
                // Ilustração flat vista de cima da mesa de amigos
                Circle()
                    .fill(JuntoColors.primaryAccent.opacity(0.22))
                    .frame(width: 240, height: 240)
                    .offset(x: -55, y: -10)

                Circle()
                    .fill(Color.white)
                    .frame(width: 96, height: 96)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.system(size: 30, weight: .thin))
                            .foregroundColor(JuntoColors.orangeSave)
                    )
                    .offset(x: -55, y: -10)

                // Card de pagamento Pix deslizando (exatamente como aos 00:05 do vídeo!)
                VStack(spacing: 12) {
                    HStack(spacing: 14) {
                        GeometricAvatarView(seed: store.user.username, size: 42)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)
                        GeometricAvatarView(seed: "pedro.santos", size: 42)
                    }

                    Text("Você pagou Pedro S. via Pix")
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)

                    HStack(spacing: 4) {
                        Text("R$")
                            .font(.inter(16, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                        Text("105,36")
                            .font(.inter(24, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                    }
                    .padding(.bottom, 4)
                    .overlay(
                        Rectangle()
                            .fill(JuntoColors.pixGreen)
                            .frame(height: 1.5),
                        alignment: .bottom
                    )
                }
                .padding(20)
                .frame(width: 225)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.09), radius: 16, y: 6)
                .offset(x: 42, y: 62)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 280)

            Spacer()
        }
    }
}
