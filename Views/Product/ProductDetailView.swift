import SwiftUI
import Realtime

struct ProductOffer: Identifiable {
    let id: UUID
    let bidderName: String
    let bidderId: UUID
    let amount: Double
    let time: Date
}

struct ProductDetailView: View {
    let product: Product
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var offers: [ProductOffer] = []
    @State private var offerAmount: String = ""
    @State private var localLikes: Int = 0
    @State private var viewCount: Int = 0
    @State private var currentImageIndex: Int = 0
    @State private var isFullScreenMedia: Bool = false
    @State private var seller: Seller? = nil
    @State private var offerError: String? = nil
    @AppStorage("hideFloatingButton") private var hideFloatingButton = false
    
    // Timer for auto-sliding images
    let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    
    private func loadSeller() async {
        struct ProfileRow: Codable { let id: UUID; let name: String; let visible_name: String?; let username: String?; let email: String?; let location: String?; let avatar_url: String?; let created_at: Date?; let rating: Double?; let avg_response_time: String?; let bio: String?; let phone: String? }
        do {
            let profile: ProfileRow = try await supabase.database.from("profiles").select("id,name,visible_name,username,email,location,avatar_url,created_at,rating,avg_response_time,bio,phone").eq("id", value: product.sellerId).single().execute().value
            let user = User(id: profile.id, name: profile.name, cpf: "", birthDate: nil, email: profile.email ?? "", phone: profile.phone ?? "", username: profile.username ?? "", visibleName: profile.visible_name, avatarURL: profile.avatar_url, location: profile.location ?? "", latitude: nil, longitude: nil, memberSince: profile.created_at ?? Date(), isProfessional: false, rating: profile.rating, responseTime: profile.avg_response_time, bio: profile.bio)
            seller = Seller(id: profile.id, user: user, isVerified: false, rating: profile.rating ?? 0, reviewCount: 0, salesCount: 0, averageResponseTime: profile.avg_response_time ?? "-", bio: profile.bio ?? "")
        } catch { print("Failed to load seller: \(error)") }
    }
var isOwner: Bool {
        authViewModel.currentUser?.id == product.sellerId
    }
    
    private func loadOffers() async {
        struct Row: Decodable { let id: UUID; let bidder_id: UUID; let amount: Double; let created_at: Date }
        do {
            let rows: [Row] = try await supabase.database.from("product_offers").select()
                .eq("product_id", value: product.id).order("created_at", ascending: false).execute().value
            offers = rows.map { ProductOffer(id: $0.id, bidderName: "Interessado", bidderId: $0.bidder_id, amount: $0.amount, time: $0.created_at) }
        } catch { offerError = "Não foi possível carregar os lances." }
    }

    private func createOffer() async {
        guard let userID = authViewModel.currentUser?.id,
              let amount = Double(offerAmount.replacingOccurrences(of: ",", with: ".")), amount > 0 else { return }
        struct NewOffer: Encodable { let product_id: UUID; let bidder_id: UUID; let amount: Double }
        do {
            try await supabase.database.from("product_offers").insert(NewOffer(product_id: product.id, bidder_id: userID, amount: amount)).execute()
            offerAmount = ""; await loadOffers()
        } catch { offerError = "Não foi possível enviar o lance." }
    }

    private func deleteOffer(_ offer: ProductOffer) async {
        do {
            try await supabase.database.from("product_offers").delete().eq("id", value: offer.id).execute()
            await loadOffers()
        } catch { offerError = "Não foi possível excluir o lance." }
    }
    private func loadViewCount() async {
        struct ProductViews: Codable { let views: Int }
        if let result: ProductViews = try? await supabase.database.from("products").select("views").eq("id", value: product.id).single().execute().value {
            viewCount = result.views
        }
    }

    private func subscribeToViewCount() async {
        let channel = await supabase.realtimeV2.channel("product_views_\(product.id.uuidString)")
        let updates = await channel.postgresChange(UpdateAction.self, schema: "public", table: "products", filter: "id=eq.\(product.id.uuidString)")
        await channel.subscribe()
        for await _ in updates { await loadViewCount() }
    }
    private func isVideo(url: String) -> Bool {
        let lowercased = url.lowercased()
        return lowercased.hasSuffix(".mp4") || lowercased.hasSuffix(".mov") || lowercased.hasSuffix(".m3u8") || lowercased.contains("video")
    }
    
