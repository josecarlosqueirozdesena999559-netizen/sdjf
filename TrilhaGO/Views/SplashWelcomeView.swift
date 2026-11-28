import SwiftUI

struct SplashWelcomeView: View {
    @ObservedObject var store: TrilhaGameStore
    @State private var pulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#E6FBF2"),
                    TrilhaColors.surfaceGray,
                    TrilhaColors.pureWhite
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(TrilhaColors.emerald.opacity(0.14))
                        .frame(width: 154, height: 154)
                        .scaleEffect(pulse ? 1.08 : 0.96)
                        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulse)

                    Image("app_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 112, height: 112)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: TrilhaColors.emerald.opacity(0.25), radius: 16, y: 8)
                }

                VStack(spacing: 10) {
                    Text("TrilhaGO")
                        .font(TrilhaFont.title(34))
                        .foregroundStyle(TrilhaColors.darkText)

                    Text("Boas-vindas!")
                        .font(TrilhaFont.title(22))
                        .foregroundStyle(TrilhaColors.emeraldDark)

                    Text("Explore o mapa 3D, conquiste territórios hexagonais e desbloqueie baús reais em lojas próximas.")
                        .font(TrilhaFont.body(15))
                        .foregroundStyle(TrilhaColors.mutedText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                VStack(spacing: 14) {
                    EmeraldPillButton(title: "CONTINUAR") {
                        store.requestLocationPermission()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            store.stage = .avatarSetup
                        }
                    }
                    .padding(.horizontal, 28)

                    Text("Caminhe, pedale e ganhe chaves a cada 500 m")
                        .font(TrilhaFont.body(12))
                        .foregroundStyle(TrilhaColors.mutedText)
                }
                .padding(.bottom, 34)
            }
        }
        .onAppear { pulse = true }
    }
}
