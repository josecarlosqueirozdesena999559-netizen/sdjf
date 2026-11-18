import SwiftUI

struct PermissionsView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Permissões")
                .font(AppTheme.Typography.largeTitle())
                .foregroundStyle(AppTheme.Colors.darkGray)
                .padding(.top, 12)

            VStack(spacing: 14) {
                permissionRow(
                    icon: "location.fill",
                    title: "Permitir localização",
                    description: "Para mostrar pessoas próximas e a distância em km.",
                    isAuthorized: viewModel.permissions.locationAuthorized
                ) {
                    Task {
                        await viewModel.requestLocationPermission()
                    }
                }

                permissionRow(
                    icon: "bell.badge.fill",
                    title: "Permitir notificações",
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
            // Sync current OS statuses if already granted earlier
            viewModel.permissions.locationAuthorized = appState.permissionService.isLocationAuthorized
            viewModel.permissions.notificationsAuthorized = appState.permissionService.isNotificationAuthorized
        }
    }

    private func permissionRow(
        icon: String,
        title: String,
        description: String,
        isAuthorized: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isAuthorized ? AppTheme.Colors.successGreen : AppTheme.Colors.primaryRed)
                    .frame(width: 46, height: 46)
                    .background(
                        (isAuthorized ? AppTheme.Colors.successGreen : AppTheme.Colors.primaryRed).opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )

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
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.Colors.successGreen)
                } else {
                    Text("Permitir")
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(AppTheme.Colors.primaryRed, in: Capsule())
                }
            }
            .padding(16)
            .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isAuthorized)
    }
}

struct OnboardingCompletionView: View {
    @State private var scale: CGFloat = 0.65
    @State private var opacity: Double = 0.0

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.Colors.primaryRed.opacity(0.12))
                    .frame(width: 112, height: 112)

                Circle()
                    .fill(AppTheme.Colors.primaryRed)
                    .frame(width: 78, height: 78)
                    .shadow(color: AppTheme.Colors.primaryRed.opacity(0.3), radius: 16, x: 0, y: 8)

                Image(systemName: "checkmark")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(scale)
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
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