    private func sendNotification(to userId: UUID, type: String, title: String, body: String) {
        Task {
            struct NotifInsert: Codable {
                let id: UUID
                let user_id: UUID
                let type: String
                let title: String
                let body: String
                let is_read: Bool
            }
            let notif = NotifInsert(id: UUID(), user_id: userId, type: type, title: title, body: body, is_read: false)
            do {
                try await supabase.database.from("notifications").insert(notif).execute()
            } catch {
                print("Failed to send notification: \(error)")
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Product Images
                if !product.images.isEmpty {
                    TabView(selection: $currentImageIndex) {
                        ForEach(0..<product.images.count, id: \.self) { index in
                            let imageUrl = product.images[index]
                            if let url = URL(string: imageUrl) {
                                ZStack {
                                    AsyncImage(url: url) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else if phase.error != nil {
                                            Rectangle()
                                                .fill(Theme.inputBackground)
                                                .overlay(Image(systemName: "photo").typographyScreenTitle().foregroundColor(.gray))
                                        } else {
                                            Rectangle()
                                                .fill(Theme.inputBackground)
                                                .overlay(ProgressView())
                                        }
                                    }
                                    
                                    if isVideo(url: imageUrl) {
                                        Circle()
                                            .fill(Color.black.opacity(0.5))
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Image(systemName: "play.fill")
                                                    .foregroundColor(.white)
                                                    .typographySubtitle()
                                            )
                                    }
                                }
                                .tag(index)
                                .onTapGesture {
                                    isFullScreenMedia = true
                                }
                            }
                        }
                    }
                    .frame(height: 300)
                    .tabViewStyle(PageTabViewStyle())
                    .onReceive(timer) { _ in
                        if product.images.count > 1 && !isFullScreenMedia {
                            withAnimation {
                                currentImageIndex = (currentImageIndex + 1) % product.images.count
                            }
                        }
                    }
                    .fullScreenCover(isPresented: $isFullScreenMedia) {
                        FullScreenMediaView(mediaUrls: product.images, currentIndex: currentImageIndex)
                    }
                } else {
                    Rectangle()
                        .fill(Theme.lightGreen)
                        .frame(height: 300)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(Theme.primary.opacity(0.5))
                        )
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(product.condition.rawValue) • \(Formatters.dateFormatter.string(from: product.createdAt))")
                        .typographyCaption()
                        .foregroundColor(Theme.textSecondary)
                    
                    HStack {
                        Text(product.title)
                            .typographyScreenTitle()
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        
                        Button(action: {
                            if let user = authViewModel.currentUser, user.id != product.sellerId {
                                sendNotification(to: product.sellerId, type: "system", title: "Produto compartilhado!", body: "Alguém compartilhou o seu produto '\(product.title)'.")
                            }
                            let activityVC = UIActivityViewController(activityItems: ["Olha esse produto que encontrei: \(product.title) por \(Formatters.formatCurrency(product.price))!", URL(string: "https://achou.com/product/\(product.id.uuidString)")!], applicationActivities: nil)
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first,
                               let rootVC = window.rootViewController {
                                var topController = rootVC
                                while let presented = topController.presentedViewController {
                                    topController = presented
                                }
                                topController.present(activityVC, animated: true)
                            }
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(Theme.textPrimary)
                        }
                        
                        Button(action: {
                            favoritesViewModel.toggleFavorite(product: product)
                            if favoritesViewModel.isFavorite(product) {
                                localLikes += 1
                                if let user = authViewModel.currentUser, user.id != product.sellerId {
                                    sendNotification(to: product.sellerId, type: "system", title: "Nova curtida!", body: "\(user.name) curtiu o seu produto '\(product.title)'.")
                                }
                            } else {
                                localLikes -= 1
                            }
                        }) {
                            Image(systemName: favoritesViewModel.isFavorite(product) ? "heart.fill" : "heart")
                                .foregroundColor(favoritesViewModel.isFavorite(product) ? Theme.primary : Theme.textPrimary)
                        }
                    }
                    
                    Text(Formatters.formatCurrency(product.price))
                        .typographyScreenTitle()
                        
                        .foregroundColor(Theme.primary)

                    Label("\(viewCount) visualizações", systemImage: "eye")
                        .typographyCaption()
                        .foregroundColor(Theme.textSecondary)
                    
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                        Text(product.location)
                    }
                    .typographyLabel()
                    .foregroundColor(Theme.textSecondary)
                    
                    Divider()
                    
                    // NEW: IMPROVED DESCRIPTION
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(Theme.primary)
                            Text("Descrição do Produto")
                                .typographySectionTitle()
                                
                        }
                        
