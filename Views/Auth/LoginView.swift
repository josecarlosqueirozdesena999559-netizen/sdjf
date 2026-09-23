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
                        withAnimation(.easeInOut(duration: 0.25)) { step = .username }
                    } else {
                        dismiss()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .typographyButton()
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                    .foregroundColor(Theme.primary)
                }
                Spacer()
            }
            .padding()
            
            VStack(alignment: .leading, spacing: 24) {
                if step == .username {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Qual é o seu usuário?")
                            .typographyScreenTitle()
                            
                            .foregroundColor(Theme.textPrimary)
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    
                    CustomTextField(title: "Nome de usuário", placeholder: "@nomedeusuario", text: $username, keyboardType: .default)
                        .autocapitalization(.none)
                        .transition(.opacity)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) { step = .password }
                    }) {
                        Text("Continuar")
                            .typographySectionTitle()
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
                            .typographyScreenTitle()
                            
                            .foregroundColor(Theme.textPrimary)
                        Text("Quase lá! Insira sua senha para acessar.")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        CustomTextField(title: "Senha", placeholder: "Sua senha secreta", text: $password, isSecure: true)
                        
                        if let error = authViewModel.errorMessage, !error.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(error)
                            }
                            .foregroundColor(Theme.error)
                            .typographyLabel()
                            .padding(.top, 4)
                        }
                        
                        HStack {
                            Spacer()
                            NavigationLink(destination: ForgotPasswordView()) {
                                Text("Esqueceu a senha?")
                                    .typographyLabel()
                                    
                                    .foregroundColor(Theme.primary)
                            }
                        }
                    }
                    .transition(.opacity)
                    
                    Spacer()
                    
                    Button(action: {
                        authViewModel.login(emailOrUsername: username, password: password)
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
                                .typographySectionTitle()
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


