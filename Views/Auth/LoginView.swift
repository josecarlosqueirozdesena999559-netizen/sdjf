import SwiftUI

enum LoginStep {
    case username
    case password
}

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var step: LoginStep = .username
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header for internal navigation
            HStack {
                Button(action: {
                    if step == .password {
                        withAnimation { step = .username }
                    } else {
                        dismiss()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Voltar")
                    }
                    .foregroundColor(Theme.primary)
                }
                Spacer()
            }
            .padding()
            
            VStack(alignment: .leading, spacing: 24) {
                if step == .username {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Qual é o seu usuário?")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textPrimary)
                    }
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                    
                    CustomTextField(title: "Nome de usuário", placeholder: "@nomedeusuario", text: $username, keyboardType: .default)
                        .autocapitalization(.none)
                        .transition(.opacity)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation { step = .password }
                    }) {
                        Text("Continuar")
                            .font(.headline)
                            .foregroundColor(username.isEmpty ? .gray : .white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(username.isEmpty ? Color.gray.opacity(0.2) : Theme.primary)
                            .cornerRadius(12)
                    }
                    .disabled(username.isEmpty)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Digite sua senha")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textPrimary)
                        Text("Quase lá! Insira sua senha para acessar.")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    
                    CustomTextField(title: "Senha", placeholder: "Sua senha secreta", text: $password, isSecure: true)
                        .transition(.opacity)
                    
                    HStack {
                        Spacer()
                        NavigationLink(destination: ForgotPasswordView()) {
                            Text("Esqueceu a senha?")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Theme.primary)
                        }
                    }
                    
                    if let error = authViewModel.errorMessage, !error.isEmpty {
                        Text(error)
                            .foregroundColor(Theme.error)
                            .font(.subheadline)
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await authViewModel.login(emailOrUsername: username, password: password)
                        }
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.primary)
                                .cornerRadius(12)
                        } else {
                            Text("Entrar")
                                .font(.headline)
                                .foregroundColor(password.isEmpty ? .gray : .white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(password.isEmpty ? Color.gray.opacity(0.2) : Theme.primary)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(password.isEmpty || authViewModel.isLoading)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}


