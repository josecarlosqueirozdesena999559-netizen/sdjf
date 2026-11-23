import SwiftUI
import PhotosUI
import CoreImage.CIFilterBuiltins

struct AccountView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showAccountSettings = false
    @State private var showSecurityPrivacy = false
    @State private var showInviteQRCode = false
    @State private var showInviteFriends = false
    @State private var showPrivacyPolicy = false
    @State private var showProSubscription = false

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
                            HStack(spacing: 6) {
                                Text(store.user.fullName)
                                    .font(.inter(16, weight: .regular))
                                    .foregroundColor(JuntoColors.textMain)
                                    .lineLimit(1)

                                if store.user.isPro {
                                    HStack(spacing: 3) {
                                        JuntoIcon(kind: .crown, size: 10, color: JuntoColors.accent)
                                        Text("PRO")
                                            .font(.inter(9, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        LinearGradient(
                                            colors: [JuntoColors.primary, JuntoColors.proIndigo],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Capsule())
                                    .shadow(color: JuntoColors.accent.opacity(0.3), radius: 3)
                                }
                            }

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

                    // Card Juntô Pro (R$ 19,90/mês: Mercado Pago, Bot WhatsApp, Alertas e IA)
                    VStack(spacing: 14) {
                        JuntoProBadgeIcon(size: 52)
                            .padding(.top, 4)

                        VStack(spacing: 4) {
                            Text(store.user.isPro ? "Você é Juntô Pro ativo 👑" : "Juntô Pro • R$ 19,90/mês")
                                .font(.inter(16, weight: .semibold))
                                .foregroundColor(JuntoColors.textMain)
                            Text(store.user.isPro ? "Mercado Pago automático, Bot WhatsApp oficial e IA liberados." : "Pagamentos Mercado Pago, API WhatsApp oficial, alertas inteligentes e planos de economia com IA.")
                                .font(.inter(12, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .multilineTextAlignment(.center)
                        }

                        JuntoPillButton(
                            title: store.user.isPro ? "Gerenciar assinatura Pro" : "Conhecer o Juntô Pro (R$ 19,90)",
                            color: JuntoColors.proIndigo
                        ) {
                            showProSubscription = true
                        }
                    }
                    .padding(20)
                    .background(JuntoColors.proBgLight)
                    .cornerRadius(16)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 20)

                    // Menu limpo (sem Pix no perfil — QR Code de convite para adicionar amigos!)
                    accountRow(icon: .inviteQR, title: "QR Code de convite") {
                        showInviteQRCode = true
                    }
                    Divider().padding(.leading, 20)

                    accountRow(icon: .inviteFriends, title: "Convidar amigos") {
                        showInviteFriends = true
                    }
                    Divider().padding(.leading, 20)

                    accountRow(icon: .person, title: "Editar perfil") {
                        showAccountSettings = true
                    }
                    Divider().padding(.leading, 20)

                    accountRow(icon: .lock, title: "Segurança e privacidade") {
                        showSecurityPrivacy = true
                    }
                    Divider().padding(.leading, 20)

                    accountRow(icon: .docText, title: "Política de Privacidade (LGPD)") {
                        showPrivacyPolicy = true
                    }
                    Divider().padding(.leading, 20)

                    accountRow(icon: .logout, iconColor: JuntoColors.danger, title: "Sair da conta", textColor: JuntoColors.danger) {
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
        .fullScreenCover(isPresented: $showInviteQRCode) {
            MyInviteQRCodeScreen()
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showInviteFriends) {
            InviteFriendsScreen()
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyScreen()
        }
        .fullScreenCover(isPresented: $showProSubscription) {
            JuntoProSubscriptionScreen()
                .environmentObject(store)
        }
    }

    private func accountRow(
        icon: JuntoIconKind?,
        iconColor: Color = JuntoColors.textMain,
        title: String,
        textColor: Color = JuntoColors.textMain,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let icon = icon {
                    JuntoIcon(kind: icon, size: 20, color: iconColor, weight: 1.6)
                        .frame(width: 26)
                }

                Text(title)
                    .font(.inter(15, weight: .regular))
                    .foregroundColor(textColor)

                Spacer()

                JuntoIcon(kind: .chevronRight, size: 16, color: JuntoColors.textLight, weight: 1.6)
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

                            Divider().padding(.leading, 54)

                            menuCardRow(
                                icon: "iphone.and.arrow.forward",
                                iconColor: JuntoColors.primary,
                                title: "Dispositivos conectados",
                                subtitle: "\(store.connectedDevices.count) aparelho(s) ativo(s)"
                            ) {
                                showDevicesScreen = true
                            }

                            Divider().padding(.leading, 54)

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
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(iconColor)
                    .frame(width: 24)

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

// MARK: - Emblema Premium Customizado do Juntô Pro
struct JuntoProBadgeIcon: View {
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [JuntoColors.primary, JuntoColors.proIndigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: JuntoColors.proIndigo.opacity(0.28), radius: 10, y: 4)

            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .stroke(JuntoColors.accent.opacity(0.65), lineWidth: 1.2)
                .frame(width: size * 0.86, height: size * 0.86)

            Image(systemName: "crown.fill")
                .font(.system(size: size * 0.36, weight: .medium))
                .foregroundColor(JuntoColors.accent)

            Image(systemName: "sparkle")
                .font(.system(size: size * 0.16, weight: .semibold))
                .foregroundColor(.white)
                .offset(x: size * 0.26, y: -size * 0.24)
        }
    }
}

// MARK: - Tela "QR Code de convite" (as pessoas leem e te adicionam no Juntô)
struct MyInviteQRCodeScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    private var inviteLink: String {
        "https://junto.app/convite/\(store.user.username)"
    }

    private func generateQRCodeImage(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "H"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 9, y: 9))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    var body: some View {
        ZStack {
            JuntoColors.warmBg.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    CircleNavButton(icon: "chevron.left") { dismiss() }
                    Spacer()
                    Text("QR Code de convite")
                        .font(.inter(17, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Spacer()
                    Spacer().frame(width: 44)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // Cartão com Avatar + QR Code real de convite + Logo oficial no centro
                        VStack(spacing: 16) {
                            GeometricAvatarView(
                                seed: store.user.username,
                                displayName: store.user.fullName,
                                avatarData: store.user.avatarData,
                                size: 64
                            )

                            VStack(spacing: 3) {
                                Text(store.user.fullName)
                                    .font(.inter(18, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                                Text("@\(store.user.username)")
                                    .font(.inter(13, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                            }

                            if let qrImg = generateQRCodeImage(from: inviteLink) {
                                ZStack {
                                    Image(uiImage: qrImg)
                                        .interpolation(.none)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 210, height: 210)
                                        .padding(14)
                                        .background(Color.white)
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(JuntoColors.border, lineWidth: 1))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))

                                    JuntoLogoMark(size: 40)
                                        .padding(4)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                                }
                            }

                            Text("Mostre este QR Code para um amigo ler com a câmera e te adicionar automaticamente no Juntô.")
                                .font(.inter(13, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(22)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Ações: Compartilhar + Copiar link
                        VStack(spacing: 10) {
                            ShareLink(
                                item: "Escaneie meu QR Code ou abra este link para me adicionar no Juntô (@\(store.user.username)): \(inviteLink)"
                            ) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .regular))
                                    Text("Compartilhar convite")
                                        .font(.inter(16, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(JuntoColors.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }

                            JuntoOutlineButton(
                                title: copied ? "Link de convite copiado!" : "Copiar link de convite",
                                icon: copied ? "checkmark" : "doc.on.doc",
                                color: JuntoColors.primary
                            ) {
                                UIPasteboard.general.string = inviteLink
                                copied = true
                                store.showToast("Link de convite copiado!", icon: "link")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            }
        }
    }
}

// MARK: - Tela "Convidar amigos" com Link Real Compartilhável
struct InviteFriendsScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss
    @State private var copiedLink = false

    private var inviteURLString: String {
        "https://junto.app/convite/\(store.user.username)"
    }

    private var inviteShareMessage: String {
        "Bora dividir os rolês e viagens sem dor de cabeça no Juntô! Me adiciona por esse link: \(inviteURLString)"
    }

    var body: some View {
        ZStack {
            JuntoColors.warmBg.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    CircleNavButton(icon: "chevron.left") { dismiss() }
                    Spacer()
                    Text("Convidar amigos")
                        .font(.inter(17, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Spacer()
                    Spacer().frame(width: 44)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 18)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Card de convite
                        VStack(spacing: 14) {
                            JuntoLogoMark(size: 56)
                                .padding(.top, 4)

                            Text("Chame a galera pro Juntô")
                                .font(.inter(20, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                                .multilineTextAlignment(.center)

                            Text("Envie seu link exclusivo para amigos entrarem direto nos seus grupos, racharem despesas e acertarem tudo via Pix.")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Caixa com link real gerado
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SEU LINK DE CONVITE")
                                .font(.inter(11, weight: .medium))
                                .tracking(0.8)
                                .foregroundColor(JuntoColors.textMuted)

                            HStack(spacing: 10) {
                                Image(systemName: "link")
                                    .font(.system(size: 15))
                                    .foregroundColor(JuntoColors.primary)
                                Text(inviteURLString)
                                    .font(.inter(14, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                            }
                            .padding(14)
                            .background(JuntoColors.surfaceSubtle)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(JuntoColors.border, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(16)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Botões reais: ShareLink nativo iOS + Copiar link
                        VStack(spacing: 10) {
                            ShareLink(item: inviteShareMessage) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .regular))
                                    Text("Compartilhar link de convite")
                                        .font(.inter(16, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(JuntoColors.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }

                            JuntoOutlineButton(
                                title: copiedLink ? "Link copiado!" : "Copiar link",
                                icon: copiedLink ? "checkmark" : "doc.on.doc",
                                color: JuntoColors.primary
                            ) {
                                UIPasteboard.general.string = inviteURLString
                                copiedLink = true
                                store.showToast("Link de convite copiado!", icon: "link")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedLink = false }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            }
        }
    }
}

// MARK: - Política de Privacidade Completa (Textos Jurídicos LGPD & Marco Civil + Práticas Reais do Juntô)
struct PrivacyPolicyScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            JuntoColors.warmBg.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    CircleNavButton(icon: "chevron.left") { dismiss() }
                    Spacer()
                    Text("Política de Privacidade")
                        .font(.inter(17, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Spacer()
                    Spacer().frame(width: 44)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 14)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Cabeçalho jurídico
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Política de Privacidade e Proteção de Dados Pessoais")
                                .font(.inter(20, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                            Text("Aplicativo Juntô • Versão 1.0 • Atualizada em 22 de novembro de 2026")
                                .font(.inter(12, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                            Text("Elaborada em conformidade com a Lei Federal nº 13.709/2018 (Lei Geral de Proteção de Dados Pessoais – LGPD), a Lei nº 12.965/2014 (Marco Civil da Internet) e o Decreto nº 8.771/2016.")
                                .font(.inter(12, weight: .regular))
                                .foregroundColor(JuntoColors.primary)
                                .padding(.top, 4)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        policySection(
                            number: "1. Controlador e Escopo de Aplicação",
                            body: """
Esta Política de Privacidade descreve, de maneira clara, transparente e acessível (art. 6º, VI, e art. 9º da Lei nº 13.709/2018 – LGPD), como o aplicativo Juntô (“Plataforma” ou “Controlador”) coleta, utiliza, armazena, protege e elimina dados pessoais dos seus usuários (“Titulares”).

Ao criar uma conta ou utilizar quaisquer funcionalidades do Juntô — incluindo divisão de despesas em grupos, gestão de cotas de potes coletivos, chats individuais e registros financeiros pessoais — o Titular declara ciência integral das práticas descritas neste instrumento.
"""
                        )

                        policySection(
                            number: "2. Dados Pessoais Coletados e Finalidades Específicas",
                            body: """
Em observância ao princípio da necessidade e minimização de dados (art. 6º, III, da LGPD), coletamos exclusivamente os dados indispensáveis ao funcionamento da Plataforma:

• Dados de Identificação e Cadastro: nome completo, endereço de e-mail, nome de usuário exclusivo (@usuário) e número de telefone brasileiro (+55). Finalidade: criação da conta, autenticação, descoberta exclusiva por @usuário e comunicação de segurança.
• Chave Pix Informada pelo Titular: CPF, celular, e-mail ou chave aleatória cadastrada voluntariamente pelo usuário. Finalidade: geração de QR Code estático e exibição para que outros participantes de grupos realizem transferências Pix diretamente ao organizador, fora da Plataforma.
• Dados de Uso e Grupos: nomes e categorias de grupos, valores de despesas, divisão de cotas, marcações manuais de pagamento (“Pago” / “Confirmar pago”), mensagens de texto, áudios, fotos e documentos anexados voluntariamente nas conversas.
• Registros Técnicos e Sessões de Dispositivos: modelo do aparelho, versão do sistema operacional, endereço IP, data e hora de acesso (art. 15 da Lei nº 12.965/2014 – Marco Civil da Internet). Finalidade: exibição da tela “Dispositivos conectados”, prevenção a fraudes e cumprimento de obrigação legal de guarda de logs de acesso por 6 (seis) meses.

O Juntô NÃO coleta dados pessoais sensíveis previstos no art. 5º, II, da LGPD (como origem racial, convicção religiosa, dados biométricos ou de saúde) e NÃO acessa sua lista de contatos telefônicos sem autorização expressa.
"""
                        )

                        policySection(
                            number: "3. Natureza P2P e Ausência de Intermediação Financeira",
                            body: """
O Juntô atua estritamente como ferramenta tecnológica de organização, cálculo, rateio e comunicação entre amigos e participantes de grupos.

• O aplicativo NÃO realiza custódia de valores, NÃO mantém saldo bancário de terceiros, NÃO executa débitos automáticos em contas bancárias e NÃO atua como Instituição de Pagamento (Lei nº 12.865/2013).
• Toda transferência financeira via Pix é realizada diretamente entre o pagador e o organizador do grupo, por meio do aplicativo bancário de escolha de cada usuário. O Juntô apenas facilita a exibição da chave Pix / QR Code do organizador e registra a marcação manual de pagamento e sua conferência pelo responsável do grupo.
"""
                        )

                        policySection(
                            number: "4. Bases Legais para o Tratamento (Art. 7º da LGPD)",
                            body: """
Todo tratamento de dados pessoais realizado pelo Juntô fundamenta-se nas hipóteses legais do art. 7º da Lei nº 13.709/2018:

• Execução de contrato ou procedimentos preliminares (art. 7º, V): operacionalização do cadastro, grupos, cálculos de rateio e mensagens em tempo real.
• Consentimento livre, informado e inequívoco do Titular (art. 7º, I): uso de câmera/galeria para foto de perfil ou capa de grupo, gravação de mensagens de áudio via microfone e compartilhamento de documentos.
• Cumprimento de obrigação legal ou regulatória (art. 7º, II): guarda de registros de acesso conforme o art. 15 do Marco Civil da Internet e atendimento a requisições judiciais.
• Exercício regular de direitos e prevenção a fraudes (art. 7º, VI e IX): proteção da integridade das sessões, bloqueio de usuários abusivos e auditoria de segurança.
"""
                        )

                        policySection(
                            number: "5. Medidas Técnicas e Administrativas de Segurança (Art. 46 da LGPD)",
                            body: """
Adotamos medidas técnicas e organizacionais compatíveis com as melhores práticas de segurança da informação para proteger os dados contra acessos não autorizados, perda, alteração ou vazamento:

• Criptografia em Trânsito: todas as comunicações entre o aplicativo iOS, APIs REST e conexões em tempo real (Socket.IO) trafegam sobre TLS 1.3 com certificados válidos.
• Criptografia em Repouso (AES-256-GCM): dados pessoais críticos armazenados em nosso banco de dados PostgreSQL — incluindo chave Pix, telefone e registros de auditoria/retenção — são cifrados com algoritmo autenticado AES-256-GCM e chaves gerenciadas exclusivamente no ambiente seguro do servidor.
• Proteção de Credenciais e Sessões: senhas são armazenadas exclusivamente por meio de hash criptográfico irreversível com sal aleatório; sessões utilizam tokens JWT assinados com expiração controlada e revogação individual por aparelho na tela “Dispositivos conectados”.
• Comunicação de Incidentes: na hipótese de incidente de segurança que possa acarretar risco ou dano relevante aos Titulares, o Juntô comunicará a Autoridade Nacional de Proteção de Dados (ANPD) e os usuários afetados nos prazos e termos do art. 48 da LGPD e da Resolução CD/ANPD nº 15/2024.
"""
                        )

                        policySection(
                            number: "6. Retenção de 90 Dias Pós-Exclusão e Anonimização Definitiva (Arts. 15 e 16 da LGPD)",
                            body: """
O Titular pode solicitar a exclusão da sua conta a qualquer momento em Conta → Segurança e privacidade → Excluir conta.

• Encerramento Imediato: ao confirmar a exclusão, o acesso à conta e todas as sessões ativas em todos os dispositivos são revogados imediatamente, e o @usuário fica bloqueado contra reutilização imediata.
• Período de Retenção Segura (90 dias): com respaldo no art. 16, I e IV, da LGPD, os registros essenciais de auditoria são mantidos de forma isolada e cifrada por 90 (noventa) dias corridos, exclusivamente para cumprimento de obrigações legais, prevenção a fraudes e resguardo de direitos em eventual disputa entre participantes de grupos.
• Anonimização Irreversível Automatizada: decorrido o prazo de 90 dias, nossa rotina automatizada de expurgo realiza a eliminação definitiva e anonimização irreversível dos identificadores pessoais (art. 5º, XI, e art. 12 da LGPD), impossibilitando a reidentificação do Titular.
"""
                        )

                        policySection(
                            number: "7. Direitos do Titular de Dados (Art. 18 da LGPD)",
                            body: """
Nos termos do art. 18 da Lei nº 13.709/2018, você tem direito a obter do Juntô, a qualquer momento e mediante requisição gratuita:

I. Confirmação da existência de tratamento de seus dados pessoais;
II. Acesso aos dados mantidos sobre você;
III. Correção de dados incompletos, inexatos ou desatualizados (disponível diretamente em “Editar perfil”);
IV. Anonimização, bloqueio ou eliminação de dados desnecessários, excessivos ou tratados em desconformidade com a LGPD;
V. Portabilidade dos dados a outro fornecedor de serviço, mediante requisição expressa;
VI. Eliminação dos dados pessoais tratados com base no consentimento;
VII. Informação sobre a possibilidade de não fornecer consentimento e as consequências da negativa;
VIII. Revogação do consentimento, nos termos do art. 8º, § 5º, da LGPD.
"""
                        )

                        policySection(
                            number: "8. Encarregado pelo Tratamento de Dados Pessoais (DPO) e Contato",
                            body: """
Para exercer qualquer direito previsto no art. 18 da LGPD, esclarecer dúvidas sobre esta Política ou reportar questões de privacidade e segurança, entre em contato diretamente com o nosso Encarregado pelo Tratamento de Dados Pessoais (art. 41 da LGPD):

• Canal Oficial de Privacidade (DPO): privacidade@junto.app
• Prazo de resposta: até 15 (quinze) dias corridos, conforme diretrizes da LGPD e da ANPD.

Fica eleito o foro da legislação brasileira, com aplicação integral das normas da República Federativa do Brasil, para dirimir quaisquer controvérsias oriundas deste documento.
"""
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func policySection(number: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(number)
                .font(.inter(15, weight: .medium))
                .foregroundColor(JuntoColors.primary)

            Text(body)
                .font(.inter(13, weight: .regular))
                .foregroundColor(JuntoColors.textMain)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
