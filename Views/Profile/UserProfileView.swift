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
                        Text(authViewModel.currentUser?.email ?? "meuemail@exemplo.com")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.top)
                    
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
                                        FlatProductCard(product: product)
                                        
                                        // Edit & Sold actions
                                        HStack(spacing: 8) {
                                            Button(action: {
                                                // Edit action mock
                                            }) {
                                                Text("Editar")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 6)
                                                    .background(Theme.inputBackground)
                                                    .foregroundColor(Theme.textPrimary)
                                                    .cornerRadius(6)
                                            }
                                            
                                            Button(action: {
                                                // Mark as sold mock
                                                if let index = myProducts.firstIndex(where: { $0.id == product.id }) {
                                                    myProducts.remove(at: index)
                                                }
                                            }) {
                                                Text("Vendido")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 6)
                                                    .background(Theme.primary)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(6)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Divider()
                    
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        Text("Sair da Conta")
                            .foregroundColor(Theme.error)
                            .fontWeight(.semibold)
                            .padding()
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .background(Theme.background)
        }
    }
}
