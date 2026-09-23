import SwiftUI
import Supabase

struct SellerProfileView: View {
    let seller: Seller
    var showsBackButton = true
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isFollowing = false
    @State private var followersCount = 0
    @State private var isFollowLoading = false
    @State private var sellerProducts: [Product] = []
    @State private var productToDelete: Product? = nil

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]


    private var isOwnProfile: Bool { authViewModel.currentUser?.id == seller.user.id }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 12) {
                    avatar
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            Text(seller.user.visibleName ?? seller.user.name)
                                .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))

                        }
                        Text("@\(seller.user.username ?? "")")
                            .font(.custom("Inter-Regular", size: 12, relativeTo: .caption)).foregroundColor(Theme.textSecondary)
                        Label(seller.user.location, systemImage: "mappin.and.ellipse")
                            .font(.custom("Inter-Regular", size: 12, relativeTo: .caption)).foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    Menu {
                        if isOwnProfile {
                            NavigationLink(destination: SettingsView()) {
                                Label("Configurações", systemImage: "gearshape")
                            }
                            NavigationLink(destination: MyAdsView()) {
                                Label("Meus anúncios", systemImage: "square.grid.2x2")
                            }
                            NavigationLink(destination: SoldItemsView()) {
                                Label("Itens vendidos", systemImage: "checkmark.circle")
                            }
                        } else {
                            Button("Denunciar", role: .destructive) { }
                            Button("Bloquear", role: .destructive) { }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 36, height: 36)
                    }
                }

                if !isOwnProfile {
                    HStack(spacing: 10) {
                        Button(action: { Task { await toggleFollow() } }) {
                            HStack(spacing: 6) {
                                if isFollowLoading { ProgressView().tint(.white) }
                                Image(systemName: isFollowing ? "checkmark" : "plus")
                                Text(isFollowing ? "Deixar de seguir" : "Seguir")
                            }
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity).padding(.vertical, 11)
                            .foregroundColor(isFollowing ? Theme.primary : .white)
                            .background(isFollowing ? Theme.lightGreen : Theme.primary)
                            .clipShape(Capsule())
                        }.disabled(isFollowLoading)
                        if let product = sellerProducts.first, let user = authViewModel.currentUser {
                            NavigationLink(destination: ChatView(conversation: Conversation(id: UUID(), productId: product.id, participantId: seller.user.id, lastMessage: Message(id: UUID(), senderId: user.id, receiverId: seller.user.id, text: "", timestamp: Date(), isRead: true), unreadCount: 0), currentUser: user)) {
                            Label("Mensagem", systemImage: "paperplane.fill")
                                .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 11)
                                .foregroundColor(Theme.primary).background(Theme.lightGreen).clipShape(Capsule())
                        }
                    }
                }
                }

                HStack {
                    metric("\(seller.salesCount)", "vendas")
                    Divider().frame(height: 34)
                    metric("\(followersCount)", "seguidores")
                    Divider().frame(height: 34)
                    metric(String(format: "%.1f", seller.rating), "avaliação", icon: "star.fill")
                    Divider().frame(height: 34)
                    metric(seller.averageResponseTime.replacingOccurrences(of: "Responde em ", with: ""), "tempo médio")
                }
                .frame(maxWidth: .infinity).padding(.vertical, 6)

                if !isOwnProfile {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sobre o vendedor").font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                        Text(seller.bio).font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline)).foregroundColor(Theme.textSecondary).lineSpacing(3)
                    }
                    .padding(14).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 1))
                }

                HStack {
                    Text(isOwnProfile ? "Meus anúncios" : "Anúncios do vendedor").font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                    Spacer()
                    if isOwnProfile {
                        NavigationLink(destination: MyAdsView()) {
                            Text("Ver todos").font(.caption.weight(.semibold)).foregroundColor(Theme.primary)
                        }
                    }
                }
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(sellerProducts) { product in
                        ZStack(alignment: .topTrailing) {
                            NavigationLink(destination: ProductDetailView(product: product)) {
                                VStack(alignment: .leading, spacing: 5) {
                                    ProductThumbnail(product: product)
                                    Text(product.title).font(.custom("Inter-Regular", size: 12, relativeTo: .caption)).lineLimit(1).foregroundColor(Theme.textPrimary)
                                    Text(Formatters.formatCurrency(product.price)).font(.caption.weight(.bold)).foregroundColor(Theme.primary)
                                }
                            }
                            if isOwnProfile {
                                Menu {
                                    NavigationLink(destination: EditProductView(product: product)) {
                                        Label("Editar", systemImage: "pencil")
                                    }
                                    Button { Task { await markAsSold(product) } } label: {
                                        Label("Marcar como vendido", systemImage: "checkmark.circle")
                                    }
                                    Button(role: .destructive) { productToDelete = product } label: {
                                        Label("Excluir", systemImage: "trash")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(Theme.textPrimary)
                                        .padding(7)
                                        .background(.white.opacity(0.9))
                                        .clipShape(Circle())
                                }
                                .padding(5)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.inline)
        .modifier(ProfileBackButton(show: showsBackButton))
        .task { await loadFollowState(); await loadProducts(); await subscribeToFollowUpdates() }
        .alert("Excluir anúncio?", isPresented: Binding(get: { productToDelete != nil }, set: { if !$0 { productToDelete = nil } })) {
            Button("Cancelar", role: .cancel) { productToDelete = nil }
            Button("Excluir", role: .destructive) {
                if let productToDelete { Task { await deleteProduct(productToDelete) } }
            }
        } message: {
            Text("Esta ação não pode ser desfeita.")
        }
    }

    private var avatar: some View {
        Group {
            if let value = seller.user.avatarURL, let url = URL(string: value) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image { image.resizable().scaledToFill() }
                    else { avatarFallback }
                }
            } else { avatarFallback }
        }
        .frame(width: 62, height: 62).clipShape(Circle())
    }

    private var avatarFallback: some View {
        Circle().fill(Theme.lightGreen).overlay(Text(String(seller.user.name.prefix(1))).font(.title2.weight(.bold)).foregroundColor(Theme.primary))
    }

    private func metric(_ value: String, _ label: String, icon: String? = nil) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 2) { Text(value).font(.caption.weight(.bold)); if let icon { Image(systemName: icon).font(.custom("Inter-Regular", size: 11, relativeTo: .caption2)).foregroundColor(.yellow) } }
            Text(label).font(.custom("Inter-Regular", size: 11, relativeTo: .caption2)).foregroundColor(Theme.textSecondary).lineLimit(1)
        }.frame(maxWidth: .infinity)
    }

    private func loadProducts() async {
        struct Row: Codable { let id: UUID; let title: String; let description: String?; let price: Double; let condition: String; let category_id: UUID?; let seller_id: UUID; let location: String?; let accepts_negotiation: Bool?; let status: String?; let images: [String]?; let created_at: Date?; let views: Int? }
        do {
            let rows: [Row] = try await supabase.database.from("products").select().eq("seller_id", value: seller.user.id).or("status.eq.active,status.is.null").order("created_at", ascending: false).execute().value
            sellerProducts = rows.map { Product(id: $0.id, title: $0.title, description: $0.description ?? "", price: $0.price, condition: ProductCondition(rawValue: $0.condition) ?? .used, categoryId: $0.category_id ?? UUID(), sellerId: $0.seller_id, location: $0.location ?? "", images: $0.images ?? [], createdAt: $0.created_at ?? Date(), views: $0.views ?? 0, isActive: $0.status == "active", deliveryMethod: "", acceptsNegotiation: $0.accepts_negotiation ?? false) }
        } catch { print("Failed to load seller products: \(error)") }
    }
    private func markAsSold(_ product: Product) async {
        do {
            try await supabase.database.from("products").update(["status": "sold"]).eq("id", value: product.id).execute()
            await loadProducts()
        } catch {
            print("Não foi possível marcar como vendido: \(error)")
        }
    }

    private func deleteProduct(_ product: Product) async {
        do {
            try await supabase.database.from("products").delete().eq("id", value: product.id).execute()
            productToDelete = nil
            await loadProducts()
        } catch {
            print("Não foi possível excluir: \(error)")
        }
    }
    private func subscribeToFollowUpdates() async {
        let channel = await supabase.realtimeV2.channel("follows_\(seller.user.id.uuidString)")
        let insertions = await channel.postgresChange(InsertAction.self, schema: "public", table: "follows", filter: "following_id=eq.\(seller.user.id.uuidString)")
        let deletions = await channel.postgresChange(DeleteAction.self, schema: "public", table: "follows", filter: "following_id=eq.\(seller.user.id.uuidString)")
        await channel.subscribe()
        Task { for await _ in insertions { await loadFollowState() } }
        for await _ in deletions { await loadFollowState() }
    }
    private func loadFollowState() async {
        struct Follow: Codable { let follower_id: UUID }
        do {
            let all: [Follow] = try await supabase.database.from("follows").select("follower_id").eq("following_id", value: seller.user.id).execute().value
            followersCount = all.count
            isFollowing = all.contains { $0.follower_id == authViewModel.currentUser?.id }
        } catch { print("Failed to load follows: \(error)") }
    }

    private func toggleFollow() async {
        guard let currentUser = authViewModel.currentUser else { return }
        isFollowLoading = true
        do {
            if isFollowing {
                try await supabase.database.from("follows").delete().eq("follower_id", value: currentUser.id).eq("following_id", value: seller.user.id).execute()
                isFollowing = false; followersCount = max(0, followersCount - 1)
            } else {
                struct Insert: Codable { let follower_id: UUID; let following_id: UUID }
                try await supabase.database.from("follows").insert(Insert(follower_id: currentUser.id, following_id: seller.user.id)).execute()
                isFollowing = true; followersCount += 1
            }
        } catch { print("Failed to update follow: \(error)") }
        isFollowLoading = false
    }
}

private struct ProductThumbnail: View {
    let product: Product
    var body: some View {
        Group {
            if let address = product.images.first, let url = URL(string: address) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image { image.resizable().scaledToFill() }
                    else { Theme.inputBackground.overlay(Image(systemName: "photo").foregroundColor(Theme.textSecondary)) }
                }
            } else { Theme.inputBackground.overlay(Image(systemName: "photo").foregroundColor(Theme.textSecondary)) }
        }
        .frame(height: 105).clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
private struct ProfileBackButton: ViewModifier {
    let show: Bool
    func body(content: Content) -> some View {
        if show { content.customBackButton() } else { content }
    }
}