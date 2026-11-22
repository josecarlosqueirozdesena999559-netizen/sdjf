import SwiftUI
import PhotosUI

struct AccountView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showAccountSettings = false
    @State private var showBlockedSheet = false
    @State private var showDisconnectAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Topo: botão lupa circular flutuante
            HStack {
                CircleNavButton(icon: "magnifyingglass") {
                    store.showToast("Busca nas configurações.", icon: "magnifyingglass")
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 12)

            Divider().opacity(0.5)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Conta")
                        .font(.inter(24, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 18)

                    // Perfil: Avatar circular geométrico + Câmera + Nome/Email + "Editar" esmeralda
                    HStack(spacing: 14) {
                        ZStack(alignment: .bottomTrailing) {
                            GeometricAvatarView(seed: store.user.username, avatarData: store.user.avatarData, size: 64)

                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 20)
                                    .background(Color(hex: "#374151"))
                                    .cornerRadius(4)
                            }
                            .offset(x: 2, y: 2)
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    store.user.avatarData = data
                                    store.showToast("Foto atualizada.", icon: "camera")
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(store.user.fullName)
                                .font(.inter(16, weight: .regular))
                                .foregroundColor(JuntoColors.textMain)
                                .lineLimit(1)
                            Text(store.user.email)
                                .font(.inter(13, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .lineLimit(1)
                        }

                        Spacer()

                        Button("Editar") {
                            showAccountSettings = true
                        }
                        .font(.inter(15, weight: .medium))
                        .foregroundColor(JuntoColors.primary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 22)

                    // Card Juntô Pro (estilo lilás suave facetado da referência)
                    VStack(spacing: 16) {
                        // Diamante geométrico roxo
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 38, weight: .light))
                            .foregroundColor(JuntoColors.proPurple)
                            .padding(.top, 8)

                        Text("Faça mais com o Juntô Pro.")
                            .font(.inter(16, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)

                        JuntoPillButton(title: "Obter Juntô Pro", color: JuntoColors.proPurple) {
                            store.showToast("Juntô Pro: Comanda IA ilimitada e Pix automático.", icon: "sparkles")
                        }
                    }
                    .padding(20)
                    .background(JuntoColors.proBgLight)
                    .cornerRadius(18)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 20)

                    // Lista limpa com ícones finos
                    accountRow(icon: "qrcode", title: "Digitalizar código") {
                        store.openPixPayment(title: "Meu QR Code Pix", recipient: store.user.fullName, amount: 25.00)
                    }
                    Divider().padding(.leading, 20)

                    accountRow(icon: "diamond.fill", iconColor: JuntoColors.proPurple, title: "Juntô Pro") {
                        store.showToast("Você já tem acesso aos recursos do Juntô.", icon: "sparkles")
                    }

                    // Preferências
                    Text("Preferências")
                        .font(.inter(13, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                        .padding(.horizontal, 20)
                        .padding(.top, 22)
                        .padding(.bottom, 8)

                    accountRow(icon: nil, title: "Configurações de conta") {
                        showAccountSettings = true
                    }
                    Divider().padding(.leading, 20)

                    accountRow(icon: nil, title: "Gerenciar lista de bloqueados") {
                        showBlockedSheet = true
                    }
                    Divider().padding(.leading, 20)

                    accountRow(icon: nil, title: "Segurança & Dispositivos") {
                        showDisconnectAlert = true
                    }

                    // Ajuda & Suporte
                    Text("Ajuda & Suporte")
                        .font(.inter(13, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                        .padding(.horizontal, 20)
                        .padding(.top, 22)
                        .padding(.bottom, 8)

                    accountRow(icon: nil, title: "Política de Privacidade (LGPD)") {
                        store.showToast("Dados protegidos com AES-256 e retenção LGPD de 90 dias.", icon: "lock.shield")
                    }
                    Divider().padding(.leading, 20)

                    accountRow(icon: nil, title: "Sair da conta", textColor: JuntoColors.danger) {
                        store.logout()
                    }
                }
                .padding(.bottom, 120)
            }
        }
        .background(Color.white)
        .fullScreenCover(isPresented: $showAccountSettings) {
            AccountSettingsScreen()
                .environmentObject(store)
        }
        .sheet(isPresented: $showBlockedSheet) {
            BlockedUsersSheetView()
                .environmentObject(store)
                .presentationDetents([.medium])
        }
        .alert("Desconectar de todos os dispositivos?", isPresented: $showDisconnectAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Desconectar todos", role: .destructive) {
                store.disconnectAllDevices()
            }
        } message: {
            Text("Todas as sessões abertas em outros aparelhos serão encerradas imediatamente.")
        }
    }

    private func accountRow(
        icon: String?,
        iconColor: Color = JuntoColors.textMain,
        title: String,
        textColor: Color = JuntoColors.textMain,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .regular))
                        .foregroundColor(iconColor)
                        .frame(width: 26)
                }

                Text(title)
                    .font(.inter(15, weight: .regular))
                    .foregroundColor(textColor)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(JuntoColors.textLight)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Tela "Configurações de conta" EXATAMENTE igual à screenshot 18.25.25 (2)
