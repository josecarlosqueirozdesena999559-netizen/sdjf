import SwiftUI
import Realtime

struct ProductOffer: Identifiable {
    let id = UUID()
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
    
    // Timer for auto-sliding images
    let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    
    private func loadSeller() async {
        struct ProfileRow: Codable { let id: UUID; let name: String; let visible_name: String?; let username: String?; let email: String?; let location: String?; let avatar_url: String?; let created_at: Date?; let rating: Double?; let avg_response_time: String?; let bio: String? }
        do {
            let profile: ProfileRow = try await supabase.database.from("profiles").select("id,name,visible_name,username,email,location,avatar_url,created_at,rating,avg_response_time,bio").eq("id", value: product.sellerId).single().execute().value
            let user = User(id: profile.id, name: profile.name, cpf: "", birthDate: nil, email: profile.email ?? "", phone: "", username: profile.username ?? "", visibleName: profile.visible_name, avatarURL: profile.avatar_url, location: profile.location ?? "", latitude: nil, longitude: nil, memberSince: profile.created_at ?? Date(), isProfessional: false, rating: profile.rating, responseTime: profile.avg_response_time, bio: profile.bio)
            seller = Seller(id: profile.id, user: user, isVerified: false, rating: profile.rating ?? 0, reviewCount: 0, salesCount: 0, averageResponseTime: profile.avg_response_time ?? "-", bio: profile.bio ?? "")
        } catch { print("Failed to load seller: \(error)") }
    }
var isOwner: Bool {
        authViewModel.currentUser?.id == product.sellerId
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
                                                .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
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
                                                    .font(.title)
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
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    
                    Text(product.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text(Formatters.formatCurrency(product.price))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.primary)

                    Label("\(viewCount) visualizações", systemImage: "eye")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                        Text(product.location)
                    }
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    
                    Divider()
                    
