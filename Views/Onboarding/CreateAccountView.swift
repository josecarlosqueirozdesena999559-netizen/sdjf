import SwiftUI

struct CreateAccountView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Vamos começar!")
                        .font(AppTheme.Typography.largeTitle())
                        .foregroundStyle(AppTheme.Colors.darkGray)

                    Text("Crie sua conta para conhecer novas pessoas.")
                        .font(AppTheme.Typography.body())
                        .foregroundStyle(AppTheme.Colors.textGray)
                }
                .padding(.top, 12)

                VStack(spacing: 16) {
                    MinimalTextField(
                        label: "Nome completo",
                        placeholder: "Seu nome completo",
                        text: $viewModel.fullName,
                        textContentType: .name,
                        autocapitalization: .words
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        MinimalTextField(
                            label: "E-mail",
                            placeholder: "voce@exemplo.com",
                            text: $viewModel.email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress,
                            autocapitalization: .never
                        )

                        if !viewModel.email.isEmpty && !viewModel.isEmailValid {
                            Text("Digite um e-mail válido.")
                                .font(AppTheme.Typography.caption())
                                .foregroundStyle(AppTheme.Colors.primaryRed)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        MinimalTextField(
                            label: "Nome de usuário",
                            placeholder: "ex: seu.nome",
                            text: $viewModel.username,
                            textContentType: .username,
                            autocapitalization: .never,
                            disableAutocorrection: true
                        )

                        usernameFeedbackView
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        MinimalTextField(
                            label: "Senha",
                            placeholder: "Mínimo de 8 caracteres",
                            text: $viewModel.password,
                            textContentType: .newPassword,
                            autocapitalization: .never,
                            isSecure: true
                        )

                        passwordRequirementsView
                    }
                }

                Spacer(minLength: 16)

                PrimaryButton(
                    title: "Continuar",
                    isEnabled: viewModel.canAdvanceFromAccount
                ) {
                    viewModel.goToNextStep()
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
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
