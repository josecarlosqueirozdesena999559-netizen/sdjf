import SwiftUI

struct LoginView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var identifier: String = ""
    @State private var password: String = ""

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
                VStack(alignment: .leading, spacing: 22) {
                    Text("Entrar")
                        .font(.inter(24, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                        .padding(.top, 22)

                    CleanOutlineInput(
                        label: "Endereço de e-mail ou @usuário",
                        placeholder: "",
                        text: $identifier,
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )

                    CleanOutlineSecureInput(
                        label: "Senha",
                        placeholder: "",
                        text: $password
                    )

                    JuntoPillButton(title: "Entrar", color: JuntoColors.primary) {
                        store.login(identifier: identifier)
                    }
                    .padding(.top, 10)

                    HStack {
                        Spacer()
                        Button("Esqueceu sua senha?") {
                            store.showToast("Enviamos um link de recuperação para seu e-mail.", icon: "envelope")
                        }
                        .font(.inter(14, weight: .regular))
                        .foregroundColor(JuntoColors.primary)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 22)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}
