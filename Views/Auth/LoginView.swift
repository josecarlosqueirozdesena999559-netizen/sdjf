import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "bag.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(Theme.primary)
                    .padding(.top, 40)
                
                VStack(spacing: 8) {
                    Text("Entrar")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Acesse sua conta para continuar")
                        .foregroundColor(Theme.textSecondary)
                }
                
                VStack(spacing: 16) {
                    CustomTextField(title: "UsuÃ¡rio, E-mail ou Telefone", placeholder: "@seu.usuario ou email", text: $email, keyboardType: .emailAddress)
                    CustomTextField(title: "Senha", placeholder: "Sua senha", text: $password, isSecure: true)
                }
                
                HStack {
                    Spacer()
                    Button("Esqueci minha senha") {
                        // Action
                    }
                    .font(.subheadline)
                    .foregroundColor(Theme.primary)
                }
                
                PrimaryButton(title: "Entrar") {
                    authViewModel.login(emailOrUsername: email, password: password)
                }
                

                
                HStack {
                    Text("Ainda nÃ£o possui uma conta?")
                        .foregroundColor(Theme.textSecondary)
                    NavigationLink("Criar conta", destination: RegisterView())
                        .foregroundColor(Theme.primary)
                        .fontWeight(.semibold)
                }
                .padding(.top, 16)
                
                Spacer()
            }
            .padding()
            .background(Theme.background.ignoresSafeArea())
        }
    }
}

