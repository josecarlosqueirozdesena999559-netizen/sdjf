import SwiftUI

struct SearchResultsView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    
    var initialQuery: String = ""
    var category: Category? = nil
    
    @State private var isGrid = true
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack {
            HStack {
                Text("\(viewModel.results.count) resultados")
                    .foregroundColor(Theme.textSecondary)
                    .font(.subheadline)
                Spacer()
                Button(action: { isGrid.toggle() }) {
                    Image(systemName: isGrid ? "list.bullet" : "square.grid.2x2")
                        .foregroundColor(Theme.textPrimary)
                }
            }
            .padding(.horizontal)
            
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if viewModel.results.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(Theme.textSecondary)
                    Text("Nenhum produto encontrado.")
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
            } else {
                ScrollView {
                    if isGrid {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.results) { product in
                                NavigationLink(destination: ProductDetailView(product: product)) {
                                    ProductCard(product: product) {
                                        favoritesViewModel.toggleFavorite(product: product)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.results) { product in
                                NavigationLink(destination: ProductDetailView(product: product)) {
                                    HStack {
                                        Rectangle()
                                            .fill(Theme.lightGreen)
                                            .frame(width: 80, height: 80)
                                            .cornerRadius(8)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(product.title)
                                                .font(.headline)
                                            Text(Formatters.formatCurrency(product.price))
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(Theme.primary)
                                            Text("\(product.condition.rawValue) • \(product.location)")
                                                .font(.caption)
                                                .foregroundColor(Theme.textSecondary)
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 3)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(category?.name ?? "Resultados")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.query, prompt: "Buscar produtos...")
        .onChange(of: viewModel.query) { _ in
            viewModel.search()
        }
        .onAppear {
            viewModel.query = initialQuery
            viewModel.selectedCategory = category
            viewModel.search()
        }
    }
}
