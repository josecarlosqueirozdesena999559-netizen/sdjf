import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showLegalSheet = false

    var body: some View {
        ZStack {
            GeometryReader { geo in
                Image("WelcomeHeroBg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()

            // Floating animated hearts layer
            FloatingHeartsOverlay()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Bottom contrast scrim
            LinearGradient(
                colors: [
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.28),
                    Color(red: 0.08, green: 0.01, blue: 0.04).opacity(0.86),
                    Color(red: 0.05, green: 0.00, blue: 0.02).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 18) {
                    if let logoName = BrandIdentitySlot.logoImageName {
                        Image(logoName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 98, height: 98)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .strokeBorder(.white.opacity(0.28), lineWidth: 1.5)
                            )
                            .shadow(color: AppTheme.Colors.primaryRed.opacity(0.55), radius: 24, x: 0, y: 10)
                    }

                    VStack(spacing: 6) {
                        Text("Conecte-se.")
                            .font(AppTheme.Typography.jakartaExtraBold(34))
                            .tracking(0.3)
                            .foregroundStyle(.white)

                        (
                            Text("Faça ")
                                .foregroundStyle(.white)
                            + Text("Match.")
                                .foregroundStyle(AppTheme.Colors.primaryRed)
                        )
                        .font(AppTheme.Typography.jakartaExtraBold(34))
                        .tracking(0.3)

                        Text("Descubra alguém especial.")
                            .font(AppTheme.Typography.jakartaRegular(16))
                            .tracking(0.2)
                            .foregroundStyle(.white.opacity(0.88))
                            .padding(.top, 4)
                    }
                    .multilineTextAlignment(.center)
                }
                .padding(.bottom, 28)

                VStack(spacing: 14) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            appState.route = .onboarding
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Criar Conta")
                                .font(AppTheme.Typography.jakartaBold(17))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [
                                    AppTheme.Colors.primaryRed,
                                    AppTheme.Colors.secondaryRed
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                        .shadow(color: AppTheme.Colors.primaryRed.opacity(0.42), radius: 14, x: 0, y: 8)
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            appState.route = .login
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Entrar")
                                .font(AppTheme.Typography.jakartaSemiBold(17))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(.black.opacity(0.32), in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(.white.opacity(0.35), lineWidth: 1.2)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 28)

                Button {
                    showLegalSheet = true
                } label: {
                    (
                        Text("Ao continuar, você concorda com nossos ")
                            .foregroundStyle(.white.opacity(0.65))
                        + Text("Termos de Uso")
                            .foregroundStyle(AppTheme.Colors.primaryRed)
                        + Text(" e ")
                            .foregroundStyle(.white.opacity(0.65))
                        + Text("Política de Privacidade")
                            .foregroundStyle(AppTheme.Colors.primaryRed)
                    )
                    .font(.system(size: 11.5))
                    .multilineTextAlignment(.center)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 36)
                .padding(.top, 18)
                .padding(.bottom, 22)
            }
        }
        .sheet(isPresented: $showLegalSheet) {
            CombinedLegalDocumentSheet()
        }
    }
}

private struct FloatingHeartsOverlay: View {
    private struct HeartParticle: Identifiable {
        let id: Int
        let xRatio: CGFloat
        let startYRatio: CGFloat
        let size: CGFloat
        let duration: Double
        let delay: Double
        let opacity: Double
    }

    private let particles: [HeartParticle] = [
        HeartParticle(id: 0, xRatio: 0.14, startYRatio: 0.78, size: 18, duration: 5.5, delay: 0.0, opacity: 0.45),
        HeartParticle(id: 1, xRatio: 0.86, startYRatio: 0.72, size: 22, duration: 6.2, delay: 0.8, opacity: 0.50),
        HeartParticle(id: 2, xRatio: 0.24, startYRatio: 0.54, size: 14, duration: 4.8, delay: 1.4, opacity: 0.38),
        HeartParticle(id: 3, xRatio: 0.78, startYRatio: 0.46, size: 16, duration: 5.2, delay: 0.4, opacity: 0.42),
        HeartParticle(id: 4, xRatio: 0.10, startYRatio: 0.34, size: 13, duration: 6.0, delay: 1.9, opacity: 0.35),
        HeartParticle(id: 5, xRatio: 0.90, startYRatio: 0.24, size: 20, duration: 5.7, delay: 1.1, opacity: 0.46),
    ]

    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Image(systemName: "heart.fill")
                        .font(.system(size: p.size))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    AppTheme.Colors.primaryRed,
                                    AppTheme.Colors.secondaryRed
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: AppTheme.Colors.primaryRed.opacity(0.65), radius: 8)
                        .opacity(animate ? p.opacity : p.opacity * 0.35)
                        .scaleEffect(animate ? 1.15 : 0.85)
                        .position(
                            x: geo.size.width * p.xRatio,
                            y: geo.size.height * (animate ? (p.startYRatio - 0.12) : p.startYRatio)
                        )
                        .animation(
                            .easeInOut(duration: p.duration)
                                .repeatForever(autoreverses: true)
                                .delay(p.delay),
                            value: animate
                        )
                }
            }
        }
        .onAppear {
            animate = true
        }
    }
}


