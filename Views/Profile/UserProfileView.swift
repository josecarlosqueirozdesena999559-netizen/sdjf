import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Theme.lightGreen)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(String(authViewModel.currentUser?.name.prefix(1) ?? "U"))
                                    .foregroundColor(Theme.primary)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authViewModel.currentUser?.name ?? "Usuário Convidado")
                                .font(.headline)
                            Text(authViewModel.currentUser?.email ?? "email@exemplo.com")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    NavigationLink(destination: MyAdsView()) {
                        Label("Meus anúncios", systemImage: "tag")
                    }
                    NavigationLink(destination: Text("Minhas compras")) {
                        Label("Minhas compras", systemImage: "bag")
                    }
                    NavigationLink(destination: FavoritesView()) {
                        Label("Meus favoritos", systemImage: "heart")
                    }
                    NavigationLink(destination: Text("Minhas vendas")) {
                        Label("Minhas vendas", systemImage: "dollarsign.circle")
                    }
                }
                
                Section {
                    NavigationLink(destination: ProfessionalAccountView()) {
                        Label("Conta Profissional", systemImage: "briefcase")
                            .foregroundColor(Theme.primary)
                    }
                }
                
                Section {
                    NavigationLink(destination: SettingsView()) {
                        Label("Configurações", systemImage: "gear")
                    }
                    NavigationLink(destination: Text("Ajuda")) {
                        Label("Ajuda", systemImage: "questionmark.circle")
                    }
                }
                
                Section {
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        Text("Sair")
                            .foregroundColor(Theme.error)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Perfil")
        }
    }
}
