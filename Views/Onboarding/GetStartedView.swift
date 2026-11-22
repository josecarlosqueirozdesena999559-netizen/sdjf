import SwiftUI

/// Tela pós-cadastro: painel de primeiros passos profissional e único do Juntô
struct GetStartedView: View {
    @EnvironmentObject var store: JuntoStore

    var body: some View {
        ZStack {
            JuntoColors.warmBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Cabeçalho com avatar gerado
                    HStack(spacing: 12) {
                        GeometricAvatarView(seed: store.user.username, size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Conta criada")
                                .font(.inter(13, weight: .regular))
                                .foregroundColor(JuntoColors.pixGreen)
                            Text("Olá, \(store.user.firstName)")
                                .font(.inter(20, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                        }
                        Spacer()
                    }
                    .padding(.top, 20)

                    // Cartão-herói azul-noite
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(JuntoColors.primary)

                        HStack(alignment: .bottom, spacing: 0) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("PRIMEIROS PASSOS")
                                    .font(.inter(11, weight: .medium))
                                    .tracking(1.2)
                                    .foregroundColor(JuntoColors.accent)
                                Text("Monte seu primeiro grupo e convide a galera.")
                                    .font(.inter(18, weight: .medium))
                                    .foregroundColor(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("Leva menos de 1 minuto.")
                                    .font(.inter(13, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(20)

                            Spacer(minLength: 0)

                            Image("OnbFriends")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 130)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(12)
                        }
                    }
                    .frame(height: 170)
                    .padding(.top, 22)

                    // Progresso de configuração
                    HStack(spacing: 10) {
                        progressStep(done: true, title: "Conta")
                        progressStep(done: false, title: "Grupo")
                        progressStep(done: false, title: "Amigos")
                    }
                    .padding(.top, 18)

                    Text("O que você quer fazer primeiro?")
                        .font(.inter(15, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                        .padding(.top, 26)
                        .padding(.bottom, 12)

                    VStack(spacing: 10) {
                        optionCard(
                            icon: "airplane",
                            tint: JuntoColors.accent,
                            title: "Criar uma viagem ou rolê",
                            subtitle: "Com Pote Coletivo e Comanda IA"
                        ) {
                            store.startApp(openingGroupCategory: "Viagem")
                        }

                        optionCard(
                            icon: "house",
                            tint: JuntoColors.linkBlue,
                            title: "Organizar contas de casa",
                            subtitle: "Aluguel, internet e mercado"
                        ) {
                            store.startApp(openingGroupCategory: "Casa")
                        }

                        optionCard(
                            icon: "person.badge.plus",
                            tint: JuntoColors.pixGreen,
                            title: "Adicionar amigos",
                            subtitle: "Convide pelo @usuário"
                        ) {
                            store.startApp(openingGroupCategory: nil)
                        }
                    }

                    Button {
                        store.startApp(openingGroupCategory: nil)
                    } label: {
                        Text("Pular por enquanto")
                            .font(.inter(14, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                    }
                }
                .padding(.horizontal, 22)
            }
        }
    }

    private func progressStep(done: Bool, title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(done ? JuntoColors.accent : JuntoColors.border)
                .frame(height: 4)
            HStack(spacing: 4) {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 11))
                    .foregroundColor(done ? JuntoColors.pixGreen : JuntoColors.textLight)
                Text(title)
                    .font(.inter(12, weight: .regular))
                    .foregroundColor(done ? JuntoColors.textMain : JuntoColors.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func optionCard(icon: String, tint: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(tint)
                    .frame(width: 44, height: 44)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.inter(15, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Text(subtitle)
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(JuntoColors.textLight)
            }
            .padding(14)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(JuntoColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
