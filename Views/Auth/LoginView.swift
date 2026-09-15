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
                    CustomTextField(title: "E-mail ou telefone", placeholder: "Digite seu e-mail", text: $email, keyboardType: .emailAddress)
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
                    authViewModel.login()
                }
                
                HStack {
                    VStack { Divider() }
                    Text("ou").foregroundColor(Theme.textSecondary).font(.caption)
                    VStack { Divider() }
                }
                .padding(.vertical, 8)
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "applelogo")
                        Text("Continuar com Apple")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)
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
        }
    }
}