                        Text(product.description)
                            .typographyBody()
                            .foregroundColor(Theme.textSecondary)
                            .lineSpacing(4)
                            .padding(.top, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Divider()
                    
                    if product.acceptsNegotiation {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Negociação e lances", systemImage: "hand.thumbsup.fill")
                                .typographySectionTitle().foregroundColor(Theme.primary)
                            if isOwner {
                                if offers.isEmpty {
                                    Text("Nenhum lance recebido ainda.").foregroundColor(Theme.textSecondary)
                                } else {
                                    ForEach(offers) { offer in
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(Formatters.formatCurrency(offer.amount)).foregroundColor(Theme.primary)
                                                Text("Lance recebido").typographyCaption().foregroundColor(Theme.textSecondary)
                                            }
                                            Spacer()
                                            if let user = authViewModel.currentUser {
                                                NavigationLink(destination: ChatView(conversation: Conversation(id: UUID(), productId: product.id, participantId: offer.bidderId, lastMessage: Message(id: UUID(), senderId: user.id, receiverId: offer.bidderId, text: "", timestamp: Date(), isRead: true), unreadCount: 0), currentUser: user)) {
                                                    Label("Responder", systemImage: "paperplane.fill").typographyCaption()
                                                }
                                            }
                                        }.padding(12).background(Theme.inputBackground).clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            } else {
                                HStack {
                                    TextField("Seu lance", text: $offerAmount).keyboardType(.decimalPad)
                                    Button("Enviar") { Task { await createOffer() } }
                                        .buttonStyle(.borderedProminent).tint(Theme.primary).disabled(offerAmount.isEmpty)
                                }.padding(10).background(Theme.inputBackground).clipShape(RoundedRectangle(cornerRadius: 10))
                                ForEach(offers.filter { $0.bidderId == authViewModel.currentUser?.id }) { offer in
                                    HStack {
                                        Text("Seu lance: \(Formatters.formatCurrency(offer.amount))").typographyButton()
                                        Spacer()
                                        Button("Excluir", role: .destructive) { Task { await deleteOffer(offer) } }.typographyCaption()
                                    }.padding(10).background(Theme.inputBackground.opacity(0.7)).clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        Divider()
                    }

                }
                .padding()
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .customBackButton()
        .navigationBarTitleDisplayMode(.inline)
        
        .toolbar(.hidden, for: .tabBar)
.onAppear {
            hideFloatingButton = true
            Task { await loadViewCount() }
            Task { await subscribeToViewCount() }
            Task { await loadOffers() }
            localLikes = (product.views / 3) + (favoritesViewModel.isFavorite(product) ? 1 : 0)
            
            // Increment view count in Supabase (unique per user)
            Task {
                guard let userId = authViewModel.currentUser?.id else { return }
                do {
                    struct IncrementParams: Codable {
                        let p_product_id: UUID
                        let p_user_id: UUID
                    }
                    let params = IncrementParams(p_product_id: product.id, p_user_id: userId)
                    try await supabase.database.rpc("increment_product_views", params: params).execute()
                    
                    struct ProductViews: Codable { let views: Int }
                    if let updatedProduct: ProductViews = try? await supabase.database.from("products").select("views").eq("id", value: product.id).single().execute().value {
                        let milestones = [5, 30, 55, 105, 500, 1000]
                        if milestones.contains(updatedProduct.views) && userId != product.sellerId {
                            sendNotification(to: product.sellerId, type: "system", title: "Meta de Visualizações!", body: "Parabéns! O seu anúncio '\(product.title)' acabou de bater \(updatedProduct.views) visualizações.")
                        }
                    }
                } catch {
                    print("Failed to increment views: \(error)")
                }
            }
        }
                .onDisappear {
            hideFloatingButton = false
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {            if isOwner {
                HStack(spacing: 12) {
                    NavigationLink(destination: EditProductView(product: product)) {
                        Label("Editar Anúncio", systemImage: "pencil")
                            .typographySectionTitle()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundColor(.white)
                            .background(Theme.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            } else if let currentUser = authViewModel.currentUser {
                HStack(spacing: 12) {
                    NavigationLink(destination: ChatView(conversation: Conversation(id: UUID(), productId: product.id, participantId: product.sellerId, lastMessage: Message(id: UUID(), senderId: currentUser.id, receiverId: product.sellerId, text: "", timestamp: Date(), isRead: true), unreadCount: 0), currentUser: currentUser)) {
                        Label("Conversar", systemImage: "bubble.left.and.bubble.right.fill")
                            .typographySectionTitle()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundColor(.white)
                            .background(Theme.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    if let phone = seller?.user.phone, !phone.isEmpty {
                        Button(action: {
                            let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                            if let url = URL(string: "https://wa.me/55$cleanPhone") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Label("WhatsApp", systemImage: "phone.circle.fill")
                                .typographySectionTitle()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .foregroundColor(.white)
                                .background(Color(red: 37/255, green: 211/255, blue: 102/255))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
        }
        .alert("Lances", isPresented: Binding(get: { offerError != nil }, set: { if !$0 { offerError = nil } })) {
            Button("OK", role: .cancel) { }
        } message: { Text(offerError ?? "") }
    }
}