import SwiftUI
import Supabase

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var message = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Recuperar Senha")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            Text("Digite seu e-mail cadastrado. Enviaremos um link para você redefinir sua senha.")
                .multilineTextAlignment(.center)
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal)
            
            CustomTextField(title: "E-mail", placeholder: "seu@email.com", text: $email, keyboardType: .emailAddress)
                .padding(.horizontal)
                .autocapitalization(.none)
            
            if !message.isEmpty {
                Text(message)
                    .foregroundColor(message.contains("Sucesso") || message.contains("enviado") ? .green : .red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: resetPassword) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.primary)
                        .cornerRadius(12)
                } else {
                    Text("Enviar Link de Recuperação")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.primary)
                        .cornerRadius(12)
                }
            }
            .disabled(email.isEmpty || !email.contains("@") || isLoading)
            .padding(.horizontal)
            
            Spacer()
        }
        .customBackButton()
    }
    
    private func resetPassword() {
        isLoading = true
        Task {
            do {
                try await supabase.auth.resetPasswordForEmail(email)
                await MainActor.run {
                    message = "Link de recuperação enviado! Verifique sua caixa de entrada."
                    isLoading = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    message = "Erro: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}
