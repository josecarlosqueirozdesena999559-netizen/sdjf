import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
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
                    Button("Esqueci minha senha") {
                        // Action
                    }
                    .font(.subheadline)
                    .foregroundColor(Theme.primary)
                }
                
                if authViewModel.isLoading {
                    ProgressView()
                } else {
                    PrimaryButton(title: "Entrar") {
                        authViewModel.login(emailOrUsername: username, password: password)
                    }
                }
                HStack {
                    Text("Ainda não possui uma conta?")
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
            .alert(isPresented: Binding<Bool>(
                get: { authViewModel.errorMessage != nil },
                set: { if !$0 { authViewModel.errorMessage = nil } }
            )) {
                Alert(title: Text("Atenção"), message: Text(authViewModel.errorMessage ?? ""), dismissButton: .default(Text("OK")))
            }
        }
    }
}


