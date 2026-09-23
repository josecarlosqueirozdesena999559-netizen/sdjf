import SwiftUI

struct MyAdsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var products: [Product] = []
    @State private var isLoading = true
    @State private var productToDelete: Product?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Carregando anúncios...")
            } else if products.isEmpty {
                ContentUnavailableView("Nenhum anúncio", systemImage: "tag", description: Text("Seus anúncios publicados aparecerão aqui."))
            } else {
                List {
                    ForEach(products) { product in
                        HStack(spacing: 12) {
                            ProductImage(product: product)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(product.title).font(.headline).lineLimit(1)
                                Text(Formatters.formatCurrency(product.price)).font(.subheadline.weight(.bold)).foregroundColor(Theme.primary)
                                Text(product.isActive ? "Ativo" : "Vendido").font(.caption.weight(.semibold)).foregroundColor(product.isActive ? Theme.primary : Theme.textSecondary)
                            }
                            Spacer()
                        }
                        .contextMenu {
                            NavigationLink(destination: EditProductView(product: product)) { Label("Editar", systemImage: "pencil") }
                            Button { Task { await markAsSold(product) } } label: { Label("Marcar como vendido", systemImage: "checkmark.circle") }
                            Button(role: .destructive) { productToDelete = product } label: { Label("Excluir", systemImage: "trash") }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) { productToDelete = product } label: { Label("Excluir", systemImage: "trash") }
                            Button { Task { await markAsSold(product) } } label: { Label("Vendido", systemImage: "checkmark.circle") }.tint(.green).disabled(!product.isActive)
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable { await loadProducts() }
            }
        }
        .navigationTitle("Meus anúncios")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SoldItemsView()) { Image(systemName: "checkmark.circle") }
            }
        }
        .customBackButton()
        .task { await loadProducts() }
        .alert("Excluir anúncio?", isPresented: Binding(get: { productToDelete != nil }, set: { if !$0 { productToDelete = nil } })) {
            Button("Cancelar", role: .cancel) { productToDelete = nil }
            Button("Excluir", role: .destructive) { if let product = productToDelete { Task { await delete(product) } } }
        } message: { Text("Esta ação não pode ser desfeita.") }
        .alert("Erro", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) { Button("OK", role: .cancel) {} } message: { Text(errorMessage ?? "") }
    }

    private func loadProducts() async {
        guard let user = authViewModel.currentUser else { return }
        isLoading = true
        struct Row: Codable { let id: UUID; let title: String; let description: String?; let price: Double; let condition: String; let category_id: UUID?; let seller_id: UUID; let location: String?; let accepts_negotiation: Bool?; let status: String?; let images: [String]?; let created_at: Date?; let views: Int? }
        do {
            let rows: [Row] = try await supabase.database.from("products").select().eq("seller_id", value: user.id).order("created_at", ascending: false).execute().value
            products = rows.map { Product(id: $0.id, title: $0.title, description: $0.description ?? "", price: $0.price, condition: ProductCondition(rawValue: $0.condition) ?? .used, categoryId: $0.category_id ?? UUID(), sellerId: $0.seller_id, location: $0.location ?? "", images: $0.images ?? [], createdAt: $0.created_at ?? Date(), views: $0.views ?? 0, isActive: $0.status != "sold", deliveryMethod: "", acceptsNegotiation: $0.accepts_negotiation ?? false) }
        } catch { errorMessage = "Não foi possível carregar seus anúncios." }
        isLoading = false
    }

    private func markAsSold(_ product: Product) async {
        do {
            try await supabase.database.from("products").update(["status": "sold"]).eq("id", value: product.id).execute()
            await loadProducts()
        } catch { errorMessage = "Não foi possível marcar o anúncio como vendido." }
    }

    private func delete(_ product: Product) async {
        do {
            try await supabase.database.from("products").delete().eq("id", value: product.id).execute()
            products.removeAll { $0.id == product.id }
            productToDelete = nil
        } catch { errorMessage = "Não foi possível excluir o anúncio." }
    }
}

private struct ProductImage: View {
    let product: Product
    var body: some View {
        Group {
            if let text = product.images.first, let url = URL(string: text) {
                CachedAsyncImage(url: url).scaledToFill()
            } else { Theme.inputBackground.overlay(Image(systemName: "photo")) }
        }.frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 10))
    }
}