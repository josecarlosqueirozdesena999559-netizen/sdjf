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
                    // Descoberta
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Descoberta")
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(AppTheme.Colors.textGray)
                            .padding(.horizontal, 4)

                        VStack(spacing: 0) {
                            NavigationLink {
                                DistanceSelectionView(selectedDistance: $draftFilter.maxDistanceKm) { newVal in
                                    draftFilter.maxDistanceKm = newVal
                                    onApplyFilter(draftFilter)
                                }
                            } label: {
                                settingsRow(
                                    icon: "location.north.fill",
                                    title: "Distância máxima",
                                    value: "\(Int(draftFilter.maxDistanceKm)) km"
                                )
                            }

                            Divider().padding(.leading, 62)

                            NavigationLink {
                                AgeRangeSelectionView(minAge: $draftFilter.minAge, maxAge: $draftFilter.maxAge) {
                                    onApplyFilter(draftFilter)
                                }
                            } label: {
                                settingsRow(
                                    icon: "person.2.fill",
                                    title: "Faixa etária",
                                    value: "\(draftFilter.minAge) – \(draftFilter.maxAge) anos"
                                )
                            }
                        }
                        .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                    }

                    // Segurança
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Segurança e Privacidade")
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(AppTheme.Colors.textGray)
                            .padding(.horizontal, 4)

                        NavigationLink {
                            SecuritySettingsView()
                                .environmentObject(appState)
                        } label: {
                            settingsRow(
                                icon: "lock.shield.fill",
                                title: "Segurança",
                                value: "Usuário, e-mail, senha"
                            )
                        }
                        .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                    }

                    // Conta
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Conta")
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(AppTheme.Colors.textGray)
                            .padding(.horizontal, 4)

                        VStack(spacing: 0) {
                            Button {
                                dismiss()
                                appState.signOut()
                            } label: {
                                settingsRow(
                                    icon: "rectangle.portrait.and.arrow.right",
                                    title: "Sair da conta",
                                    value: nil,
                                    showChevron: false
                                )
                            }
                            .buttonStyle(.plain)

                            Divider().padding(.leading, 62)

                            Button {
                                showDeleteAlert = true
                            } label: {
                                settingsRow(
                                    icon: "trash.fill",
                                    title: "Excluir conta",
                                    value: nil,
                                    isDestructive: true,
                                    showChevron: false
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isDeleting)
                        }
                        .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                    }
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

    private func settingsRow(
        icon: String,
        title: String,
        value: String?,
        isDestructive: Bool = false,
        showChevron: Bool = true
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isDestructive
                            ? [AppTheme.Colors.primaryRed, AppTheme.Colors.primaryRed]
                            : [AppTheme.Colors.secondaryRed, AppTheme.Colors.primaryRed],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(title)
                .font(AppTheme.Typography.subheadline())
                .foregroundStyle(isDestructive ? AppTheme.Colors.primaryRed : AppTheme.Colors.darkGray)

            Spacer()

            if let value {
                Text(value)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.textGray)
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textGray.opacity(0.7))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func deleteAccount() async {
        isDeleting = true
        try? await APIClient.shared.requestVoid(path: "/lgpd/delete-account", method: "POST")
        isDeleting = false
        dismiss()
        appState.signOut()
    }
}

private struct DistanceSelectionView: View {
    @Binding var selectedDistance: Double
    let onSelect: (Double) -> Void
    @Environment(\.dismiss) private var dismiss

    private let options: [Double] = [5, 10, 25, 50, 100, 200]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.element) { index, km in
                    Button {
                        selectedDistance = km
                        onSelect(km)
                        dismiss()
                    } label: {
                        HStack {
                            Text("Até \(Int(km)) km")
                                .font(AppTheme.Typography.subheadline())
                                .foregroundStyle(AppTheme.Colors.darkGray)
                            Spacer()
                            if Int(selectedDistance) == Int(km) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(AppTheme.Colors.primaryRed)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < options.count - 1 {
                        Divider().padding(.leading, 16)
                    }
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
        .navigationTitle("Distância máxima")
        .navigationBarTitleDisplayMode(.inline)
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

                Divider().padding(.leading, 62)

                NavigationLink {
                    ChangeEmailView()
                        .environmentObject(appState)
                } label: {
                    securityRow(icon: "envelope.fill", title: "Alterar e-mail", subtitle: appState.currentUser?.email ?? "")
                }

                Divider().padding(.leading, 62)

                NavigationLink {
                    ChangePasswordView()
                } label: {
                    securityRow(icon: "key.fill", title: "Alterar senha", subtitle: "Atualizar sua senha de acesso")
                }

                Divider().padding(.leading, 62)

                NavigationLink {
                    CombinedLegalDocumentSheet()
                } label: {
                    securityRow(icon: "doc.text.fill", title: "Termos e Privacidade (LGPD)", subtitle: "Política de dados e segurança")
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
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.secondaryRed, AppTheme.Colors.primaryRed],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }

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
                .foregroundStyle(AppTheme.Colors.textGray.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
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
