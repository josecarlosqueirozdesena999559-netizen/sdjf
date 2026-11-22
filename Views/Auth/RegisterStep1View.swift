import SwiftUI

struct RegisterStep1View: View {
    @EnvironmentObject var store: JuntoStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                CircleNavButton(icon: "chevron.left") {
                    withAnimation { store.route = .welcomeAuth }
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Cadastrar-se")
                        .font(.inter(24, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                        .padding(.top, 22)

                    CleanOutlineInput(
                        label: "Endereço de e-mail",
                        placeholder: "",
                        text: $store.draftEmail,
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )

                    // Nome de usuário com checagem em tempo real discreta e elegante
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text("Nome de usuário")
                                .font(.inter(13, weight: .regular))
                                .foregroundColor(JuntoColors.textMain)
                            Spacer()
                            usernameStatusLabel
                        }

                        HStack(spacing: 4) {
                            Text("@")
                                .font(.inter(15, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                            TextField("seu.usuario", text: $store.draftUsername)
                                .font(.inter(15, weight: .regular))
                                .foregroundColor(JuntoColors.textMain)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .onChange(of: store.draftUsername) { _, newValue in
                                    store.checkUsername(newValue)
                                }
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 50)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .stroke(usernameBorderColor, lineWidth: 1)
                        )
                    }

                    CleanOutlineSecureInput(
                        label: "Senha",
                        placeholder: "",
                        text: $store.draftPassword,
                        helperText: "Mínimo de 8 caracteres"
                    )

                    JuntoPillButton(title: "Próximo", color: JuntoColors.primary) {
                        store.advanceToRegisterStep2()
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }

    private var usernameBorderColor: Color {
        switch store.usernameState {
        case .available: return JuntoColors.primary
        case .unavailable: return JuntoColors.danger
        default: return JuntoColors.inputBorder
        }
    }

    @ViewBuilder
    private var usernameStatusLabel: some View {
        switch store.usernameState {
        case .idle:
            EmptyView()
        case .tooShort:
            Text("Mínimo 3 letras")
                .font(.inter(12, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
        case .checking:
            HStack(spacing: 4) {
                ProgressView().scaleEffect(0.65)
                Text("Verificando...")
                    .font(.inter(12, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
            }
        case .available:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle")
                Text("Disponível")
            }
            .font(.inter(12, weight: .medium))
            .foregroundColor(JuntoColors.primary)
        case .unavailable:
            HStack(spacing: 4) {
                Image(systemName: "xmark.circle")
                Text("Indisponível")
            }
            .font(.inter(12, weight: .medium))
            .foregroundColor(JuntoColors.danger)
        }
    }
}
