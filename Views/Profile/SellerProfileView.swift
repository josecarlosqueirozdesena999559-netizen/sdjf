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
                                .font(.custom("Inter-Bold", size: 34, relativeTo: .largeTitle))
                        )
                    
                    HStack {
                        Text(seller.user.name)
                            .font(.custom("Inter-Bold", size: 22, relativeTo: .title2))
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
                                .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                            Text("Vendas")
                                .font(.custom("Inter-Regular", size: 12, relativeTo: .caption))
                                .foregroundColor(Theme.textSecondary)
                        }
                        
                        VStack {
                            HStack(spacing: 2) {
                                Text(String(format: "%.1f", seller.rating))
                                    .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.custom("Inter-Regular", size: 12, relativeTo: .caption))
                            }
                            Text("Avaliação")
                                .font(.custom("Inter-Regular", size: 12, relativeTo: .caption))
                                .foregroundColor(Theme.textSecondary)
                        }
                        
                        VStack {
                            Text(seller.averageResponseTime)
                                .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                            Text("Resposta")
                                .font(.custom("Inter-Regular", size: 12, relativeTo: .caption))
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
                        .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                    
                    Text(seller.bio)
                        .font(.custom("Inter-Regular", size: 17, relativeTo: .body))
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Anúncios do vendedor")
                        .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(sellerProducts) { product in
                            FlatProductCard(product: product)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(seller.user.name)
        .customBackButton()
        .navigationBarTitleDisplayMode(.inline)
    }
}

