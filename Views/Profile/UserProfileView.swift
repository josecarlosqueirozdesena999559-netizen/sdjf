import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var myProducts: [Product] = MockData.products.prefix(3).map { $0 }
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(Theme.inputBackground)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image("lucide_user")
                                        .resizable()
                                        .renderingMode(.template)
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(Theme.textSecondary.opacity(0.5))
                                )
                            
                            Button(action: {}) {
                                Circle()
                                    .fill(Theme.primary)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Image("lucide_camera")
                                            .resizable()
                                            .renderingMode(.template)
                                            .scaledToFit()
                                            .frame(width: 14, height: 14)
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        
                        Text(authViewModel.currentUser?.visibleName ?? "Meu Nome")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("@\(authViewModel.currentUser?.username ?? "usuario")")
                            .foregroundColor(Theme.textSecondary)
                        
                        Text(authViewModel.currentUser?.location ?? "São Paulo - SP")
                            .foregroundColor(Theme.textSecondary)
                            .font(.subheadline)
                        
                        HStack(spacing: 32) {
                            VStack {
                                Text("12")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Vendas")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                            
                            VStack {
                                HStack(spacing: 4) {
                                    Text("5.0")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Image("lucide_star")
                                        .resizable()
                                        .renderingMode(.template)
                                        .scaledToFit()
                                        .frame(width: 12, height: 12)
                                        .foregroundColor(.yellow)
                                }
                                Text("Avaliação")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                            
                            VStack {
                                Text("1 hora")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Resposta")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                        .padding(.top, 8)
                        
                    }
                    .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sobre")
                            .font(.headline)
                        
                        Text("Vendo itens que não uso mais, tudo bem conservado! (Você pode alterar isso em Configurações)")
                            .font(.body)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Meus Anúncios")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if myProducts.isEmpty {
                            VStack(spacing: 12) {
                                Image("lucide_tag")
                                    .resizable()
                                    .renderingMode(.template)
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(Theme.textSecondary)
                                Text("Você ainda não publicou nada.")
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(myProducts) { product in
                                    VStack(spacing: 8) {
                                        ZStack(alignment: .topTrailing) {
                                            FlatProductCard(product: product)
                                            
                                            Menu {
                                                Button(action: {}) {
                                                    Label { Text("Editar") } icon: { Image("lucide_keyboard").renderingMode(.template) }
                                                }
                                                Button(action: {}) {
                                                    Label { Text("Marcar como Vendido") } icon: { Image("lucide_check").renderingMode(.template) }
                                                }
                                                Button(role: .destructive, action: {}) {
                                                    Label { Text("Excluir") } icon: { Image("lucide_trash").renderingMode(.template) }
                                                }
                                            } label: {
                                                Image("lucide_more-horizontal")
                                                    .resizable()
                                                    .renderingMode(.template)
                                                    .scaledToFit()
                                                    .frame(width: 20, height: 20)
                                                    .foregroundColor(Theme.textPrimary)
                                                    .padding(8)
                                                    .background(Color.white.opacity(0.8))
                                                    .clipShape(Circle())
                                                    .shadow(radius: 2)
                                            }
                                            .padding(8)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image("lucide_settings")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Theme.textPrimary)
                    }
                }
            }
            .background(Theme.background)
        }
    }
}
