import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var myProducts: [Product] = MockData.products.prefix(3).map { $0 } // Mock own products
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Profile Header
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(Theme.inputBackground)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 100))
                                        .foregroundColor(Theme.textSecondary.opacity(0.5))
                                )
                            
                            Button(action: {}) {
                                Circle()
                                    .fill(Theme.primary)
                                    .frame(width: 30, height: 30)
                                    .overlay(Image(systemName: "camera.fill").font(.caption).foregroundColor(.white))
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
                        
                        // STATS BLOCK - Identical to SellerProfileView
                        HStack(spacing: 32) {
                            VStack {
                                Text("12") // Mock sales
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
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                }
                                Text("Avaliação")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                            
                            VStack {
                                Text("1 hora") // Mock response time
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
                    
                    // User's Ads
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Meus Anúncios")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if myProducts.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tag.slash")
                                    .font(.largeTitle)
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
                                                    Label("Editar", systemImage: "pencil")
                                                }
                                                Button(action: {
                                                    if let index = myProducts.firstIndex(where: { $0.id == product.id }) {
                                                        myProducts.remove(at: index)
                                                    }
                                                }) {
                                                    Label("Marcar como Vendido", systemImage: "checkmark.circle")
                                                }
                                                Button(role: .destructive, action: {
                                                    if let index = myProducts.firstIndex(where: { $0.id == product.id }) {
                                                        myProducts.remove(at: index)
                                                    }
                                                }) {
                                                    Label("Excluir", systemImage: "trash")
                                                }
                                            } label: {
                                                Image(systemName: "ellipsis")
                                                    .font(.system(size: 20, weight: .bold))
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
                        Image(systemName: "gearshape")
                            .foregroundColor(Theme.textPrimary)
                    }
                }
            }
            .background(Theme.background)
        }
    }
}
