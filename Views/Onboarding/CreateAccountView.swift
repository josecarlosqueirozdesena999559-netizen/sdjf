import SwiftUI

struct AccountStepFullNameView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Nome completo")
                .font(AppTheme.Typography.largeTitle())
                .foregroundStyle(AppTheme.Colors.darkGray)
                .padding(.top, 12)

            MinimalTextField(
                label: "Nome completo",
                placeholder: "Digite seu nome",
                text: $viewModel.fullName,
                textContentType: .name,
                autocapitalization: .words
            )

            PrimaryButton(
                title: "Continuar",
                isEnabled: viewModel.isFullNameValid
            ) {
                viewModel.goToNextStep()
            }

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
}

struct AccountStepEmailView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("E-mail")
                .font(AppTheme.Typography.largeTitle())
                .foregroundStyle(AppTheme.Colors.darkGray)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 6) {
                MinimalTextField(
                    label: "E-mail",
                    placeholder: "Digite seu e-mail",
                    text: $viewModel.email,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    autocapitalization: .never,
                    disableAutocorrection: true
                )

                if !viewModel.email.isEmpty && !viewModel.isEmailValid {
                    Text("Digite um e-mail válido.")
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.primaryRed)
                }
            }

            PrimaryButton(
                title: "Continuar",
                isEnabled: viewModel.isEmailValid
            ) {
                viewModel.goToNextStep()
            }

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
}

struct AccountStepUsernameView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Nome de usuário")
                .font(AppTheme.Typography.largeTitle())
                .foregroundStyle(AppTheme.Colors.darkGray)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 6) {
                MinimalTextField(
                    label: "Nome de usuário",
                    placeholder: "Digite um nome de usuário",
                    text: $viewModel.username,
                    textContentType: .username,
                    autocapitalization: .never,
                    disableAutocorrection: true
                )

                usernameFeedbackView
            }

            PrimaryButton(
                title: "Continuar",
                isEnabled: viewModel.usernameState == .available
            ) {
                viewModel.goToNextStep()
            }

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }

    @ViewBuilder
    private var usernameFeedbackView: some View {
        switch viewModel.usernameState {
        case .idle:
            EmptyView()
        case .checking:
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.75)
                Text("Verificando disponibilidade...")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.textGray)
            }
        case .available:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                Text("Nome de usuário disponível.")
                    .font(AppTheme.Typography.caption())
            }
            .foregroundStyle(AppTheme.Colors.successGreen)
        case .unavailable:
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13))
                Text("Este nome de usuário já está em uso.")
                    .font(AppTheme.Typography.caption())
            }
            .foregroundStyle(AppTheme.Colors.primaryRed)
        case .invalid(let message):
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 13))
                Text(message)
                    .font(AppTheme.Typography.caption())
            }
            .foregroundStyle(AppTheme.Colors.primaryRed)
        }
    }
}

struct AccountStepPasswordView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Senha")
                .font(AppTheme.Typography.largeTitle())
                .foregroundStyle(AppTheme.Colors.darkGray)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 8) {
                MinimalTextField(
                    label: "Senha",
                    placeholder: "Mínimo de 8 caracteres",
                    text: $viewModel.password,
                    textContentType: .newPassword,
                    autocapitalization: .never,
                    disableAutocorrection: true,
                    isSecure: true
                )

                passwordRequirementsView
            }

            PrimaryButton(
                title: "Continuar",
                isEnabled: viewModel.isPasswordValid
            ) {
                viewModel.goToNextStep()
            }

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }

    private var passwordRequirementsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.Colors.chipUnselected)
                        .frame(height: 4)

                    Capsule()
                        .fill(passwordBarColor)
                        .frame(width: geo.size.width * viewModel.passwordStrength.progress, height: 4)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.passwordStrength.progress)
                }
            }
            .frame(height: 4)

            HStack(spacing: 6) {
                Image(systemName: viewModel.isPasswordValid ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundStyle(viewModel.isPasswordValid ? AppTheme.Colors.successGreen : AppTheme.Colors.textGray)

                Text(viewModel.password.isEmpty ? "Mínimo de 8 caracteres" : viewModel.passwordStrength.label)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(viewModel.isPasswordValid ? AppTheme.Colors.darkGray : AppTheme.Colors.textGray)
            }
        }
    }

    private var passwordBarColor: Color {
        switch viewModel.passwordStrength {
        case .empty: return AppTheme.Colors.chipUnselected
        case .tooShort: return AppTheme.Colors.primaryRed
        case .weak: return AppTheme.Colors.warningAmber
        case .medium, .strong: return AppTheme.Colors.successGreen
        }
    }
}
