import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Estados de privacidade (Mock)
    @State private var showOnline = true
    @State private var showTyping = true
    @State private var showRecording = true
    
    // Confirmação de exclusão
    @State private var showDeleteConfirm = false
    
    var body: some View {
        Form {
            Section(header: Text("Perfil")) {
                NavigationLink(destination: ProfileEditView()) {
                    Label("Configurações de Perfil", systemImage: "person.crop.circle")
                }
            }
            
            Section(header: Text("Segurança")) {
                NavigationLink(destination: Text("Trocar Senha").padding().navigationTitle("Senha")) {
                    Label("Trocar Senha", systemImage: "lock")
                }
                NavigationLink(destination: Text("Trocar E-mail").padding().navigationTitle("E-mail")) {
                    Label("Trocar E-mail", systemImage: "envelope")
                }
            }
            
            Section(header: Text("Privacidade"), footer: Text("Controle o que os outros usuários podem ver sobre sua atividade.")) {
                Toggle(isOn: $showOnline) {
                    Label("Visto por último e online", systemImage: "eye")
                }
                .tint(Theme.primary)
                
                Toggle(isOn: $showTyping) {
                    Label("Status 'Digitando...'", systemImage: "keyboard")
                }
                .tint(Theme.primary)
                
                Toggle(isOn: $showRecording) {
                    Label("Status 'Gravando áudio...'", systemImage: "mic")
                }
                .tint(Theme.primary)
            }
            
            Section(header: Text("Conta")) {
                Button(action: {
                    showDeleteConfirm = true
                }) {
                    Label("Excluir conta", systemImage: "trash")
                        .foregroundColor(Theme.error)
                }
            }
            
            Section {
                Button(action: {
                    authViewModel.logout()
                }) {
                    Text("Sair da Conta")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Theme.error)
                        .fontWeight(.bold)
                }
            }
        }
        .customBackButton()
        .navigationTitle("Configurações")
        .alert("Excluir conta?", isPresented: $showDeleteConfirm) {
            Button("Cancelar", role: .cancel) { }
            Button("Excluir", role: .destructive) {
                authViewModel.logout()
            }
        } message: {
            Text("Esta ação é irreversível e todos os seus anúncios serão apagados para sempre.")
        }
    }
}