struct AccountSettingsScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    @State private var editField: EditableField? = nil
    @State private var showBlockedSheet = false
    @State private var showDisconnectAlert = false
    @State private var showDeleteAlert = false

    enum EditableField: Identifiable {
        case name, email, phone, pixKey, password
        var id: Int { hashValue }
        var label: String {
            switch self {
            case .name: return "Nome completo"
            case .email: return "Endereço de e-mail"
            case .phone: return "Telefone"
            case .pixKey: return "Chave Pix"
            case .password: return "Nova senha"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Topo: botão voltar circular + título "Configurações de conta"
            HStack {
                CircleNavButton(icon: "chevron.left") { dismiss() }
                Spacer()
                Text("Configurações de conta")
                    .font(.inter(17, weight: .regular))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Spacer().frame(width: 44)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    editableRow(label: "Nome completo", value: store.user.fullName) {
                        editField = .name
                    }

                    editableRow(label: "Endereço de e-mail", value: store.user.email) {
                        editField = .email
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        editableRow(label: "Telefone", value: "\(store.user.country.dialCode) \(store.user.phone)") {
                            editField = .phone
                        }
                        Button("Confirmar seu número de telefone") {
                            store.showToast("SMS de confirmação enviado.", icon: "message")
                        }
                        .font(.inter(14, weight: .regular))
                        .foregroundColor(JuntoColors.linkBlue)
                    }

                    editableRow(label: "Chave Pix (Recebimento)", value: store.user.pixKey) {
                        editField = .pixKey
                    }

                    editableRow(label: "Senha", value: "••••••••") {
                        editField = .password
                    }

                    // Pickers estilo pílula cinza claro igual ao modelo
                    pillPickerDisplay(label: "Fuso Horário", value: store.user.timezone)
                    pillPickerDisplay(label: "Moeda padrão", value: "BRL")
                    pillPickerDisplay(label: "Idioma (Para e-mails e notificações)", value: store.user.language)

                    // Configurações de privacidade (LGPD)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Configurações de privacidade")
                            .font(.inter(15, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)

                        HStack(alignment: .top, spacing: 10) {
                            Button {
                                store.user.allowRecommendations.toggle()
                            } label: {
                                Image(systemName: store.user.allowRecommendations ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 18))
                                    .foregroundColor(JuntoColors.linkBlue)
                            }
                            .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Permitir que o Juntô me recomende como amigo a outros usuários")
                                    .font(.inter(14, weight: .regular))
                                    .foregroundColor(JuntoColors.textMain)
                                Text("O Juntô somente recomendará você a usuários que já tenham seu e-mail ou telefone na agenda.")
                                    .font(.inter(12, weight: .regular))
                                    .italic()
                                    .foregroundColor(JuntoColors.textMuted)
                            }
                        }
                    }

                    // Botão Salvar mudanças (exatamente como no modelo)
                    Button {
                        store.showToast("Alterações salvas.", icon: "checkmark.circle")
                        dismiss()
                    } label: {
                        Text("Salvar mudanças")
                            .font(.inter(16, weight: .regular))
                            .foregroundColor(.white)
                            .padding(.horizontal, 22)
                            .frame(height: 46)
                            .background(JuntoColors.orangeSave)
                            .cornerRadius(8)
                    }
                    .padding(.top, 4)

                    // Recursos avançados (Bloqueios, Dispositivos, Excluir conta)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recursos avançados")
                            .font(.inter(20, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)
                            .padding(.top, 12)

                        advancedActionButton("Gerenciar a lista de bloqueios") {
                            showBlockedSheet = true
                        }

                        advancedActionButton("Desconectar de todos os dispositivos") {
                            showDisconnectAlert = true
                        }

                        advancedActionButton("Excluir conta", isDestructive: true) {
                            showDeleteAlert = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .sheet(item: $editField) { field in
            EditFieldSimpleSheet(field: field)
                .environmentObject(store)
                .presentationDetents([.height(250)])
        }
        .sheet(isPresented: $showBlockedSheet) {
            BlockedUsersSheetView()
                .environmentObject(store)
                .presentationDetents([.medium])
        }
        .alert("Desconectar de todos os dispositivos?", isPresented: $showDisconnectAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Desconectar todos", role: .destructive) {
                store.disconnectAllDevices()
            }
        } message: {
            Text("Todas as outras sessões serão encerradas imediatamente.")
        }
        .alert("Excluir conta?", isPresented: $showDeleteAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Excluir conta", role: .destructive) {
                dismiss()
                store.deleteAccountPermanently()
            }
        } message: {
            Text("Sua conta será desativada imediatamente e os dados ficarão em retenção segura LGPD por 90 dias antes da anonimização definitiva.")
        }
    }

    private func editableRow(label: String, value: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.inter(14, weight: .regular))
                .foregroundColor(JuntoColors.textMain)

            HStack(spacing: 8) {
                Text(value)
                    .font(.inter(17, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)

                Button(action: action) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 13))
                        Text("Editar")
                            .font(.inter(14, weight: .regular))
                    }
                    .foregroundColor(JuntoColors.linkBlue)
                }
            }
        }
    }

    private func pillPickerDisplay(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.inter(14, weight: .regular))
                .foregroundColor(JuntoColors.textMain)

            HStack {
                Text(value)
                    .font(.inter(15, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(JuntoColors.textMain)
            }
            .padding(.horizontal, 14)
            .frame(width: 240, height: 38)
            .background(JuntoColors.surfaceSubtle)
            .overlay(Capsule().stroke(JuntoColors.border, lineWidth: 1))
            .clipShape(Capsule())
        }
    }

    private func advancedActionButton(_ title: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.inter(14, weight: .regular))
                .foregroundColor(isDestructive ? JuntoColors.danger : JuntoColors.textMain)
                .padding(.horizontal, 16)
                .frame(height: 42)
                .background(isDestructive ? JuntoColors.dangerLight : JuntoColors.surfaceSubtle)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isDestructive ? JuntoColors.danger.opacity(0.3) : JuntoColors.border, lineWidth: 1)
                )
                .cornerRadius(6)
        }
    }
}

