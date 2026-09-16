import SwiftUI

struct SellerProfileView: View {
    let seller: Seller
    
    var sellerProducts: [Product] {
        MockData.products.filter { $0.sellerId == seller.user.id }
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Circle()
                        .fill(Theme.lightGreen)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(String(seller.user.name.prefix(1)))
                                .foregroundColor(Theme.primary)
                                .font(.largeTitle)
                        )
                    
                    HStack {
                        Text(seller.user.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if seller.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(seller.user.location)
                        .foregroundColor(Theme.textSecondary)
                    
                    HStack(spacing: 32) {
                        VStack {
                            Text("\(seller.salesCount)")
                                .font(.headline)
                            Text("Vendas")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }
                        
                        VStack {
                            HStack(spacing: 2) {
                                Text(String(format: "%.1f", seller.rating))
                                    .font(.headline)
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                            Text("Avaliação")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }
                        
                        VStack {
                            Text(seller.averageResponseTime)
                                .font(.headline)
                            Text("Resposta")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sobre")
                        .font(.headline)
                    
                    Text(seller.bio)
                        .font(.body)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Anúncios do vendedor")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(sellerProducts) { product in
                            NavigationLink(destination: ProductDetailView(product: product)) {
                                FlatProductCard(product: product)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(seller.user.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