                    // NEW: IMPROVED DESCRIPTION
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(Theme.primary)
                            Text("Descrição do Produto")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        
                        Text(product.description)
                            .font(.body)
                            .foregroundColor(Theme.textSecondary)
                            .lineSpacing(4)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.inputBackground)
                            .cornerRadius(12)
                    }
                    
                    Divider()
                    
                    // NEW: NEGOTIATION / BIDS SECTION
                    if product.acceptsNegotiation {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "hand.thumbsup.fill")
                                    .foregroundColor(Theme.primary)
                                Text("Negociação e Lances")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            
                            if isOwner {
                                Text("Como dono deste anúncio, você pode ver os lances e iniciar uma negociação.")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                                
                                if offers.isEmpty {
                                    Text("Nenhum lance recebido ainda.")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.textSecondary)
                                        .padding()
                                } else {
                                    ForEach(offers) { offer in
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(offer.bidderName)
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                Text(Formatters.formatCurrency(offer.amount))
                                                    .foregroundColor(Theme.primary)
                                                    .fontWeight(.bold)
                                            }
                                            Spacer()
                                            
                                            NavigationLink(destination: ChatView(conversation: Conversation(
                                                id: UUID(),
                                                productId: product.id,
                                                participantId: offer.bidderId,
                                                lastMessage: Message(id: UUID(), senderId: product.sellerId, receiverId: offer.bidderId, text: "Olá! Vi seu lance de \(Formatters.formatCurrency(offer.amount)). Vamos negociar?", timestamp: Date(), isRead: true),
                                                unreadCount: 0
                                            ), currentUser: authViewModel.currentUser!)) {
                                                Text("Negociar")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Theme.primary)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(8)
                                            }
                                        }
                                        .padding()
                                        .background(Theme.inputBackground)
                                        .cornerRadius(8)
                                    }
                                }
                            } else {
                                // If not owner, user can place bids
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("R$")
                                            .foregroundColor(Theme.textSecondary)
                                            .fontWeight(.bold)
                                        TextField("0,00", text: $offerAmount)
                                            .keyboardType(.decimalPad)
                                            .font(.headline)
                                        
                                        Button(action: {
                                            if let amount = Double(offerAmount.replacingOccurrences(of: ",", with: ".")) {
                                                let bidderName = authViewModel.currentUser?.name ?? "Você"
                                                let bidderId = authViewModel.currentUser?.id ?? UUID()
                                                let newOffer = ProductOffer(bidderName: bidderName, bidderId: bidderId, amount: amount, time: Date())
                                                offers.append(newOffer)
                                                offerAmount = ""
                                                
                                                if bidderId != product.sellerId {
                                                    sendNotification(to: product.sellerId, type: "sale", title: "Novo lance recebido!", body: "\(bidderName) fez um lance de \(Formatters.formatCurrency(amount)) no seu produto '\(product.title)'.")
                                                }
                                            }
                                        }) {
                                            Text("Enviar Lance")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(offerAmount.isEmpty ? Theme.textSecondary : Theme.primary)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                        .disabled(offerAmount.isEmpty)
                                    }
                                    .padding()
                                    .background(Theme.inputBackground)
                                    .cornerRadius(8)
                                    
                                    if !offers.filter({ $0.bidderId == authViewModel.currentUser?.id }).isEmpty {
                                        Text("Seus lances:")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .padding(.top, 4)
                                        
                                        ForEach(offers.filter({ $0.bidderId == authViewModel.currentUser?.id })) { offer in
                                            HStack {
                                                Text("Você ofereceu:")
                                                    .font(.caption)
                                                    .foregroundColor(Theme.textSecondary)
                                                Spacer()
                                                Text(Formatters.formatCurrency(offer.amount))
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(Theme.primary)
                                            }
                                            .padding()
                                            .background(Theme.inputBackground.opacity(0.5))
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                        
                        Divider()
                    }
                    
                    if let seller = seller {
                        Text("Sobre o vendedor")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        NavigationLink(destination: SellerProfileView(seller: seller)) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Theme.lightGreen)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(String(seller.user.name.prefix(1)))
                                            .foregroundColor(Theme.primary)
                                            .font(.headline)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(seller.user.name)
                                            .font(.headline)
                                            .foregroundColor(Theme.textPrimary)
                                        if seller.isVerified {
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundColor(.blue)
                                                .font(.caption)
                                        }
                                    }
                                    
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text(String(format: "%.1f", seller.rating))
                                        Text("(\(seller.reviewCount))")
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                    .font(.caption)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .customBackButton()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if let user = authViewModel.currentUser, user.id != product.sellerId {
                        sendNotification(to: product.sellerId, type: "system", title: "Produto compartilhado!", body: "Alguém compartilhou o seu produto '\(product.title)'.")
                    }
                    
                    let activityVC = UIActivityViewController(activityItems: ["Olha esse produto que encontrei no Achou: \(product.title) por \(Formatters.formatCurrency(product.price))!", URL(string: "https://achou.com/product/\(product.id.uuidString)")!], applicationActivities: nil)
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
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 2) {
                    Text("\(localLikes)")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .padding(.trailing, 2)
                        
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
            }
        }
        .onAppear {
            Task { await loadViewCount() }
            Task { await subscribeToViewCount() }
            Task { await loadSeller() }
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
        .overlay(
            VStack {
                Spacer()
                if !isOwner {
                    HStack(spacing: 12) {
                        NavigationLink(destination: ChatView(conversation: Conversation(
                            id: UUID(),
                            productId: product.id,
                            participantId: product.sellerId,
                            lastMessage: Message(
                                id: UUID(),
                                senderId: authViewModel.currentUser?.id ?? UUID(),
                                receiverId: product.sellerId,
                                text: "Olá! Gostaria de conversar sobre o produto \(product.title).",
                                timestamp: Date(),
                                isRead: true
                            ),
                            unreadCount: 0
                                            ), currentUser: authViewModel.currentUser!)) {
                            Text("Chat")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.primary)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        if let whatsapp = product.whatsappNumber, !whatsapp.isEmpty {
                            Button(action: {
                                let cleanNumber = whatsapp.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                                let message = "Olá! Vi seu anúncio '\(product.title)' no Achou e gostaria de mais informações."
                                if let url = URL(string: "https://wa.me/\(cleanNumber)?text=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "phone.bubble.left.fill")
                                    Text("WhatsApp")
                                }
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.shadow(color: Color.black.opacity(0.1), radius: 10, y: -5))
                }
            }
            , alignment: .bottom
        )
    }
}