struct EditFieldSimpleSheet: View {
    @EnvironmentObject var store: JuntoStore
    let field: AccountSettingsScreen.EditableField
    @State private var text: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(field.label)
                .font(.inter(18, weight: .regular))
                .foregroundColor(JuntoColors.textMain)
                .padding(.top, 20)

            CleanOutlineInput(label: "", placeholder: "Digite o novo valor", text: $text)

            JuntoPillButton(title: "Salvar", color: JuntoColors.primary) {
                let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !clean.isEmpty else { return }
                switch field {
                case .name: store.user.fullName = clean
                case .email: store.user.email = clean
                case .phone: store.user.phone = clean
                case .pixKey: store.user.pixKey = clean
                case .password: break
                }
                store.showToast("Atualizado.", icon: "checkmark.circle")
                dismiss()
            }
            Spacer()
        }
        .padding(.horizontal, 22)
        .background(Color.white)
        .onAppear {
            switch field {
            case .name: text = store.user.fullName
            case .email: text = store.user.email
            case .phone: text = store.user.phone
            case .pixKey: text = store.user.pixKey
            case .password: text = ""
            }
        }
    }
}

struct BlockedUsersSheetView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var newHandle: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Lista de bloqueios")
                    .font(.inter(18, weight: .regular))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Button("Fechar") { dismiss() }
                    .font(.inter(14, weight: .regular))
                    .foregroundColor(JuntoColors.primary)
            }
            .padding(.top, 20)

            HStack(spacing: 8) {
                CleanOutlineInput(label: "", placeholder: "usuario", text: $newHandle, autocapitalization: .never, leadingPrefix: "@")
                Button("Bloquear") {
                    store.blockUser(newHandle)
                    newHandle = ""
                }
                .font(.inter(14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(JuntoColors.danger)
                .cornerRadius(10)
            }

            if store.blockedUsernames.isEmpty {
                Text("Nenhum usuário bloqueado.")
                    .font(.inter(14, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
                    .padding(.top, 8)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(store.blockedUsernames, id: \.self) { handle in
                            HStack {
                                Text("@\(handle)")
                                    .font(.inter(15, weight: .regular))
                                    .foregroundColor(JuntoColors.textMain)
                                Spacer()
                                Button("Desbloquear") {
                                    store.unblockUser(handle)
                                }
                                .font(.inter(13, weight: .regular))
                                .foregroundColor(JuntoColors.linkBlue)
                            }
                            .padding(.vertical, 12)
                            Divider()
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 22)
        .background(Color.white)
    }
}
