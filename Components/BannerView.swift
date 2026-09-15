import SwiftUI

struct BannerView: View {
    @State private var currentIndex = 0
    let timers = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        TabView(selection: $currentIndex) {
            // Banner 1
            bannerContent(
                title: "Ofertas Relâmpago",
                subtitle: "Descontos de até 50% em smartphones.",
                icon: "bolt.fill",
                color1: Theme.primary,
                color2: Theme.darkGreen
            ).tag(0)
            
            // Banner 2
            bannerContent(
                title: "Frete Grátis",
                subtitle: "Para milhares de produtos selecionados.",
                icon: "shippingbox.fill",
                color1: Color(hex: "3B82F6"), // Azul
                color2: Color(hex: "1D4ED8")
            ).tag(1)
            
            // Banner 3
            bannerContent(
                title: "Desapega Aqui!",
                subtitle: "Venda rápido aquilo que não usa mais.",
                icon: "sparkles",
                color1: Color(hex: "F59E0B"), // Laranja/Amarelo
                color2: Color(hex: "B45309")
            ).tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .frame(height: 160)
        .cornerRadius(20)
        .onReceive(timers) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentIndex = (currentIndex + 1) % 3
            }
        }
    }
    
    @ViewBuilder
    func bannerContent(title: String, subtitle: String, icon: String, color1: Color, color2: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(AppFont.bold(22))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(AppFont.regular(14))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [color1, color2]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
