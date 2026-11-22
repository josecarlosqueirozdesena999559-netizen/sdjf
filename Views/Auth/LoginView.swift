import SwiftUI

struct LoginView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var identifier: String = "lucas.silva"
    @State private var password: String = "123456"

    var body: some View {
        ZStack {
            AnimatedRoleBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer().frame(height: 24)

                    // Brand Badge Flat
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(JuntoColors.primary)
                                .frame(width: 30, height: 30)
                            Text("J")
                                .font(.inter(16, weight: .heavy))
                                .foregroundColor(.white)
                        }
                        Text("Juntô")
                            .font(.inter(18, weight: .heavy))
                            .foregroundColor(JuntoColors.textMain)

                        Text("O App do Rolê")
                            .font(.inter(11, weight: .semibold))
                            .foregroundColor(JuntoColors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(JuntoColors.primaryLight)
                            .cornerRadius(6)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 99)
                            .stroke(JuntoColors.border, lineWidth: 1)
                    )
                    .cornerRadius(99)

                    // Headline
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Juntô a galera.\nZero estresse na conta.")
                            .font(.inter(28, weight: .heavy))
                            .foregroundColor(JuntoColors.textMain)
                            .lineSpacing(2)

                        Text("Divida o churrasco, a viagem ou o bar com Pote Coletivo e Pix instantâneo.")
                            .font(.inter(14, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                    }

                    // Flat Auth Card
                    VStack(spacing: 16) {
                        FlatInputField(
                            label: "E-mail ou @usuário",
                            placeholder: "seu@email.com ou @usuario",
                            text: $identifier,
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )

                        FlatSecureField(
                            label: "Senha",
                            placeholder: "Digite sua senha",
                            text: $password
                        )

                        JuntoPrimaryButton(title: "Entrar no Juntô", icon: "arrow.right") {
                            store.login(identifier: identifier)
                        }
                        .padding(.top, 6)
                    }
                    .padding(22)
                    .background(JuntoColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(JuntoColors.border, lineWidth: 1)
                    )
                    .cornerRadius(14)

                    // Link Cadastro
                    HStack {
                        Spacer()
                        Text("Ainda não tem conta?")
                            .font(.inter(14))
                            .foregroundColor(JuntoColors.textMuted)
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                store.route = .registerStep1
                            }
                        } label: {
                            Text("Criar conta")
                                .font(.inter(14, weight: .bold))
                                .foregroundColor(JuntoColors.primary)
                        }
                        Spacer()
                    }
                    .padding(.top, 4)

                    Spacer()
                }
                .padding(.horizontal, 22)
            }
        }
    }
}
