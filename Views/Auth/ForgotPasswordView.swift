import SwiftUI
import Supabase

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var message = ""
    @State private var isSuccess = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Customizado
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                    .foregroundColor(Theme.primary)
                }
                Spacer()
            }
            .padding()
            
            VStack(alignment: .leading, spacing: 24) {
                if isSuccess {
                    // Success View
                    VStack(spacing: 24) {
                        Spacer().frame(height: 40)
                        
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 100, height: 100)
                            Image(systemName: "envelope.badge.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                        }
                        
                        Text("E-mail Enviado!")
                            .font(.custom("Inter-Bold", size: 34, relativeTo: .largeTitle))
                            
                            .foregroundColor(Theme.textPrimary)
                        
                        Text(message)
                            .font(.custom("Inter-Regular", size: 17, relativeTo: .body))
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    .transition(.opacity)
                } else {
                    // Form View
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recuperar Senha")
                            .font(.custom("Inter-Bold", size: 34, relativeTo: .largeTitle))
                            
                            .foregroundColor(Theme.textPrimary)
                        Text("Digite seu e-mail cadastrado. Enviaremos um link seguro para você redefinir sua senha.")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    CustomTextField(title: "Seu E-mail", placeholder: "exemplo@email.com", text: $email, keyboardType: .emailAddress)
                        .autocapitalization(.none)
                        .padding(.top, 16)
                    
                    if !message.isEmpty && !isSuccess {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(message)
                        }
                        .foregroundColor(Theme.error)
                        .font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline))
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        resetPassword()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.primary)
                                .cornerRadius(12)
                        } else {
                            Text("Enviar Link de Recuperação")
                                .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                                .foregroundColor(email.isEmpty || !email.contains("@") ? .gray : .white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(email.isEmpty || !email.contains("@") ? Color.gray.opacity(0.2) : Theme.primary)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(email.isEmpty || !email.contains("@") || isLoading)
                }
            }
            .padding(.horizontal, 24)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
    }
    
    private func resetPassword() {
        isLoading = true
        message = ""
        Task {
            do {
                try await supabase.auth.resetPasswordForEmail(email)
                await MainActor.run {
                    message = "Enviamos as instruções de recuperação para o e-mail: \(email)."
                    withAnimation {
                        isSuccess = true
                    }
                    isLoading = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    message = "Erro ao enviar: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}
