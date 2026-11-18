import SwiftUI

struct AnimatedAuthBackground: View {
    private let images = ["AuthBg1", "AuthBg2", "AuthBg3"]

    @State private var currentIndex = 0
    @State private var zoomed = false

    private let timer = Timer.publish(every: 4.5, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(images.enumerated()), id: \.offset) { idx, name in
                    if idx == currentIndex {
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .scaleEffect(zoomed ? 1.08 : 1.0)
                            .clipped()
                            .transition(.opacity)
                    }
                }

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.45),
                        Color(red: 0.14, green: 0.02, blue: 0.06).opacity(0.55),
                        Color(red: 0.09, green: 0.01, blue: 0.04).opacity(0.88)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 4.5)) {
                zoomed = true
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 1.1)) {
                currentIndex = (currentIndex + 1) % images.count
                zoomed = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeInOut(duration: 4.5)) {
                    zoomed = true
                }
            }
        }
    }
}
