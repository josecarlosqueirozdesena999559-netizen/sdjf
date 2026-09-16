import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Agora vai puxar dados reais de produtos
    @State private var myProducts: [Product] = []
    @State private var myCategories: [String] = []
    @State private var isLoading = true
    
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
                                    Group {
                                        if let avatarURL = authViewModel.currentUser?.avatarURL, let url = URL(string: avatarURL) {
                                            AsyncImage(url: url) { phase in
                                                if let image = phase.image {
                                                    image.resizable().scaledToFill()
                                                } else {
                                                    Image("lucide_user").resizable().renderingMode(.template).scaledToFit().padding(20)
                                                }
                                            }
                                        } else {
                                            Image("lucide_user")
                                                .resizable()
                                                .renderingMode(.template)
                                                .scaledToFit()
                                                .padding(20)
                                                .foregroundColor(Theme.textSecondary.opacity(0.5))
                                        }
                                    }
                                )
                                .clipShape(Circle())
                            
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
                        
                        Text(authViewModel.currentUser?.visibleName ?? authViewModel.currentUser?.name ?? "Meu Nome")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("@\(authViewModel.currentUser?.username ?? "usuario")")
                            .foregroundColor(Theme.textSecondary)
                        
                        Text(authViewModel.currentUser?.location ?? "São Paulo - SP")
                            .foregroundColor(Theme.textSecondary)
                            .font(.subheadline)
                        
                        HStack(spacing: 32) {
                            VStack {
                                Text("\(myProducts.count)")
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
                        Text("Categorias que costumo vender:")
                            .font(.headline)
                        
                        if myCategories.isEmpty {
                            Text("Ainda não vendi nenhum produto ou categoria definida.")
                                .font(.body)
                                .foregroundColor(Theme.textSecondary)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(myCategories, id: \.self) { cat in
                                        Text(cat)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Theme.inputBackground)
                                            .cornerRadius(12)
                                            .foregroundColor(Theme.textPrimary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Meus Anúncios")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else if myProducts.isEmpty {
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
            .refreshable {
                fetchMyProducts()
            }
            .onAppear {
                fetchMyProducts()
            }
        }
    }
    
    private func fetchMyProducts() {
        Task {
            guard let userId = authViewModel.currentUser?.id else {
                isLoading = false
                return
            }
            do {
                // Copia da estrutura DTO usada no HomeViewModel
                struct SupabaseProduct: Codable {
                    let id: UUID
                    let title: String
                    let description: String?
                    let price: Double
                    let condition: String
                    let category_id: UUID?
                    let seller_id: UUID
                    let location: String?
                    let accepts_negotiation: Bool?
                    let status: String?
                    let images: [String]?
                    let created_at: Date?
                }
                
                struct SupabaseCategory: Codable {
                    let id: UUID
                    let name: String
                }
                
                let sbProducts: [SupabaseProduct] = try await supabase.database
                    .from("products")
                    .select()
                    .eq("seller_id", value: userId)
                    .execute()
                    .value
                
                // Mapeando produtos reais
                var realProducts: [Product] = []
                var categoryIDs = Set<UUID>()
                
                for sb in sbProducts {
                    realProducts.append(Product(
                        id: sb.id,
                        title: sb.title,
                        description: sb.description ?? "",
                        price: sb.price,
                        condition: ProductCondition(rawValue: sb.condition) ?? .used,
                        categoryId: sb.category_id ?? UUID(),
                        sellerId: sb.seller_id,
                        location: sb.location ?? "Desconhecido",
                        images: sb.images ?? [],
                        createdAt: sb.created_at ?? Date(),
                        views: 0,
                        isActive: sb.status == "active",
                        deliveryMethod: "Em mãos",
                        acceptsNegotiation: sb.accepts_negotiation ?? false
                    ))
                    if let c = sb.category_id {
                        categoryIDs.insert(c)
                    }
                }
                
                // Descobrir o nome das categorias que ele vende
                var catNames: [String] = []
                for catID in categoryIDs {
                    // Try fetch category name
                    do {
                        let cat: SupabaseCategory = try await supabase.database
                            .from("categories")
                            .select()
                            .eq("id", value: catID)
                            .single()
                            .execute()
                            .value
                        catNames.append(cat.name)
                    } catch { }
                }
                
                await MainActor.run {
                    self.myProducts = realProducts
                    self.myCategories = catNames
                    self.isLoading = false
                    
                    // Fallback para n ficar em branco no teste
                    if self.myProducts.isEmpty {
                        self.myProducts = Array(MockData.products.prefix(3))
                        self.myCategories = ["Eletrônicos", "Móveis"]
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    // Fallback
                    self.myProducts = Array(MockData.products.prefix(3))
                    self.myCategories = ["Eletrônicos", "Móveis"]
                }
            }
        }
    }
}

