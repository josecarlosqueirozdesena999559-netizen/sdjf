import SwiftUI

struct PermissionsView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Permissões")
                .font(AppTheme.Typography.largeTitle())
                .foregroundStyle(AppTheme.Colors.darkGray)
                .padding(.top, 12)

            VStack(spacing: 14) {
                permissionCard(
                    icon: "location.north.fill",
                    title: "Localização",
                    description: "Para mostrar pessoas próximas e calcular a distância.",
                    isAuthorized: viewModel.permissions.locationAuthorized
                ) {
                    Task {
                        await viewModel.requestLocationPermission()
                    }
                }

                permissionCard(
                    icon: "bell.fill",
                    title: "Notificações",
                    description: "Para avisar sobre novos matches e mensagens.",
                    isAuthorized: viewModel.permissions.notificationsAuthorized
                ) {
                    Task {
                        await viewModel.requestNotificationsPermission()
                    }
                }
            }

            if let error = viewModel.submissionError {
                Text(error)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.primaryRed)
            }

            Spacer()

            PrimaryButton(
                title: "Concluir",
                isEnabled: true,
                isLoading: viewModel.isSubmitting
            ) {
                Task {
                    await viewModel.finishOnboarding(appState: appState)
                }
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .task {
            viewModel.permissions.locationAuthorized = appState.permissionService.isLocationAuthorized
            viewModel.permissions.notificationsAuthorized = appState.permissionService.isNotificationAuthorized
        }
    }

    private func permissionCard(
        icon: String,
        title: String,
        description: String,
        isAuthorized: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.secondaryRed, AppTheme.Colors.primaryRed],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: AppTheme.Colors.primaryRed.opacity(0.22), radius: 8, x: 0, y: 4)

                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(AppTheme.Typography.headline())
                        .foregroundStyle(AppTheme.Colors.darkGray)
                    Text(description)
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.textGray)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isAuthorized {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                        Text("Ativo")
                            .font(AppTheme.Typography.caption())
                    }
                    .foregroundStyle(AppTheme.Colors.primaryRed)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(AppTheme.Colors.primaryRed.opacity(0.1), in: Capsule())
                } else {
                    Text("Permitir")
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppTheme.Colors.primaryRed, in: Capsule())
                }
            }
            .padding(18)
            .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .strokeBorder(isAuthorized ? AppTheme.Colors.primaryRed.opacity(0.3) : AppTheme.Colors.borderSubtle, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isAuthorized)
    }
}

struct OnboardingCompletionView: View {
    @State private var scale: CGFloat = 0.55
    @State private var opacity: Double = 0.0
    @State private var ringScale: CGFloat = 0.7
    @State private var ringOpacity: Double = 0.65

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(AppTheme.Colors.primaryRed.opacity(0.35), lineWidth: 2)
                    .frame(width: 140, height: 140)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)

                Circle()
                    .fill(AppTheme.Colors.primaryRed.opacity(0.12))
                    .frame(width: 112, height: 112)
                    .scaleEffect(scale)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.secondaryRed, AppTheme.Colors.primaryRed],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 82, height: 82)
                    .shadow(color: AppTheme.Colors.primaryRed.opacity(0.35), radius: 18, x: 0, y: 8)
                    .scaleEffect(scale)

                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(scale)
            }
            .opacity(opacity)

            Text("Tudo pronto!")
                .font(AppTheme.Typography.largeTitle())
                .foregroundStyle(AppTheme.Colors.darkGray)
                .opacity(opacity)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
        .onAppear {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.68)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                ringScale = 1.45
                ringOpacity = 0.0
            }
        }
    }
}
