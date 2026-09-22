import SwiftUI

// MARK: - Cached Image Loader
// Soluciona: imagens cinza piscando (Bug 1)
// Usa URLCache para não redownlodar imagens já vistas
struct CachedAsyncImage: View {
    let url: URL
    @State private var image: UIImage? = nil
    @State private var isLoading = true

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
            } else if isLoading {
                Rectangle()
                    .fill(Color(UIColor.systemGray5))
                    .overlay(ProgressView().tint(.gray))
            } else {
                Rectangle()
                    .fill(Color(UIColor.systemGray5))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray.opacity(0.5))
                            .font(.custom("Inter-Regular", size: 40))
                    )
            }
        }
        .onAppear { loadImage() }
        .onChange(of: url) { _ in loadImage() }
    }

    private func loadImage() {
        let request = URLRequest(url: url)
        if let cached = URLCache.shared.cachedResponse(for: request),
           let img = UIImage(data: cached.data) {
            self.image = img
            self.isLoading = false
            return
        }
        isLoading = true
        URLSession.shared.dataTask(with: request) { data, response, _ in
            if let data, let img = UIImage(data: data),
               let response {
                let cached = CachedURLResponse(response: response, data: data)
                URLCache.shared.storeCachedResponse(cached, for: request)
                DispatchQueue.main.async {
                    self.image = img
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }.resume()
    }
}

// MARK: - Category Card
struct FlatCategoryCard: View {
    var category: Category

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.inputBackground)
                    .frame(width: 60, height: 60)

                Image(systemName: category.iconName)
                    .font(.custom("Inter-Bold", size: 22, relativeTo: .title2))
                    .foregroundColor(Theme.primary)
            }

            Text(category.name)
                .font(.custom("Inter-Regular", size: 12, relativeTo: .caption))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
        }
    }
}

// MARK: - Product Card
struct FlatProductCard: View {
    var product: Product

    @State private var currentImageIndex = 0
    // Timer agora usa 3.5s para dar tempo de carregar a imagem
    let timer = Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationLink(destination: ProductDetailView(product: product)) {
                VStack(alignment: .leading, spacing: 8) {
                    // Área da imagem com CachedAsyncImage (sem piscar)
                    ZStack {
                        if !product.images.isEmpty,
                           let url = URL(string: product.images[currentImageIndex]) {
                            CachedAsyncImage(url: url)
                                .aspectRatio(1, contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            Rectangle()
                                .fill(Theme.inputBackground)
                                .aspectRatio(1, contentMode: .fill)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray.opacity(0.5))
                                        .font(.custom("Inter-Regular", size: 40))
                                )
                                .cornerRadius(12)
                        }
                    }
                    .onReceive(timer) { _ in
                        guard product.images.count > 1 else { return }
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentImageIndex = (currentImageIndex + 1) % product.images.count
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.title)
                            .font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline))
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(2)

                        Text("\(product.condition.rawValue) · \(product.location)")
                            .font(.custom("Inter-Medium", size: 11, relativeTo: .caption2))
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)

                        HStack {
                            Text(Formatters.formatCurrency(product.price))
                                .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                                .fontWeight(.bold)
                                .foregroundColor(Theme.primary)

                            Spacer()

                            HStack(spacing: 2) {
                                Image(systemName: "eye")
                                    .font(.custom("Inter-Regular", size: 10))
                                    .foregroundColor(Theme.textSecondary)
                                Text("\(product.views)")
                                    .font(.custom("Inter-Medium", size: 11, relativeTo: .caption2))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color.white)
    }
}
