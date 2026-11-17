import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 16) {
                    if let logoName = BrandIdentitySlot.logoImageName {
                        Image(logoName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 88, height: 88)
                    } else {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .frame(width: 88, height: 88)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                            )
                    }

                    if let name = BrandIdentitySlot.appName {
                        Text(name)
                            .font(.system(size: 30, weight: .bold, design: .default))
                            .foregroundStyle(AppTheme.Colors.darkGray)
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }

                    Text("Conexões reais, simples e do seu jeito.")
                        .font(AppTheme.Typography.body())
                        .foregroundStyle(AppTheme.Colors.textGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                VStack(spacing: 12) {
                    PrimaryButton(title: "Criar conta") {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            appState.route = .onboarding
                        }
                    }

                    SecondaryOutlineButton(title: "Entrar") {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            appState.route = .login
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, 32)
            }
        }
    }
}
