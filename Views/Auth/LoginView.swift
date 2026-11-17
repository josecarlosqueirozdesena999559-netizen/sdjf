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
                    label: "Nome de usuário",
                    placeholder: "Digite seu nome de usuário",
                    text: $username,
                    textContentType: .username,
                    autocapitalization: .never,
                    disableAutocorrection: true
                )
                .onChange(of: username) { _, newValue in
                    scheduleLookup(for: newValue)
                }

                if isSearchingUser {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Procurando usuário...")
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(AppTheme.Colors.textGray)
                    }
                } else if userNotFound {
                    Text("Usuário não encontrado.")
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.primaryRed)
                }

                if let preview = userPreview, preview.found, let fullName = preview.fullName {
                    VStack(alignment: .leading, spacing: 16) {
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
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

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
