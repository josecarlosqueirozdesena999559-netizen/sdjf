import SwiftUI

struct SettingsView: View {
    @State private var showingDeleteAlert = false
    
    var body: some View {
        List {
            Section(header: Text("Conta")) {
                NavigationLink("Dados pessoais", destination: Text("Dados pessoais"))
                NavigationLink("Endereço", destination: Text("Gerenciar endereços"))
            }
            
            Section(header: Text("Preferências")) {
                NavigationLink("Notificações", destination: Text("Alertas e mensagens"))
                NavigationLink("Privacidade", destination: Text("Dados e permissões"))
                NavigationLink("Segurança", destination: Text("Senha e autenticação"))
            }
            
            Section {
                Button("Excluir conta") {
                    showingDeleteAlert = true
                }
                .foregroundColor(Theme.error)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Configurações")
        .alert("Excluir Conta", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Excluir", role: .destructive) { }
        } message: {
            Text("Tem certeza que deseja excluir sua conta permanentemente? Esta ação não pode ser desfeita.")
        }
    }
}
