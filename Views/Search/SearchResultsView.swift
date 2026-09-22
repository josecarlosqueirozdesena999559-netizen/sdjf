import SwiftUI

struct SearchResultsView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var initialQuery: String = ""
    var category: Category? = nil
    
    @State private var isGrid = true
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var localResults: [Product] {
        let userLoc = authViewModel.currentUser?.location ?? "São Paulo - SP"
        return viewModel.results.filter { $0.location == userLoc }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("\(localResults.count) resultados próximos a você")
                    .foregroundColor(Theme.textSecondary)
                    .font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline))
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
            } else if localResults.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "location.slash")
                        .font(.custom("Inter-Bold", size: 34, relativeTo: .largeTitle))
                        .foregroundColor(Theme.textSecondary)
                    Text("Nenhum produto próximo a você.")
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
            } else {
                ScrollView {
                    if isGrid {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(localResults) { product in
                                FlatProductCard(product: product)
                            }
                        }
                        .padding()
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(localResults) { product in
                                NavigationLink(destination: ProductDetailView(product: product)) {
                                    HStack {
                                        Rectangle()
                                            .fill(Theme.lightGreen)
                                            .frame(width: 80, height: 80)
                                            .cornerRadius(8)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(product.title)
                                                .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                                            Text(Formatters.formatCurrency(product.price))
                                                .font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline))
                                                .fontWeight(.bold)
                                                .foregroundColor(Theme.primary)
                                            Text("\(product.condition.rawValue) • \(product.location)")
                                                .font(.custom("Inter-Regular", size: 12, relativeTo: .caption))
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
        .customBackButton()
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.query, prompt: "Buscar produtos...")
        .onChange(of: viewModel.query) { _, _ in
            viewModel.search()
        }
        .onAppear {
            viewModel.query = initialQuery
            viewModel.selectedCategory = category
            viewModel.search()
        }
    }
}
