import SwiftUI

struct SettingsLabel: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text(title)
                .foregroundColor(Theme.textPrimary)
        }
    }
}

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
                    SettingsLabel(title: "Configurações de Perfil", icon: "person.fill", color: .blue)
                }
            }
            
            Section(header: Text("Segurança")) {
                NavigationLink(destination: Text("Trocar Senha").padding().navigationTitle("Senha")) {
                    SettingsLabel(title: "Trocar Senha", icon: "lock.fill", color: .orange)
                }
                NavigationLink(destination: Text("Trocar E-mail").padding().navigationTitle("E-mail")) {
                    SettingsLabel(title: "Trocar E-mail", icon: "envelope.fill", color: .green)
                }
            }
            
            Section(header: Text("Privacidade"), footer: Text("Controle o que os outros usuários podem ver sobre sua atividade.")) {
                Toggle(isOn: $showOnline) {
                    SettingsLabel(title: "Visto por último e online", icon: "eye.fill", color: .teal)
                }
                .tint(Theme.primary)
                
                Toggle(isOn: $showTyping) {
                    SettingsLabel(title: "Status 'Digitando...'", icon: "keyboard.fill", color: .purple)
                }
                .tint(Theme.primary)
                
                Toggle(isOn: $showRecording) {
                    SettingsLabel(title: "Status 'Gravando áudio...'", icon: "mic.fill", color: .pink)
                }
                .tint(Theme.primary)
            }
            
            Section(header: Text("Conta")) {
                Button(action: {
                    showDeleteConfirm = true
                }) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                                .frame(width: 30, height: 30)
                            Image(systemName: "trash.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.red)
                        }
                        Text("Excluir conta")
                            .foregroundColor(.red)
                    }
                }
            }
            
            Section {
                Button(action: {
                    authViewModel.logout()
                }) {
                    Text("Sair da Conta")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.red)
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
