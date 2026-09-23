import SwiftUI

// MARK: - Cached Image Loader
// Soluciona: imagens cinza piscando (Bug 1)
// Usa URLCache para não redownlodar imagens já vistas
import SwiftUI

class ImageCache {
    static let shared = NSCache<NSString, UIImage>()
}

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
        .onAppear { loadImage(for: url) }
        .onChange(of: url) { newURL in loadImage(for: newURL) }
    }

    private func loadImage(for targetURL: URL) {
        let key = targetURL.absoluteString as NSString
        if let cached = ImageCache.shared.object(forKey: key) {
            self.image = cached
            self.isLoading = false
            return
        }
        
        self.isLoading = true
        
        URLSession.shared.dataTask(with: targetURL) { data, response, error in
            if let data = data, let img = UIImage(data: data) {
                ImageCache.shared.setObject(img, forKey: key)
                DispatchQueue.main.async {
                    if self.url == targetURL {
                        self.image = img
                        self.isLoading = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    if self.url == targetURL {
                        self.isLoading = false
                    }
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
                    .typographySubtitle()
                    .foregroundColor(Theme.primary)
            }

            Text(category.name)
                .typographyCaption()
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
                            .typographyLabel()
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(2)

                        Text("\(product.condition.rawValue) · \(product.location)")
                            .typographyCaption()
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)

                        HStack {
                            Text(Formatters.formatCurrency(product.price))
                                .typographySectionTitle()
                                
                                .foregroundColor(Theme.primary)

                            Spacer()

                            HStack(spacing: 2) {
                                Image(systemName: "eye")
                                    .typographyCaption()
                                    .foregroundColor(Theme.textSecondary)
                                Text("\(product.views)")
                                    .typographyCaption()
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
