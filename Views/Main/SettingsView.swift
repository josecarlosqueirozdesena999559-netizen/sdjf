import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var draftFilter: DiscoveryFilter
    let onApplyFilter: (DiscoveryFilter) -> Void

    @State private var showDeleteAlert = false
    @State private var isDeleting = false

    init(currentFilter: DiscoveryFilter, onApplyFilter: @escaping (DiscoveryFilter) -> Void) {
        _draftFilter = State(initialValue: currentFilter)
        self.onApplyFilter = onApplyFilter
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Descoberta — Distância com barra + Faixa etária
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Descoberta")
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(AppTheme.Colors.textGray)
                            .padding(.horizontal, 4)

                        VStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(AppTheme.Colors.primaryRed)
                                    Text("Distância máxima")
                                        .font(AppTheme.Typography.subheadline())
                                        .foregroundStyle(AppTheme.Colors.darkGray)
                                    Spacer()
                                    Text("Até \(Int(draftFilter.maxDistanceKm)) km")
                                        .font(AppTheme.Typography.subheadline())
                                        .foregroundStyle(AppTheme.Colors.primaryRed)
                                }

                                Slider(value: $draftFilter.maxDistanceKm, in: 2...200, step: 1)
                                    .tint(AppTheme.Colors.primaryRed)
                                    .onChange(of: draftFilter.maxDistanceKm) { _, _ in
                                        onApplyFilter(draftFilter)
                                    }
                            }

                            Divider()

                            NavigationLink {
                                AgeRangeSelectionView(minAge: $draftFilter.minAge, maxAge: $draftFilter.maxAge) {
                                    onApplyFilter(draftFilter)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.2")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(AppTheme.Colors.darkGray)
                                        .frame(width: 24)

                                    Text("Faixa etária")
                                        .font(AppTheme.Typography.subheadline())
                                        .foregroundStyle(AppTheme.Colors.darkGray)

                                    Spacer()

                                    Text("\(draftFilter.minAge) – \(draftFilter.maxAge) anos")
                                        .font(AppTheme.Typography.caption())
                                        .foregroundStyle(AppTheme.Colors.textGray)

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(AppTheme.Colors.textGray.opacity(0.6))
                                }
                            }
                        }
                        .padding(16)
                        .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                    }

                    // Segurança
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacidade e Segurança")
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(AppTheme.Colors.textGray)
                            .padding(.horizontal, 4)

                        NavigationLink {
                            SecuritySettingsView()
                                .environmentObject(appState)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "lock.shield")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(AppTheme.Colors.darkGray)
                                    .frame(width: 24)

                                Text("Segurança")
                                    .font(AppTheme.Typography.subheadline())
                                    .foregroundStyle(AppTheme.Colors.darkGray)

                                Spacer()

                                Text("Usuário, e-mail, senha")
                                    .font(AppTheme.Typography.caption())
                                    .foregroundStyle(AppTheme.Colors.textGray)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(AppTheme.Colors.textGray.opacity(0.6))
                            }
                            .padding(16)
                            .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                                    .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                            )
                        }
                    }

                    // Ações de Conta
                    VStack(spacing: 12) {
                        Button {
                            dismiss()
                            appState.signOut()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Sair da conta")
                                    .font(AppTheme.Typography.headline())
                            }
                            .foregroundStyle(AppTheme.Colors.darkGray)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                                    .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            showDeleteAlert = true
                        } label: {
                            Text("Excluir conta")
                                .font(AppTheme.Typography.subheadline())
                                .foregroundStyle(AppTheme.Colors.primaryRed)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .buttonStyle(.plain)
                        .disabled(isDeleting)
                    }
                    .padding(.top, 6)
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("Configurações")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.Colors.darkGray)
                            .frame(width: 30, height: 30)
                            .background(AppTheme.Colors.chipUnselected, in: Circle())
                    }
                }
            }
            .alert("Excluir conta permanentemente?", isPresented: $showDeleteAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Excluir conta", role: .destructive) {
                    Task { await deleteAccount() }
                }
            } message: {
                Text("Seu perfil será removido imediatamente da descoberta. Os registros mínimos exigidos por lei (LGPD / Marco Civil) permanecem sob sigilo pelo prazo legal.")
            }
        }
    }

    private func deleteAccount() async {
        isDeleting = true
        try? await APIClient.shared.requestVoid(path: "/lgpd/delete-account", method: "POST")
        isDeleting = false
        dismiss()
        appState.signOut()
    }
}

private struct AgeRangeSelectionView: View {
    @Binding var minAge: Int
    @Binding var maxAge: Int
    let onChanged: () -> Void

    var body: some View {
        Form {
            Section("Selecione a faixa etária") {
                Stepper("Idade mínima: \(minAge) anos", value: $minAge, in: 18...maxAge)
                Stepper("Idade máxima: \(maxAge) anos", value: $maxAge, in: minAge...80)
            }
        }
        .navigationTitle("Faixa etária")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            onChanged()
        }
    }
}

