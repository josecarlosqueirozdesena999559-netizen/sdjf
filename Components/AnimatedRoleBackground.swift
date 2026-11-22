import SwiftUI

/// Fundo animado com fotos reais de rolê (transição suave + efeito Ken Burns)
/// e véu claro elegante para manter o visual clean e flat nas telas de Login e Cadastro.
struct AnimatedRoleBackground: View {
    private let images = ["RoleBg1", "RoleBg2", "RoleBg3"]

    @State private var currentIndex = 0
    @State private var zoomed = false

    private let timer = Timer.publish(every: 4.8, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(images.enumerated()), id: \.offset) { idx, name in
                    if idx == currentIndex {
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .scaleEffect(zoomed ? 1.10 : 1.0)
                            .clipped()
                            .transition(.opacity)
                    }
                }

                // Véu claro sofisticado para leitura nítida e estética leve
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.62),
                        Color(hex: "#F8FAFC").opacity(0.84),
                        Color(hex: "#F8FAFC").opacity(0.97)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 4.8)) {
                zoomed = true
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 1.0)) {
                currentIndex = (currentIndex + 1) % images.count
                zoomed = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                withAnimation(.easeInOut(duration: 4.8)) {
                    zoomed = true
                }
            }
        }
    }
}
