import SwiftUI
import Supabase

struct ChangePasswordView: View {
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var message = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Nova Senha"), footer: Text(message).foregroundColor(message.contains("sucesso") ? .green : .red)) {
                SecureField("Nova Senha", text: $newPassword)
                SecureField("Confirmar Nova Senha", text: $confirmPassword)
            }
            
            Button(action: updatePassword) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Atualizar Senha")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(newPassword.isEmpty || newPassword != confirmPassword || isLoading)
        }
        .navigationTitle("Trocar Senha")
        .customBackButton()
    }
    
    private func updatePassword() {
        isLoading = true
        Task {
            do {
                let attrs = UserAttributes(password: newPassword)
                try await supabase.auth.update(user: attrs)
                await MainActor.run {
                    message = "Senha atualizada com sucesso!"
                    isLoading = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
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
