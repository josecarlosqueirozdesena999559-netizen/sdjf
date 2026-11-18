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
                    NavigationLink {
                        DistanceSelectionView(selectedDistance: $draftFilter.maxDistanceKm) { newVal in
                            draftFilter.maxDistanceKm = newVal
                            onApplyFilter(draftFilter)
                        }
                    } label: {
                        HStack {
                            Label("Distância máxima", systemImage: "location.circle.fill")
                                .foregroundStyle(AppTheme.Colors.darkGray)
                            Spacer()
                            Text("\(Int(draftFilter.maxDistanceKm)) km")
                                .foregroundStyle(AppTheme.Colors.textGray)
                        }
                    }

                    NavigationLink {
                        AgeRangeSelectionView(minAge: $draftFilter.minAge, maxAge: $draftFilter.maxAge) {
                            onApplyFilter(draftFilter)
                        }
                    } label: {
                        HStack {
                            Label("Faixa etária", systemImage: "person.2.circle.fill")
                                .foregroundStyle(AppTheme.Colors.darkGray)
                            Spacer()
                            Text("\(draftFilter.minAge) – \(draftFilter.maxAge) anos")
                                .foregroundStyle(AppTheme.Colors.textGray)
                        }
                    }
                }

                Section("Privacidade e Segurança") {
                    NavigationLink {
                        SecuritySettingsView()
                            .environmentObject(appState)
                    } label: {
                        Label("Segurança", systemImage: "lock.shield.fill")
                            .foregroundStyle(AppTheme.Colors.darkGray)
                    }
                }

                Section("Conta") {
                    Button {
                        dismiss()
                        appState.signOut()
                    } label: {
                        Label("Sair da conta", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(AppTheme.Colors.darkGray)
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Excluir conta", systemImage: "trash.fill")
                            .foregroundStyle(AppTheme.Colors.primaryRed)
                    }
                    .disabled(isDeleting)
                }
            }
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

private struct DistanceSelectionView: View {
    @Binding var selectedDistance: Double
    let onSelect: (Double) -> Void
    @Environment(\.dismiss) private var dismiss

    private let options: [Double] = [5, 10, 25, 50, 100, 200]

    var body: some View {
        List {
            ForEach(options, id: \.self) { km in
                Button {
                    selectedDistance = km
                    onSelect(km)
                    dismiss()
                } label: {
                    HStack {
                        Text("Até \(Int(km)) km")
                            .foregroundStyle(AppTheme.Colors.darkGray)
                        Spacer()
                        if Int(selectedDistance) == Int(km) {
                            Image(systemName: "checkmark")
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.Colors.primaryRed)
                        }
                    }
                }
            }
        }
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
        List {
            Section("Credenciais") {
                NavigationLink {
                    ChangeUsernameView()
                        .environmentObject(appState)
                } label: {
                    HStack {
                        Label("Trocar nome de usuário", systemImage: "at")
                            .foregroundStyle(AppTheme.Colors.darkGray)
                        Spacer()
                        Text("@\(appState.currentUser?.username ?? "")")
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(AppTheme.Colors.textGray)
                    }
                }

                NavigationLink {
                    ChangeEmailView()
                        .environmentObject(appState)
                } label: {
                    HStack {
                        Label("Alterar e-mail", systemImage: "envelope.fill")
                            .foregroundStyle(AppTheme.Colors.darkGray)
                        Spacer()
                        Text(appState.currentUser?.email ?? "")
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(AppTheme.Colors.textGray)
                            .lineLimit(1)
                    }
                }

                NavigationLink {
                    ChangePasswordView()
                } label: {
                    Label("Alterar senha", systemImage: "key.fill")
                        .foregroundStyle(AppTheme.Colors.darkGray)
                }
            }

            Section("Proteção de Dados (LGPD)") {
                NavigationLink {
                    CombinedLegalDocumentSheet()
                } label: {
                    Label("Termos e Política de Privacidade", systemImage: "doc.text.fill")
                        .foregroundStyle(AppTheme.Colors.darkGray)
                }
            }
        }
        .navigationTitle("Segurança")
        .navigationBarTitleDisplayMode(.inline)
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
