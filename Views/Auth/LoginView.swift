import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    private let authService: AuthServiceProtocol

    @State private var identifier: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    private var canSubmit: Bool {
        !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty && !isLoading
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            appState.route = .welcome
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.darkGray)
                            .frame(width: 38, height: 38)
                            .background(AppTheme.Colors.white, in: Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Voltar")

                    Spacer()
                }
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Entrar")
                        .font(AppTheme.Typography.largeTitle())
                        .foregroundStyle(AppTheme.Colors.darkGray)

                    Text("Acesse sua conta para continuar.")
                        .font(AppTheme.Typography.body())
                        .foregroundStyle(AppTheme.Colors.textGray)
                }

                VStack(spacing: 14) {
                    MinimalTextField(
                        label: "E-mail ou nome de usuário",
                        placeholder: "voce@exemplo.com",
                        text: $identifier,
                        keyboardType: .emailAddress,
                        textContentType: .username,
                        autocapitalization: .never,
                        disableAutocorrection: true
                    )

                    MinimalTextField(
                        label: "Senha",
                        placeholder: "Sua senha",
                        text: $password,
                        textContentType: .password,
                        autocapitalization: .never,
                        disableAutocorrection: true,
                        isSecure: true
                    )
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.primaryRed)
                }

                PrimaryButton(title: "Entrar", isEnabled: canSubmit, isLoading: isLoading) {
                    Task {
                        await submitLogin()
                    }
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
    }

    private func submitLogin() async {
        isLoading = true
        errorMessage = nil
        do {
            let profile = try await authService.login(
                identifier: identifier.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            try? await LocalUserRepository().saveProfile(profile)
            await appState.completeOnboarding(with: profile)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
