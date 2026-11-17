import SwiftUI

struct PermissionsView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Permissões")
                .font(AppTheme.Typography.largeTitle())
                .foregroundStyle(AppTheme.Colors.darkGray)
                .padding(.top, 12)

            ScrollView {
                VStack(spacing: 14) {
                    permissionCard(
                        icon: "location.fill",
                        title: "Localização",
                        bullets: [
                            "Encontrar pessoas próximas",
                            "Calcular distância aproximada",
                            "Melhorar as recomendações"
                        ],
                        isAuthorized: viewModel.permissions.locationAuthorized,
                        buttonTitle: viewModel.permissions.locationAuthorized ? "Localização ativada" : "Permitir durante o uso"
                    ) {
                        Task {
                            await viewModel.requestLocationPermission()
                        }
                    }

                    permissionCard(
                        icon: "bell.badge.fill",
                        title: "Notificações",
                        bullets: [
                            "Novos matches",
                            "Novas mensagens",
                            "Curtidas recebidas",
                            "Atividades relevantes"
                        ],
                        isAuthorized: viewModel.permissions.notificationsAuthorized,
                        buttonTitle: viewModel.permissions.notificationsAuthorized ? "Notificações ativadas" : "Ativar notificações"
                    ) {
                        Task {
                            await viewModel.requestNotificationsPermission()
                        }
                    }
                }
            }

            if let error = viewModel.submissionError {
                Text(error)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.primaryRed)
            }

            PrimaryButton(
                title: "Concluir cadastro",
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
    }

    private func permissionCard(
        icon: String,
        title: String,
        bullets: [String],
        isAuthorized: Bool,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.primaryRed)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.Colors.primaryRed.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(title)
                    .font(AppTheme.Typography.headline())
                    .foregroundStyle(AppTheme.Colors.darkGray)

                Spacer()

                if isAuthorized {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppTheme.Colors.successGreen)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(bullets, id: \.self) { bullet in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(AppTheme.Colors.primaryRed.opacity(0.7))
                            .frame(width: 5, height: 5)
                        Text(bullet)
                            .font(AppTheme.Typography.subheadline())
                            .foregroundStyle(AppTheme.Colors.textGray)
                    }
                }
            }

            Button(action: action) {
                Text(buttonTitle)
                    .font(AppTheme.Typography.subheadline())
                    .foregroundStyle(isAuthorized ? AppTheme.Colors.successGreen : AppTheme.Colors.primaryRed)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                            .fill(isAuthorized ? AppTheme.Colors.successGreen.opacity(0.1) : AppTheme.Colors.primaryRed.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)
            .disabled(isAuthorized)
        }
        .padding(16)
        .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
        )
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

            Text("Seu perfil foi configurado. Vamos começar.")
                .font(AppTheme.Typography.body())
                .foregroundStyle(AppTheme.Colors.textGray)
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
