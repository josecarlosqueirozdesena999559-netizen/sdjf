import SwiftUI

struct RegisterStep1View: View {
    @EnvironmentObject var store: JuntoStore

    var body: some View {
        ZStack {
            AnimatedRoleBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // Header Passo 1
                    HStack {
                        Button {
                            withAnimation { store.route = .login }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JuntoColors.textMain)
                                .frame(width: 40, height: 40)
                                .background(Color.white)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(JuntoColors.border, lineWidth: 1))
                                .cornerRadius(10)
                        }

                        Spacer()

                        Text("Passo 1 de 2")
                            .font(.inter(12, weight: .bold))
                            .foregroundColor(JuntoColors.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(JuntoColors.primaryLight)
                            .cornerRadius(8)
                    }
                    .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Crie sua conta no Juntô")
                            .font(.inter(26, weight: .heavy))
                            .foregroundColor(JuntoColors.textMain)

                        Text("Escolha um @usuário único para seus amigos te chamarem pros rolês.")
                            .font(.inter(14))
                            .foregroundColor(JuntoColors.textMuted)
                    }

                    // Card Claro Flat
                    VStack(spacing: 16) {
                        FlatInputField(
                            label: "E-mail",
                            placeholder: "exemplo@gmail.com",
                            text: $store.draftEmail,
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )

                        // Campo de Nome de Usuário com Verificação ao Vivo
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Nome de usuário")
                                    .font(.inter(13, weight: .semibold))
                                    .foregroundColor(JuntoColors.textMain)
                                Spacer()
                                usernameStatusBadge
                            }

                            HStack(spacing: 6) {
                                Text("@")
                                    .font(.inter(15, weight: .bold))
                                    .foregroundColor(JuntoColors.primary)

                                TextField("ex: joao.silva", text: $store.draftUsername)
                                    .font(.inter(14, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .onChange(of: store.draftUsername) { _, newValue in
                                        store.checkUsername(newValue)
                                    }
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(JuntoColors.bgMain)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(usernameBorderColor, lineWidth: 1.2)
                            )
                            .cornerRadius(8)
                        }

                        FlatSecureField(
                            label: "Senha",
                            placeholder: "Mínimo 6 caracteres",
                            text: $store.draftPassword
                        )

                        JuntoPrimaryButton(title: "Próximo", icon: "arrow.right") {
                            store.advanceToRegisterStep2()
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

                    HStack {
                        Spacer()
                        Text("Já possui conta?")
                            .font(.inter(14))
                            .foregroundColor(JuntoColors.textMuted)
                        Button {
                            withAnimation { store.route = .login }
                        } label: {
                            Text("Entrar")
                                .font(.inter(14, weight: .bold))
                                .foregroundColor(JuntoColors.primary)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
            }
        }
    }

    private var usernameBorderColor: Color {
        switch store.usernameState {
        case .available: return JuntoColors.secondary
        case .unavailable: return JuntoColors.danger
        default: return JuntoColors.border
        }
    }

    @ViewBuilder
    private var usernameStatusBadge: some View {
        switch store.usernameState {
        case .idle:
            EmptyView()
        case .tooShort:
            Text("Mín. 3 caracteres")
                .font(.inter(11, weight: .semibold))
                .foregroundColor(JuntoColors.textMuted)
        case .checking:
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.65)
                Text("Verificando...")
                    .font(.inter(11, weight: .semibold))
                    .foregroundColor(JuntoColors.textMuted)
            }
        case .available:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                Text("Disponível!")
            }
            .font(.inter(11, weight: .bold))
            .foregroundColor(JuntoColors.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(JuntoColors.secondaryLight)
            .cornerRadius(6)
        case .unavailable:
            HStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                Text("Indisponível")
            }
            .font(.inter(11, weight: .bold))
            .foregroundColor(JuntoColors.danger)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(JuntoColors.dangerLight)
            .cornerRadius(6)
        }
    }
}
