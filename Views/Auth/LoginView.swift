import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    private let authService: AuthServiceProtocol

    @State private var identifier: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var userPreview: UserLookupPreview?
    @State private var lookupTask: Task<Void, Never>?

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

            VStack(alignment: .leading, spacing: 18) {
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

                Text("Entrar")
                    .font(AppTheme.Typography.largeTitle())
                    .foregroundStyle(AppTheme.Colors.darkGray)

                MinimalTextField(
                    label: "Nome de usuário ou e-mail",
                    placeholder: "Digite seu usuário ou e-mail",
                    text: $identifier,
                    keyboardType: .emailAddress,
                    textContentType: .username,
                    autocapitalization: .never,
                    disableAutocorrection: true
                )
                .onChange(of: identifier) { _, newValue in
                    scheduleLookup(for: newValue)
                }

                if let preview = userPreview, preview.found, let fullName = preview.fullName {
                    HStack(spacing: 12) {
                        avatarView(avatarUrl: preview.avatarUrl, fullName: fullName)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(fullName)
                                .font(AppTheme.Typography.headline())
                                .foregroundStyle(AppTheme.Colors.darkGray)
                            if let uname = preview.username {
                                Text("@\(uname)")
                                    .font(AppTheme.Typography.caption())
                                    .foregroundStyle(AppTheme.Colors.textGray)
                            }
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(AppTheme.Colors.successGreen)
                    }
                    .padding(12)
                    .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                            .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }

                MinimalTextField(
                    label: "Senha",
                    placeholder: "Digite sua senha",
                    text: $password,
                    textContentType: .password,
                    autocapitalization: .never,
                    disableAutocorrection: true,
                    isSecure: true
                )

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

    @ViewBuilder
    private func avatarView(avatarUrl: String?, fullName: String) -> some View {
        if let urlStr = avatarUrl, let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    initialsCircle(fullName: fullName)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
        } else {
            initialsCircle(fullName: fullName)
        }
    }

    private func initialsCircle(fullName: String) -> some View {
        let initial = fullName.trimmingCharacters(in: .whitespaces).prefix(1).uppercased()
        return ZStack {
            Circle()
                .fill(AppTheme.Colors.primaryRed.opacity(0.14))
            Text(initial.isEmpty ? "?" : initial)
                .font(AppTheme.Typography.headline())
                .foregroundStyle(AppTheme.Colors.primaryRed)
        }
        .frame(width: 48, height: 48)
    }

    private func scheduleLookup(for value: String) {
        lookupTask?.cancel()
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else {
            withAnimation(.easeInOut(duration: 0.15)) {
                userPreview = nil
            }
            return
        }

        lookupTask = Task {
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled else { return }
            if let result = try? await authService.lookupUserPreview(trimmed) {
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    userPreview = result.found ? result : nil
                }
            }
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
