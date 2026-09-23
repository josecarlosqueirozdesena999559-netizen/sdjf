import SwiftUI
import Supabase

struct ChangeEmailView: View {
    @State private var newEmail = ""
    @State private var isLoading = false
    @State private var message = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Novo E-mail"), footer: Text(message).foregroundColor(message.contains("sucesso") || message.contains("confirmação") ? .green : .red)) {
                TextField("Endereço de e-mail", text: $newEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            
            Button(action: updateEmail) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Atualizar E-mail")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(newEmail.isEmpty || !newEmail.contains("@") || isLoading)
        }
        .navigationTitle("Trocar E-mail")
        .customBackButton()
    }
    
    private func updateEmail() {
        isLoading = true
        Task {
            do {
                let attrs = UserAttributes(email: newEmail)
                try await supabase.auth.update(user: attrs)
                await MainActor.run {
                    message = "E-mail atualizado com sucesso! (Verifique sua caixa de entrada para confirmar)"
                    isLoading = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
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
