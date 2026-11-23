import SwiftUI
import PhotosUI

struct AccountView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showAccountSettings = false
    @State private var showSecurityPrivacy = false
    @State private var showAddBalanceSheet = false
    @State private var hideWalletBalance = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Conta")
                        .font(.inter(24, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 18)

                    // Perfil: Avatar + Câmera + Nome/Email + "Editar"
                    HStack(spacing: 14) {
                        ZStack(alignment: .bottomTrailing) {
                            GeometricAvatarView(seed: store.user.username, displayName: store.user.fullName, avatarData: store.user.avatarData, size: 64)

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
                            Text("@\(store.user.username)")
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
                    .padding(.bottom, 18)

                    // Cartão Carteira do Usuário (Saldo + Botão Adicionar Saldo)
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "wallet.pass.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(JuntoColors.accent)
                                Text("Carteira Juntô")
                                    .font(.inter(13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            Spacer()
                            Button {
                                hideWalletBalance.toggle()
                            } label: {
                                Image(systemName: hideWalletBalance ? "eye.slash" : "eye")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.75))
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Saldo disponível")
                                .font(.inter(11, weight: .regular))
                                .foregroundColor(.white.opacity(0.65))
                            Text(hideWalletBalance ? "R$ •••••" : JuntoStore.formatBRL(store.walletBalance))
                                .font(.inter(26, weight: .medium))
                                .foregroundColor(.white)
                        }

                        Button {
                            showAddBalanceSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Adicionar saldo")
                                    .font(.inter(14, weight: .medium))
                            }
                            .foregroundColor(JuntoColors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    .padding(18)
                    .background(JuntoColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)

                    // Card Juntô Pro
                    VStack(spacing: 16) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(JuntoColors.proIndigo)
                            .padding(.top, 6)

                        Text("Faça mais com o Juntô Pro.")
                            .font(.inter(16, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)

                        JuntoPillButton(title: "Obter Juntô Pro", color: JuntoColors.proIndigo) {
                            store.showToast("Juntô Pro: Comanda IA ilimitada e Pix automático.", icon: "sparkles")
                        }
                    }
                    .padding(20)
                    .background(JuntoColors.proBgLight)
                    .cornerRadius(16)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 20)

                    // Menu limpo (Segurança e privacidade em menu exclusivo!)
                    accountRow(icon: "qrcode", title: "Meu código Pix") {
                        store.openPixPayment(title: "Meu QR Code Pix", recipient: store.user.fullName, amount: 25.00)
                    }
                    Divider().padding(.leading, 20)

                    accountRow(icon: "person", title: "Editar perfil") {
                        showAccountSettings = true
                    }
                    Divider().padding(.leading, 20)

                    accountRow(icon: "lock.shield", title: "Segurança e privacidade") {
                        showSecurityPrivacy = true
                    }
                    Divider().padding(.leading, 20)

                    accountRow(icon: "doc.text", title: "Política de Privacidade (LGPD)") {
                        store.showToast("Dados protegidos com AES-256 e retenção LGPD de 90 dias.", icon: "lock.shield")
                    }
                    Divider().padding(.leading, 20)

                    accountRow(icon: "rectangle.portrait.and.arrow.right", iconColor: JuntoColors.danger, title: "Sair da conta", textColor: JuntoColors.danger) {
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
        .fullScreenCover(isPresented: $showSecurityPrivacy) {
            SecurityPrivacyScreen()
                .environmentObject(store)
        }
        .sheet(isPresented: $showAddBalanceSheet) {
            AddWalletBalanceSheet()
                .environmentObject(store)
                .presentationDetents([.height(340)])
                .presentationCornerRadius(20)
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
                        .font(.system(size: 18, weight: .regular))
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

// MARK: - Tela "Editar perfil" (botão Salvar aparece SOMENTE quando houver alterações, sem texto de contato)
struct AccountSettingsScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var editField: EditableField? = nil

    // Rascunho local para detectar se houve alteração real
    @State private var draftName: String = ""
    @State private var draftEmail: String = ""
    @State private var draftPhone: String = ""
    @State private var draftPixKey: String = ""
    @State private var draftAvatarData: Data? = nil
    @State private var passwordChanged: Bool = false

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

    private var hasChanges: Bool {
        draftName != store.user.fullName ||
        draftEmail != store.user.email ||
        draftPhone != store.user.phone ||
        draftPixKey != store.user.pixKey ||
        draftAvatarData != store.user.avatarData ||
        passwordChanged
    }

    var body: some View {
        ZStack {
            JuntoColors.warmBg.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    CircleNavButton(icon: "chevron.left") { dismiss() }
                    Spacer()
                    Text("Editar perfil")
                        .font(.inter(17, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Spacer()
                    Spacer().frame(width: 44)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 14)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Foto / Avatar
                        VStack(spacing: 12) {
                            ZStack(alignment: .bottomTrailing) {
                                GeometricAvatarView(
                                    seed: store.user.username,
                                    displayName: draftName,
                                    avatarData: draftAvatarData,
                                    size: 84
                                )

                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                        .frame(width: 28, height: 28)
                                        .background(JuntoColors.primary)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                }
                            }
                            .onChange(of: selectedPhotoItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        draftAvatarData = data
                                    }
                                }
                            }

                            VStack(spacing: 2) {
                                Text(draftName)
                                    .font(.inter(17, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                                Text("@\(store.user.username) · 🇧🇷 Brasil")
                                    .font(.inter(13, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Dados da conta
                        VStack(alignment: .leading, spacing: 0) {
                            Text("DADOS DA CONTA")
                                .font(.inter(11, weight: .medium))
                                .tracking(0.8)
                                .foregroundColor(JuntoColors.textMuted)
                                .padding(.horizontal, 16)
                                .padding(.top, 14)
                                .padding(.bottom, 6)

                            profileFieldRow(icon: "person", label: "Nome completo", value: draftName) {
                                editField = .name
                            }
                            Divider().padding(.leading, 54)

                            profileFieldRow(icon: "envelope", label: "E-mail", value: draftEmail) {
                                editField = .email
                            }
                            Divider().padding(.leading, 54)

                            profileFieldRow(icon: "phone", label: "Telefone (Brasil)", value: "+55 \(draftPhone)") {
                                editField = .phone
                            }
                            Divider().padding(.leading, 54)

                            profileFieldRow(icon: "qrcode", label: "Chave Pix", value: draftPixKey) {
                                editField = .pixKey
                            }
                            Divider().padding(.leading, 54)

                            profileFieldRow(icon: "lock", label: "Senha", value: passwordChanged ? "Nova senha definida" : "••••••••") {
                                editField = .password
                            }
                        }
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Botão Salvar aparece SOMENTE quando houver alterações!
                        if hasChanges {
                            JuntoPillButton(title: "Salvar alterações", color: JuntoColors.primary) {
                                store.user.fullName = draftName
                                store.user.email = draftEmail
                                store.user.phone = draftPhone
                                store.user.pixKey = draftPixKey
                                store.user.avatarData = draftAvatarData
                                passwordChanged = false
                                store.showToast("Alterações salvas.", icon: "checkmark.circle")
                                dismiss()
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            draftName = store.user.fullName
            draftEmail = store.user.email
            draftPhone = store.user.phone
            draftPixKey = store.user.pixKey
            draftAvatarData = store.user.avatarData
        }
        .sheet(item: $editField) { field in
            EditDraftFieldSheet(
                field: field,
                initialValue: currentDraftValue(for: field)
            ) { newValue in
                switch field {
                case .name: draftName = newValue
                case .email: draftEmail = newValue
                case .phone: draftPhone = newValue
                case .pixKey: draftPixKey = newValue
                case .password: passwordChanged = true
                }
            }
            .presentationDetents([.height(240)])
        }
    }

    private func currentDraftValue(for field: EditableField) -> String {
        switch field {
        case .name: return draftName
        case .email: return draftEmail
        case .phone: return draftPhone
        case .pixKey: return draftPixKey
        case .password: return ""
        }
    }

    private func profileFieldRow(icon: String, label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(JuntoColors.primary)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                    Text(value)
                        .font(.inter(14, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(JuntoColors.textLight)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
    }
}

struct EditDraftFieldSheet: View {
    let field: AccountSettingsScreen.EditableField
    let initialValue: String
    let onSave: (String) -> Void
    @State private var text: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(field.label)
                .font(.inter(18, weight: .medium))
                .foregroundColor(JuntoColors.textMain)
                .padding(.top, 20)

            CleanOutlineInput(label: "", placeholder: "Digite o novo valor", text: $text)

            JuntoPillButton(title: "Aplicar", color: JuntoColors.primary) {
                let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !clean.isEmpty else { return }
                onSave(clean)
                dismiss()
            }
            Spacer()
        }
        .padding(.horizontal, 22)
        .background(Color.white)
        .onAppear { text = initialValue }
    }
}

// MARK: - Menu Exclusivo: Segurança e Privacidade (abre 3 telas próprias!)
struct SecurityPrivacyScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    @State private var showBlockedScreen = false
    @State private var showDevicesScreen = false
    @State private var showDeleteScreen = false

    var body: some View {
        ZStack {
            JuntoColors.warmBg.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    CircleNavButton(icon: "chevron.left") { dismiss() }
                    Spacer()
                    Text("Segurança e privacidade")
                        .font(.inter(17, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Spacer()
                    Spacer().frame(width: 44)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        VStack(spacing: 0) {
                            menuCardRow(
                                icon: "nosign",
                                iconColor: JuntoColors.primary,
                                title: "Lista de bloqueados",
                                subtitle: "\(store.blockedUsers.count) usuário(s) bloqueado(s)"
                            ) {
                                showBlockedScreen = true
                            }

                            Divider().padding(.leading, 58)

                            menuCardRow(
                                icon: "iphone.and.arrow.forward",
                                iconColor: JuntoColors.primary,
                                title: "Dispositivos conectados",
                                subtitle: "\(store.connectedDevices.count) aparelho(s) ativo(s)"
                            ) {
                                showDevicesScreen = true
                            }

                            Divider().padding(.leading, 58)

                            menuCardRow(
                                icon: "trash",
                                iconColor: JuntoColors.danger,
                                title: "Excluir conta",
                                subtitle: "Encerrar acesso e iniciar retenção LGPD",
                                isDestructive: true
                            ) {
                                showDeleteScreen = true
                            }
                        }
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .fullScreenCover(isPresented: $showBlockedScreen) {
            BlockedUsersScreen()
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showDevicesScreen) {
            ConnectedDevicesScreen()
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showDeleteScreen) {
            DeleteAccountScreen {
                dismiss()
            }
            .environmentObject(store)
        }
    }

    private func menuCardRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(iconColor)
                    .frame(width: 34, height: 34)
                    .background(isDestructive ? JuntoColors.dangerLight : JuntoColors.primaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.inter(15, weight: .medium))
                        .foregroundColor(isDestructive ? JuntoColors.danger : JuntoColors.textMain)
                    Text(subtitle)
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(JuntoColors.textLight)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Tela Própria 1: Lista de Bloqueados (foto + nome + @usuário + botão Desbloquear)
struct BlockedUsersScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                CircleNavButton(icon: "chevron.left") { dismiss() }
                Spacer()
                Text("Lista de bloqueados")
                    .font(.inter(17, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Spacer().frame(width: 44)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 16)

            Divider().opacity(0.6)

            if store.blockedUsers.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 34, weight: .thin))
                        .foregroundColor(JuntoColors.textLight)
                    Text("Nenhum usuário bloqueado.")
                        .font(.inter(15, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(store.blockedUsers) { entry in
                            HStack(spacing: 12) {
                                GeometricAvatarView(seed: entry.username, size: 44)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.name)
                                        .font(.inter(15, weight: .medium))
                                        .foregroundColor(JuntoColors.textMain)
                                    Text("@\(entry.username)")
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                }

                                Spacer()

                                Button {
                                    withAnimation { store.unblockUser(entry.username) }
                                } label: {
                                    Text("Desbloquear")
                                        .font(.inter(13, weight: .medium))
                                        .foregroundColor(JuntoColors.primary)
                                        .padding(.horizontal, 14)
                                        .frame(height: 34)
                                        .background(JuntoColors.primaryLight)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)

                            Divider().padding(.leading, 76)
                        }
                    }
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}

// MARK: - Tela Própria 2: Dispositivos Conectados (reais + desconectar individualmente ou todos)
struct ConnectedDevicesScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDevice: ConnectedDeviceSession? = nil

    var body: some View {
        ZStack {
            JuntoColors.warmBg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    CircleNavButton(icon: "chevron.left") { dismiss() }
                    Spacer()
                    Text("Dispositivos conectados")
                        .font(.inter(17, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Spacer()
                    Spacer().frame(width: 44)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(spacing: 0) {
                            ForEach(store.connectedDevices) { device in
                                Button {
                                    if !device.isCurrentDevice {
                                        selectedDevice = device
                                    }
                                } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: device.deviceName.lowercased().contains("ipad") ? "ipad" : "iphone")
                                            .font(.system(size: 20, weight: .light))
                                            .foregroundColor(device.isCurrentDevice ? JuntoColors.pixGreen : JuntoColors.primary)
                                            .frame(width: 30)

                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 6) {
                                                Text(device.deviceName)
                                                    .font(.inter(15, weight: .medium))
                                                    .foregroundColor(JuntoColors.textMain)
                                                if device.isCurrentDevice {
                                                    Text("Este aparelho")
                                                        .font(.inter(10, weight: .medium))
                                                        .foregroundColor(JuntoColors.pixGreen)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(JuntoColors.pixGreenLight)
                                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                                }
                                            }
                                            Text("\(device.systemInfo) · \(device.locationText)")
                                                .font(.inter(12, weight: .regular))
                                                .foregroundColor(JuntoColors.textMuted)
                                            Text(device.lastActiveText)
                                                .font(.inter(11, weight: .regular))
                                                .foregroundColor(device.isCurrentDevice ? JuntoColors.pixGreen : JuntoColors.textLight)
                                        }

                                        Spacer()

                                        if !device.isCurrentDevice {
                                            Text("Desconectar")
                                                .font(.inter(12, weight: .medium))
                                                .foregroundColor(JuntoColors.danger)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                                Divider().padding(.leading, 60)
                            }
                        }
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        if store.connectedDevices.count > 1 {
                            JuntoOutlineButton(title: "Desconectar todos os outros aparelhos", color: JuntoColors.danger) {
                                withAnimation { store.disconnectAllDevices() }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .sheet(item: $selectedDevice) { device in
            VStack(alignment: .leading, spacing: 18) {
                Text("Desconectar \(device.deviceName)?")
                    .font(.inter(18, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                    .padding(.top, 20)

                Text("\(device.systemInfo) · \(device.locationText) · \(device.lastActiveText)")
                    .font(.inter(13, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)

                JuntoPillButton(title: "Desconectar este aparelho", color: JuntoColors.danger) {
                    withAnimation { store.disconnectDevice(device.id) }
                    selectedDevice = nil
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .background(JuntoColors.warmBg.ignoresSafeArea())
            .presentationDetents([.height(220)])
            .presentationCornerRadius(20)
        }
    }
}

// MARK: - Tela Própria 3: Excluir Conta (confirmação clara + LGPD)
struct DeleteAccountScreen: View {
    @EnvironmentObject var store: JuntoStore
    var onDeleted: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var confirmed: Bool = false

    var body: some View {
        ZStack {
            JuntoColors.warmBg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    CircleNavButton(icon: "chevron.left") { dismiss() }
                    Spacer()
                    Text("Excluir conta")
                        .font(.inter(17, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Spacer()
                    Spacer().frame(width: 44)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 20)

                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 26, weight: .light))
                            .foregroundColor(JuntoColors.danger)

                        Text("Tem certeza que deseja excluir sua conta?")
                            .font(.inter(20, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)

                        Text("• Seu acesso e todas as sessões serão encerrados imediatamente.\n• Seus dados ficarão em retenção segura por 90 dias conforme a LGPD antes da anonimização definitiva.\n• Seu @usuário ficará indisponível durante esse período.")
                            .font(.inter(14, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                            .lineSpacing(4)
                    }
                    .padding(18)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    Button {
                        confirmed.toggle()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: confirmed ? "checkmark.square.fill" : "square")
                                .font(.system(size: 20))
                                .foregroundColor(confirmed ? JuntoColors.danger : JuntoColors.textMuted)
                            Text("Entendo e quero excluir minha conta")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMain)
                        }
                    }

                    JuntoPillButton(
                        title: "Confirmar e excluir conta",
                        color: confirmed ? JuntoColors.danger : JuntoColors.border,
                        textColor: confirmed ? .white : JuntoColors.textMuted
                    ) {
                        guard confirmed else { return }
                        dismiss()
                        onDeleted()
                        store.deleteAccountPermanently()
                    }
                    .disabled(!confirmed)
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
    }
}

// MARK: - Sheet para Adicionar Saldo à Carteira via Pix
struct AddWalletBalanceSheet: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    @State private var amountText: String = "100"
    private let presets: [Double] = [50, 100, 200]

    private var numericAmount: Double {
        let cleaned = amountText
            .replacingOccurrences(of: "R$", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleaned) ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Adicionar saldo")
                        .font(.inter(18, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Text("Use o saldo para pagar cotas e despesas dos grupos")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(JuntoColors.textMuted)
                        .frame(width: 32, height: 32)
                        .background(JuntoColors.surfaceSubtle)
                        .clipShape(Circle())
                }
            }
            .padding(.top, 20)

            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { val in
                    let active = numericAmount == val
                    Button {
                        amountText = "\(Int(val))"
                    } label: {
                        Text("+ \(JuntoStore.formatBRL(val))")
                            .font(.inter(13, weight: .medium))
                            .foregroundColor(active ? .white : JuntoColors.textMain)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(active ? JuntoColors.primary : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(active ? JuntoColors.primary : JuntoColors.border, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            CleanOutlineInput(
                label: "Valor do depósito (R$)",
                placeholder: "0,00",
                text: $amountText,
                keyboardType: .decimalPad,
                leadingPrefix: "R$"
            )

            JuntoPillButton(
                title: "Adicionar \(JuntoStore.formatBRL(max(numericAmount, 0))) via Pix",
                icon: "plus.circle",
                color: JuntoColors.pixGreen
            ) {
                guard numericAmount > 0 else {
                    store.showToast("Informe um valor válido.", icon: "exclamationmark.circle")
                    return
                }
                store.addWalletBalance(numericAmount)
                dismiss()
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(JuntoColors.warmBg.ignoresSafeArea())
    }
}
