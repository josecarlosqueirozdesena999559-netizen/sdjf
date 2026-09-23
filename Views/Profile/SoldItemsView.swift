import SwiftUI

struct SoldItemsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var items: [Product] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Carregando itens vendidos...")
            } else if items.isEmpty {
                ContentUnavailableView("Nenhum item vendido", systemImage: "checkmark.circle", description: Text("Os anúncios marcados como vendidos aparecerão aqui."))
            } else {
                List(items) { product in
                    HStack(spacing: 12) {
                        SoldItemImage(product: product)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(product.title).typographySectionTitle().lineLimit(1)
                            Text(Formatters.formatCurrency(product.price)).typographyButton().foregroundColor(Theme.primary)
                            Label("Vendido", systemImage: "checkmark.circle.fill").typographyCaption().foregroundColor(.green)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
                .refreshable { await loadSoldItems() }
            }
        }
        .navigationTitle("Itens vendidos")
        .customBackButton()
        .task { await loadSoldItems() }
    }

    private func loadSoldItems() async {
        guard let user = authViewModel.currentUser else { return }
        isLoading = true
        struct Row: Codable { let id: UUID; let title: String; let description: String?; let price: Double; let condition: String; let category_id: UUID?; let seller_id: UUID; let location: String?; let accepts_negotiation: Bool?; let images: [String]?; let created_at: Date?; let views: Int? }
        if let rows: [Row] = try? await supabase.database.from("products").select().eq("seller_id", value: user.id).eq("status", value: "sold").order("created_at", ascending: false).execute().value {
            items = rows.map { Product(id: $0.id, title: $0.title, description: $0.description ?? "", price: $0.price, condition: ProductCondition(rawValue: $0.condition) ?? .used, categoryId: $0.category_id ?? UUID(), sellerId: $0.seller_id, location: $0.location ?? "", images: $0.images ?? [], createdAt: $0.created_at ?? Date(), views: $0.views ?? 0, isActive: false, deliveryMethod: "", acceptsNegotiation: $0.accepts_negotiation ?? false) }
        }
        isLoading = false
    }
}

private struct SoldItemImage: View {
    let product: Product
    var body: some View {
        Group {
            if let value = product.images.first, let url = URL(string: value) { CachedAsyncImage(url: url).scaledToFill() }
            else { Theme.inputBackground.overlay(Image(systemName: "photo")) }
        }
        .frame(width: 68, height: 68).clipShape(RoundedRectangle(cornerRadius: 10))
    }
}