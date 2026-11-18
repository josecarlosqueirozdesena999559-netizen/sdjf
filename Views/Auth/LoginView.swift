import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    private let authService: AuthServiceProtocol

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var isSearchingUser: Bool = false
    @State private var userNotFound: Bool = false
    @State private var errorMessage: String?
    @State private var userPreview: UserLookupPreview?
    @State private var lookupTask: Task<Void, Never>?

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    private var canSubmit: Bool {
        userPreview?.found == true && !password.isEmpty && !isLoading
    }

    var body: some View {
        ZStack {
            AnimatedAuthBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Top bar
                    HStack {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                appState.route = .welcome
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(
                                    Circle()
                                        .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Voltar")

                        Spacer()
                    }
                    .padding(.top, 8)

                    // Brand Hero Header
                    VStack(spacing: 14) {
                        if let logoName = BrandIdentitySlot.logoImageName {
                            Image(logoName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 72, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .strokeBorder(.white.opacity(0.28), lineWidth: 1.5)
                                )
                                .shadow(color: .black.opacity(0.32), radius: 16, x: 0, y: 8)
                        }

                        VStack(spacing: 6) {
                            Text("Bem-vindo de volta")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text("Entre com seu usuário para continuar suas conexões.")
                                .font(AppTheme.Typography.subheadline())
                                .foregroundStyle(.white.opacity(0.86))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)

                    // Main Auth Card
                    VStack(alignment: .leading, spacing: 18) {
                        MinimalTextField(
                            label: "Nome de usuário",
                            placeholder: "Digite seu @usuário",
                            text: $username,
                            textContentType: .username,
                            autocapitalization: .never,
                            disableAutocorrection: true
                        )
                        .onChange(of: username) { _, newValue in
                            scheduleLookup(for: newValue)
                        }

                        if isSearchingUser {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .tint(AppTheme.Colors.primaryRed)
                                    .scaleEffect(0.85)
                                Text("Procurando seu perfil...")
                                    .font(AppTheme.Typography.caption())
                                    .foregroundStyle(AppTheme.Colors.textGray)
                            }
                            .padding(.horizontal, 4)
                        } else if userNotFound {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 13))
                                Text("Usuário não encontrado.")
                                    .font(AppTheme.Typography.caption())
                            }
                            .foregroundStyle(AppTheme.Colors.primaryRed)
                            .padding(.horizontal, 4)
                        }

                        if let preview = userPreview, preview.found, let fullName = preview.fullName {
                            VStack(alignment: .leading, spacing: 18) {
                                HStack(spacing: 14) {
                                    avatarView(avatarUrl: preview.avatarUrl, fullName: fullName)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(AppTheme.Colors.primaryRed.opacity(0.35), lineWidth: 2)
                                        )

                                    VStack(alignment: .leading, spacing: 3) {
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

                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(AppTheme.Colors.primaryRed)
                                }
                                .padding(14)
                                .background(
                                    Color(red: 1.0, green: 0.96, blue: 0.97),
                                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(AppTheme.Colors.primaryRed.opacity(0.18), lineWidth: 1)
                                )

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
                                    HStack(spacing: 6) {
                                        Image(systemName: "xmark.octagon.fill")
                                            .font(.system(size: 13))
                                        Text(errorMessage)
                                            .font(AppTheme.Typography.caption())
                                    }
                                    .foregroundStyle(AppTheme.Colors.primaryRed)
                                }

                                PrimaryButton(title: "Entrar no Mytch", isEnabled: canSubmit, isLoading: isLoading) {
                                    Task {
                                        await submitLogin()
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(22)
                    .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 18, x: 0, y: 10)

                    // Footer link to Sign Up
                    HStack(spacing: 4) {
                        Text("Ainda não tem conta?")
                            .foregroundStyle(.white.opacity(0.85))
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                appState.route = .onboarding
                            }
                        } label: {
                            Text("Criar agora")
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .underline()
                        }
                    }
                    .font(AppTheme.Typography.subheadline())
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)
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
            .frame(width: 52, height: 52)
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
        .frame(width: 52, height: 52)
    }

    private func scheduleLookup(for value: String) {
        lookupTask?.cancel()
        errorMessage = nil
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if trimmed.count < 3 {
            withAnimation(.easeInOut(duration: 0.15)) {
                userPreview = nil
                isSearchingUser = false
                userNotFound = false
                password = ""
            }
            return
        }

        isSearchingUser = true
        userNotFound = false

        lookupTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            do {
                let result = try await authService.lookupUserPreview(trimmed)
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSearchingUser = false
                    if result.found {
                        userPreview = result
                        userNotFound = false
                    } else {
                        userPreview = nil
                        userNotFound = true
                        password = ""
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                isSearchingUser = false
                userPreview = nil
                errorMessage = error.localizedDescription
            }
        }
    }

    private func submitLogin() async {
        isLoading = true
        errorMessage = nil
        do {
            let identifier = userPreview?.username ?? username.trimmingCharacters(in: .whitespacesAndNewlines)
            let profile = try await authService.login(
                identifier: identifier,
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
