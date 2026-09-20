import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .padding(.top, 40)
            
            VStack(spacing: 8) {
                Text("Entrar")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Acesse sua conta para continuar")
                    .foregroundColor(Theme.textSecondary)
            }
            
            VStack(spacing: 16) {
                CustomTextField(title: "Nome de usuário", placeholder: "@nomedeusuario", text: $username, keyboardType: .default)
                CustomTextField(title: "Senha", placeholder: "Sua senha", text: $password, isSecure: true)
            }
            
            HStack {
                Spacer()
                NavigationLink(destination: ForgotPasswordView()) {
                    Text("Esqueci minha senha")
                        .font(.subheadline)
                        .foregroundColor(Theme.primary)
                }
            }
            
            if let error = authViewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if authViewModel.isLoading {
                ProgressView()
            } else {
                PrimaryButton(title: "Entrar") {
                    authViewModel.login(emailOrUsername: username, password: password)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Theme.background.ignoresSafeArea())
        .customBackButton()
    }
}


