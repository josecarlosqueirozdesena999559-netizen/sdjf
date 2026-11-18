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
            List {
                Section("Descoberta") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label("Distância máxima", systemImage: "location.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.Colors.darkGray)
                            Spacer()
                            Text("Até \(Int(draftFilter.maxDistanceKm)) km")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.Colors.primaryRed)
                        }

                        Slider(value: $draftFilter.maxDistanceKm, in: 2...200, step: 1)
                            .tint(AppTheme.Colors.primaryRed)
                            .onChange(of: draftFilter.maxDistanceKm) { _, _ in
                                onApplyFilter(draftFilter)
                            }
                    }
                    .padding(.vertical, 4)

                    NavigationLink {
                        AgeRangeSelectionView(minAge: $draftFilter.minAge, maxAge: $draftFilter.maxAge) {
                            onApplyFilter(draftFilter)
                        }
                    } label: {
                        HStack {
                            Label("Faixa etária", systemImage: "person.2.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.Colors.darkGray)
                            Spacer()
                            Text("\(draftFilter.minAge) – \(draftFilter.maxAge) anos")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.Colors.textGray)
                        }
                    }
                }
                .listRowBackground(AppTheme.Colors.white)

                Section("Privacidade e Segurança") {
                    NavigationLink {
                        SecuritySettingsView()
                            .environmentObject(appState)
                    } label: {
                        Label("Segurança", systemImage: "lock.shield.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.Colors.darkGray)
                    }
                }
                .listRowBackground(AppTheme.Colors.white)

                Section {
                    Button {
                        dismiss()
                        appState.signOut()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.subheadline.weight(.semibold))
                            Text("Sair da conta")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(AppTheme.Colors.primaryRed)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Text("Excluir conta")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.Colors.primaryRed.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(isDeleting)
                }
                .listRowBackground(AppTheme.Colors.white)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.background)
            .tint(AppTheme.Colors.primaryRed)
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
        List {
            Section("Conta e Acesso") {
                NavigationLink {
                    ChangeUsernameView()
                        .environmentObject(appState)
                } label: {
                    securityRow(icon: "at", title: "Trocar nome de usuário", subtitle: "@\(appState.currentUser?.username ?? "")")
                }

                NavigationLink {
                    ChangeEmailView()
                        .environmentObject(appState)
                } label: {
                    securityRow(icon: "envelope.fill", title: "Alterar e-mail", subtitle: appState.currentUser?.email ?? "")
                }

                NavigationLink {
                    ChangePasswordView()
                } label: {
                    securityRow(icon: "key.fill", title: "Alterar senha", subtitle: "Atualizar sua senha de acesso")
                }
            }
            .listRowBackground(AppTheme.Colors.white)

            Section("Legal") {
                NavigationLink {
                    CombinedLegalDocumentSheet()
                } label: {
                    securityRow(icon: "doc.text.fill", title: "Termos e Privacidade (LGPD)", subtitle: "Política de dados e segurança")
                }
            }
            .listRowBackground(AppTheme.Colors.white)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.Colors.background)
        .tint(AppTheme.Colors.primaryRed)
        .navigationTitle("Segurança")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func securityRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryRed)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.Colors.darkGray)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.textGray)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
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
