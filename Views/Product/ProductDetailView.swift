import SwiftUI

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
    @State private var currentImageIndex: Int = 0
    @State private var isFullScreenMedia: Bool = false
    @State private var realConversation: Conversation? = nil
    @State private var isLoadingConversation: Bool = false
    
    // Timer for auto-sliding images
    let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    
    var seller: Seller? {
        MockData.sellers.first { $0.user.id == product.sellerId }
    }
    
    var isOwner: Bool {
        authViewModel.currentUser?.id == product.sellerId
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
                                    CachedAsyncImage(url: url)
                                        .aspectRatio(contentMode: .fill)
                                        .clipped()

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
                                .onTapGesture { isFullScreenMedia = true }
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
                                                // Salvar lance no Supabase
                                                Task {
                                                    struct InsertOffer: Codable {
                                                        let product_id: UUID
                                                        let bidder_id: UUID
                                                        let amount: Double
                                                    }
                                                    let offer = InsertOffer(product_id: product.id, bidder_id: bidderId, amount: amount)
                                                    try? await supabase.database.from("offers").insert(offer).execute()
                                                }
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
            // Bug 3 fix: não usar views/3 como likes. Inicializar com 0.
            localLikes = favoritesViewModel.isFavorite(product) ? 1 : 0
            
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

            // Buscar lances do banco de dados
            Task {
                await fetchOffers()
            }
        }
        .overlay(
            VStack {
                Spacer()
                if !isOwner {
                    HStack(spacing: 12) {
                        // Bug 4 fix: busca/cria a conversa real no banco antes de abrir o chat
                        Button(action: {
                            guard let currentUser = authViewModel.currentUser else { return }
                            isLoadingConversation = true
                            Task {
                                let conv = await findOrCreateConversation(
                                    buyerId: currentUser.id,
                                    sellerId: product.sellerId,
                                    productId: product.id
                                )
                                await MainActor.run {
                                    realConversation = conv
                                    isLoadingConversation = false
                                }
                            }
                        }) {
                            HStack {
                                if isLoadingConversation {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Chat")
                                }
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoadingConversation)
                        .background(
                            NavigationLink(
                                destination: Group {
                                    if let conv = realConversation, let user = authViewModel.currentUser {
                                        ChatView(conversation: conv, currentUser: user)
                                    }
                                },
                                isActive: Binding(
                                    get: { realConversation != nil },
                                    set: { if !$0 { realConversation = nil } }
                                )
                            ) { EmptyView() }
                        )

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

    // Busca lances do Supabase
    private func fetchOffers() async {
        struct OfferRow: Codable {
            let id: UUID
            let product_id: UUID
            let bidder_id: UUID
            let amount: Double
            let created_at: Date
            let profiles: ProfileName?
            struct ProfileName: Codable {
                let name: String?
            }
        }
        do {
            let rows: [OfferRow] = try await supabase.database
                .from("offers")
                .select("*, profiles:bidder_id(name)")
                .eq("product_id", value: product.id)
                .order("created_at", ascending: false)
                .execute()
                .value
            let mapped = rows.map { row in
                ProductOffer(
                    bidderName: row.profiles?.name ?? "Comprador",
                    bidderId: row.bidder_id,
                    amount: row.amount,
                    time: row.created_at
                )
            }
            await MainActor.run {
                self.offers = mapped
            }
        } catch {
            print("Erro ao buscar lances: \(error)")
        }
    }

    // Bug 4 fix: busca conversa existente ou cria uma nova com ID real no banco
    private func findOrCreateConversation(buyerId: UUID, sellerId: UUID, productId: UUID) async -> Conversation {
        struct ConvRow: Codable {
            let id: UUID
            let buyer_id: UUID
            let seller_id: UUID
            let product_id: UUID
            let created_at: Date
        }

        // 1. Buscar se já existe
        if let existing: ConvRow = try? await supabase.database
            .from("conversations")
            .select()
            .eq("buyer_id", value: buyerId)
            .eq("seller_id", value: sellerId)
            .eq("product_id", value: productId)
            .single()
            .execute()
            .value {
            return Conversation(
                id: existing.id,
                productId: existing.product_id,
                participantId: sellerId,
                lastMessage: Message(id: UUID(), senderId: buyerId, receiverId: sellerId, text: "", timestamp: existing.created_at, isRead: true),
                unreadCount: 0
            )
        }

        // 2. Criar nova conversa com ID real
        struct NewConv: Codable {
            let buyer_id: UUID
            let seller_id: UUID
            let product_id: UUID
        }
        let newConv = NewConv(buyer_id: buyerId, seller_id: sellerId, product_id: productId)
        if let created: ConvRow = try? await supabase.database
            .from("conversations")
            .insert(newConv)
            .select()
            .single()
            .execute()
            .value {
            return Conversation(
                id: created.id,
                productId: created.product_id,
                participantId: sellerId,
                lastMessage: Message(id: UUID(), senderId: buyerId, receiverId: sellerId, text: "", timestamp: Date(), isRead: true),
                unreadCount: 0
            )
        }

        // Fallback (não deve acontecer)
        return Conversation(id: UUID(), productId: productId, participantId: sellerId,
                            lastMessage: Message(id: UUID(), senderId: buyerId, receiverId: sellerId, text: "", timestamp: Date(), isRead: true),
                            unreadCount: 0)
    }
}

