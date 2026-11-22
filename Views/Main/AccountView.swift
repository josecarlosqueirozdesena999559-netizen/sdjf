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
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Conta")
                        .font(.inter(24, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 18)

                    // Perfil: Avatar circular geométrico + Câmera + Nome/Email + "Editar" esmeralda
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

                    // Card Juntô Pro (estilo índigo-lavanda autoral do Juntô)
                    VStack(spacing: 16) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 38, weight: .light))
                            .foregroundColor(JuntoColors.proIndigo)
                            .padding(.top, 8)

                        Text("Faça mais com o Juntô Pro.")
                            .font(.inter(16, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)

                        JuntoPillButton(title: "Obter Juntô Pro", color: JuntoColors.proIndigo) {
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

                    accountRow(icon: "diamond.fill", iconColor: JuntoColors.proIndigo, title: "Juntô Pro") {
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

// MARK: - Tela "Editar perfil" com a identidade própria do Juntô (sem Fuso Horário / Idioma — apenas Brasil)
struct AccountSettingsScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
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
        ZStack {
            JuntoColors.warmBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Topo limpo
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
                        // Cartão de foto / avatar
                        VStack(spacing: 12) {
                            ZStack(alignment: .bottomTrailing) {
                                GeometricAvatarView(
                                    seed: store.user.username,
                                    displayName: store.user.fullName,
                                    avatarData: store.user.avatarData,
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
                                        store.user.avatarData = data
                                        store.showToast("Foto atualizada.", icon: "camera")
                                    }
                                }
                            }

                            VStack(spacing: 2) {
                                Text(store.user.fullName)
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

                        // Cartão de Dados Pessoais
                        VStack(alignment: .leading, spacing: 0) {
                            sectionTitle("Dados da conta")

                            profileFieldRow(icon: "person", label: "Nome completo", value: store.user.fullName) {
                                editField = .name
                            }
                            Divider().padding(.leading, 54)

                            profileFieldRow(icon: "envelope", label: "E-mail", value: store.user.email) {
                                editField = .email
                            }
                            Divider().padding(.leading, 54)

                            profileFieldRow(icon: "phone", label: "Telefone (Brasil)", value: "+55 \(store.user.phone)") {
                                editField = .phone
                            }
                            Divider().padding(.leading, 54)

                            profileFieldRow(icon: "qrcode", label: "Chave Pix", value: store.user.pixKey) {
                                editField = .pixKey
                            }
                            Divider().padding(.leading, 54)

                            profileFieldRow(icon: "lock", label: "Senha", value: "••••••••") {
                                editField = .password
                            }
                        }
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Cartão de Privacidade
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $store.user.allowRecommendations) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Permitir ser encontrado por amigos")
                                        .font(.inter(14, weight: .medium))
                                        .foregroundColor(JuntoColors.textMain)
                                    Text("Outros usuários podem te encontrar pelo @usuário ou contato.")
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                }
                            }
                            .tint(JuntoColors.primary)
                        }
                        .padding(16)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Botão Salvar no estilo Juntô
                        JuntoPillButton(title: "Salvar alterações", color: JuntoColors.primary) {
                            store.showToast("Perfil atualizado.", icon: "checkmark.circle")
                            dismiss()
                        }

                        // Cartão de Segurança & LGPD
                        VStack(alignment: .leading, spacing: 0) {
                            sectionTitle("Segurança e privacidade")

                            securityRow(icon: "hand.raised", title: "Gerenciar lista de bloqueios", tint: JuntoColors.textMain) {
                                showBlockedSheet = true
                            }
                            Divider().padding(.leading, 54)

                            securityRow(icon: "iphone.and.arrow.forward", title: "Desconectar de todos os dispositivos", tint: JuntoColors.textMain) {
                                showDisconnectAlert = true
                            }
                            Divider().padding(.leading, 54)

                            securityRow(icon: "trash", title: "Excluir conta", tint: JuntoColors.danger) {
                                showDeleteAlert = true
                            }
                        }
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
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

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.inter(11, weight: .medium))
            .tracking(0.8)
            .foregroundColor(JuntoColors.textMuted)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 6)
    }

    private func profileFieldRow(icon: String, label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(JuntoColors.primary)
                    .frame(width: 30, height: 30)
                    .background(JuntoColors.primaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

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
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    private func securityRow(icon: String, title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(tint)
                    .frame(width: 30, height: 30)
                    .background(tint == JuntoColors.danger ? JuntoColors.dangerLight : JuntoColors.surfaceSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(title)
                    .font(.inter(14, weight: .regular))
                    .foregroundColor(tint)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(JuntoColors.textLight)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
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
