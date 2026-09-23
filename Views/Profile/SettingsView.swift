import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Estados de privacidade (Salvos no dispositivo para funcionarem de forma real)
    @AppStorage("privacy_showOnline") private var showOnline = true
    @AppStorage("privacy_showTyping") private var showTyping = true
    @AppStorage("privacy_showRecording") private var showRecording = true
    
    // Confirmação de exclusão
    @State private var showDeleteConfirm = false
    
    var body: some View {
        Form {
            Section(header: Text("Perfil")) {
                NavigationLink(destination: ProfileEditView()) {
                    Label {
                        Text("Configurações de Perfil")
                    } icon: {
                        Image("lucide_user").renderingMode(.template)
                    }
                }
            }
            
            Section(header: Text("Segurança")) {
                NavigationLink(destination: ChangePasswordView()) {
                    Label {
                        Text("Trocar Senha")
                    } icon: {
                        Image("lucide_lock").renderingMode(.template)
                    }
                }
                NavigationLink(destination: ChangeEmailView()) {
                    Label {
                        Text("Trocar E-mail")
                    } icon: {
                        Image("lucide_mail").renderingMode(.template)
                    }
                }
            }
            
            Section(header: Text("Privacidade"), footer: Text("Controle o que os outros usuários podem ver sobre sua atividade.")) {
                Toggle(isOn: $showOnline) {
                    Label {
                        Text("Visto por último e online")
                    } icon: {
                        Image("lucide_eye").renderingMode(.template)
                    }
                }
                .tint(Theme.primary)
                
                Toggle(isOn: $showTyping) {
                    Label {
                        Text("Status 'Digitando...'")
                    } icon: {
                        Image("lucide_keyboard").renderingMode(.template)
                    }
                }
                .tint(Theme.primary)
                
                Toggle(isOn: $showRecording) {
                    Label {
                        Text("Status 'Gravando áudio...'")
                    } icon: {
                        Image("lucide_mic").renderingMode(.template)
                    }
                }
                .tint(Theme.primary)
            }
            
            Section(header: Text("Conta")) {
                Button(action: {
                    showDeleteConfirm = true
                }) {
                    Label {
                        Text("Excluir conta")
                    } icon: {
                        Image("lucide_trash").renderingMode(.template)
                    }
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