private struct SecuritySettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                NavigationLink {
                    ChangeUsernameView()
                        .environmentObject(appState)
                } label: {
                    securityRow(icon: "at", title: "Trocar nome de usuário", subtitle: "@\(appState.currentUser?.username ?? "")")
                }

                Divider().padding(.leading, 50)

                NavigationLink {
                    ChangeEmailView()
                        .environmentObject(appState)
                } label: {
                    securityRow(icon: "envelope", title: "Alterar e-mail", subtitle: appState.currentUser?.email ?? "")
                }

                Divider().padding(.leading, 50)

                NavigationLink {
                    ChangePasswordView()
                } label: {
                    securityRow(icon: "key", title: "Alterar senha", subtitle: "Atualizar sua senha de acesso")
                }

                Divider().padding(.leading, 50)

                NavigationLink {
                    CombinedLegalDocumentSheet()
                } label: {
                    securityRow(icon: "doc.text", title: "Termos e Privacidade (LGPD)", subtitle: "Política de dados e segurança")
                }
            }
            .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
            )
            .padding(AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.background)
        .navigationTitle("Segurança")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func securityRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.Colors.darkGray)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.subheadline())
                    .foregroundStyle(AppTheme.Colors.darkGray)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.textGray)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textGray.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

private struct ChangeUsernameView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var username: String = ""
    @State private var isSaving = false
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            MinimalTextField(
                label: "Novo nome de usuário",
                placeholder: "ex: seu.novo.usuario",
                text: $username,
                textContentType: .username,
                autocapitalization: .never,
                disableAutocorrection: true
            )

            if let message {
                Text(message)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.primaryRed)
            }

            PrimaryButton(
                title: "Salvar usuário",
                isEnabled: Validators.validateUsernameFormat(username) == .valid,
                isLoading: isSaving
            ) {
                Task { await save() }
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.background)
        .navigationTitle("Trocar usuário")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            username = appState.currentUser?.username ?? ""
        }
    }

    private func save() async {
        isSaving = true
        message = nil
        do {
            struct Body: Encodable { let username: String }
            let clean = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            try await APIClient.shared.requestVoid(path: "/users/me", method: "PUT", body: Body(username: clean))
            if var user = appState.currentUser {
                user.username = clean
                appState.currentUser = user
                try? await LocalUserRepository().saveProfile(user)
            }
            dismiss()
        } catch {
            message = error.localizedDescription
        }
        isSaving = false
    }
}

private struct ChangeEmailView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var isSaving = false
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            MinimalTextField(
                label: "Novo e-mail",
                placeholder: "voce@exemplo.com",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                autocapitalization: .never,
                disableAutocorrection: true
            )

            if let message {
                Text(message)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.primaryRed)
            }

            PrimaryButton(
                title: "Salvar e-mail",
                isEnabled: Validators.isValidEmail(email),
                isLoading: isSaving
            ) {
                Task { await save() }
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.background)
        .navigationTitle("Alterar e-mail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            email = appState.currentUser?.email ?? ""
        }
    }

    private func save() async {
        isSaving = true
        message = nil
        do {
            struct Body: Encodable { let email: String }
            let clean = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            try await APIClient.shared.requestVoid(path: "/users/me", method: "PUT", body: Body(email: clean))
            if var user = appState.currentUser {
                user.email = clean
                appState.currentUser = user
                try? await LocalUserRepository().saveProfile(user)
            }
            dismiss()
        } catch {
            message = error.localizedDescription
        }
        isSaving = false
    }
}

private struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var isSaving = false
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            MinimalTextField(
                label: "Senha atual",
                placeholder: "Digite sua senha atual",
                text: $currentPassword,
                textContentType: .password,
                autocapitalization: .never,
                disableAutocorrection: true,
                isSecure: true
            )

            MinimalTextField(
                label: "Nova senha",
                placeholder: "Mínimo de 8 caracteres",
                text: $newPassword,
                textContentType: .newPassword,
                autocapitalization: .never,
                disableAutocorrection: true,
                isSecure: true
            )

            if let message {
                Text(message)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.primaryRed)
            }

            PrimaryButton(
                title: "Salvar nova senha",
                isEnabled: !currentPassword.isEmpty && Validators.isValidPassword(newPassword),
                isLoading: isSaving
            ) {
                Task { await save() }
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.background)
        .navigationTitle("Alterar senha")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() async {
        isSaving = true
        message = nil
        do {
            struct Body: Encodable {
                let currentPassword: String
                let newPassword: String
            }
            try await APIClient.shared.requestVoid(
                path: "/users/password",
                method: "PUT",
                body: Body(currentPassword: currentPassword, newPassword: newPassword)
            )
            dismiss()
        } catch {
            message = error.localizedDescription
        }
        isSaving = false
    }
}
