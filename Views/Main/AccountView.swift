import SwiftUI
import PhotosUI

struct AccountView: View {
    @EnvironmentObject var store: JuntoStore

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var editFieldType: AccountEditField? = nil
    @State private var showBlockedSheet = false
    @State private var showDisconnectAlert = false
    @State private var showDeleteAlert = false

    enum AccountEditField: Identifiable {
        case name, email, phone, pixKey
        var id: Int { hashValue }
        var title: String {
            switch self {
            case .name: return "Editar Nome"
            case .email: return "Editar E-mail"
            case .phone: return "Editar Telefone"
            case .pixKey: return "Editar Chave Pix"
            }
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Card de Perfil com Avatar Flat + Editar Foto
                VStack(spacing: 10) {
                    ZStack(alignment: .bottomTrailing) {
                        if let data = store.user.avatarData, let uiImg = UIImage(data: data) {
                            Image(uiImage: uiImg)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 86, height: 86)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                        } else {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(
                                    LinearGradient(
                                        colors: [JuntoColors.primary, Color(hex: "#7C3AED")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 86, height: 86)
                                .overlay(
                                    Text(store.user.avatarEmoji ?? store.user.initials)
                                        .font(.inter(30, weight: .heavy))
                                        .foregroundColor(.white)
                                )
                        }

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(JuntoColors.primary)
                                .frame(width: 32, height: 32)
                                .background(Color.white)
                                .overlay(Circle().stroke(JuntoColors.border, lineWidth: 1))
                                .clipShape(Circle())
                        }
                        .offset(x: 4, y: 4)
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                store.user.avatarData = data
                                store.showToast("Foto do perfil atualizada!", icon: "camera.fill")
                            }
                        }
                    }

                    VStack(spacing: 2) {
                        Text(store.user.fullName)
                            .font(.inter(18, weight: .heavy))
                            .foregroundColor(JuntoColors.textMain)
                        Text("@\(store.user.username)")
                            .font(.inter(13, weight: .medium))
                            .foregroundColor(JuntoColors.textMuted)
                    }

                    // Destaque do Diferencial no Perfil
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Juntô Pro • Pix Automático + Pote + Comanda IA")
                    }
                    .font(.inter(11, weight: .bold))
                    .foregroundColor(JuntoColors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(JuntoColors.primaryLight)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(JuntoColors.surface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(JuntoColors.border, lineWidth: 1))
                .cornerRadius(16)

                // Grupo 1: Dados da Conta
                VStack(alignment: .leading, spacing: 0) {
                    sectionHeader("Dados Pessoais & Pix")

                    settingsRow(icon: "person.fill", title: "Nome", subtitle: store.user.fullName) {
                        editFieldType = .name
                    }
                    Divider().padding(.leading, 56)

                    settingsRow(icon: "envelope.fill", title: "E-mail", subtitle: store.user.email) {
                        editFieldType = .email
                    }
                    Divider().padding(.leading, 56)

                    settingsRow(icon: "phone.fill", title: "Telefone", subtitle: "\(store.user.country.flag) \(store.user.country.dialCode) \(store.user.phone)") {
                        editFieldType = .phone
                    }
                    Divider().padding(.leading, 56)

                    settingsRow(icon: "bolt.fill", iconColor: JuntoColors.secondary, iconBg: JuntoColors.secondaryLight, title: "Chave Pix", subtitle: store.user.pixKey) {
                        editFieldType = .pixKey
                    }
                }
                .background(JuntoColors.surface)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                .cornerRadius(14)

                // Grupo 2: Privacidade, Dispositivos & Exclusão de Conta (Apple Compliant)
                VStack(alignment: .leading, spacing: 0) {
                    sectionHeader("Segurança & Privacidade")

                    settingsRow(icon: "hand.raised.fill", title: "Gerenciar lista de bloqueados", subtitle: "\(store.blockedUsernames.count) usuário(s) bloqueado(s)") {
                        showBlockedSheet = true
                    }
                    Divider().padding(.leading, 56)

                    settingsRow(icon: "iphone.and.arrow.forward", title: "Desconectar de todos os dispositivos", subtitle: "Encerra todas as sessões ativas") {
                        showDisconnectAlert = true
                    }
                    Divider().padding(.leading, 56)

                    settingsRow(
                        icon: "trash.fill",
                        iconColor: JuntoColors.danger,
                        iconBg: JuntoColors.dangerLight,
                        title: "Excluir conta",
                        subtitle: "Remove permanentemente todos os seus dados",
                        isDestructive: true
                    ) {
                        showDeleteAlert = true
                    }
                }
                .background(JuntoColors.surface)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                .cornerRadius(14)

                JuntoSecondaryButton(title: "Sair da Conta", color: JuntoColors.danger) {
                    store.logout()
                }
            }
            .padding(16)
        }
        .sheet(item: $editFieldType) { field in
            EditAccountFieldSheet(field: field)
                .environmentObject(store)
                .presentationDetents([.height(260)])
        }
        .sheet(isPresented: $showBlockedSheet) {
            BlockedUsersSheetView()
                .environmentObject(store)
                .presentationDetents([.medium])
        }
        .alert("Desconectar de todos os dispositivos?", isPresented: $showDisconnectAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Desconectar Todos", role: .destructive) {
                store.disconnectAllDevices()
            }
        } message: {
            Text("Todas as sessões abertas em outros celulares ou tablets serão encerradas imediatamente.")
        }
        .alert("Excluir conta permanentemente?", isPresented: $showDeleteAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Excluir Conta", role: .destructive) {
                store.deleteAccountPermanently()
            }
        } message: {
            Text("Esta ação não pode ser desfeita. Todos os seus dados, rolês e histórico serão removidos permanentemente.")
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.inter(11, weight: .bold))
            .foregroundColor(JuntoColors.textMuted)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 6)
    }

    private func settingsRow(
        icon: String,
        iconColor: Color = JuntoColors.primary,
        iconBg: Color = JuntoColors.primaryLight,
        title: String,
        subtitle: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(iconColor)
                    .frame(width: 34, height: 34)
                    .background(iconBg)
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.inter(13, weight: .bold))
                        .foregroundColor(isDestructive ? JuntoColors.danger : JuntoColors.textMain)
                    Text(subtitle)
                        .font(.inter(11))
                        .foregroundColor(isDestructive ? JuntoColors.danger.opacity(0.8) : JuntoColors.textMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(JuntoColors.textLight)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

struct EditAccountFieldSheet: View {
    @EnvironmentObject var store: JuntoStore
    let field: AccountView.AccountEditField
    @State private var value: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(field.title)
                .font(.inter(18, weight: .heavy))
                .foregroundColor(JuntoColors.textMain)
                .padding(.top, 20)

            FlatInputField(label: "", placeholder: "Digite o novo valor", text: $value)

            JuntoPrimaryButton(title: "Salvar Alteração", icon: "checkmark") {
                let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !clean.isEmpty else { return }
                switch field {
                case .name: store.user.fullName = clean
                case .email: store.user.email = clean
                case .phone: store.user.phone = clean
                case .pixKey: store.user.pixKey = clean
                }
                store.showToast("Alteração salva com sucesso!", icon: "checkmark.circle.fill")
                dismiss()
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .background(JuntoColors.surface)
        .onAppear {
            switch field {
            case .name: value = store.user.fullName
            case .email: value = store.user.email
            case .phone: value = store.user.phone
            case .pixKey: value = store.user.pixKey
            }
        }
    }
}

struct BlockedUsersSheetView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var newHandle: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Lista de Bloqueados")
                    .font(.inter(18, weight: .heavy))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Button("Fechar") { dismiss() }
                    .font(.inter(13, weight: .semibold))
                    .foregroundColor(JuntoColors.primary)
            }
            .padding(.top, 20)

            HStack(spacing: 8) {
                FlatInputField(label: "", placeholder: "usuario.bloqueado", text: $newHandle, autocapitalization: .never, leadingPrefix: "@")
                Button {
                    store.blockUser(newHandle)
                    newHandle = ""
                } label: {
                    Text("Bloquear")
                        .font(.inter(12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .background(JuntoColors.danger)
                        .cornerRadius(8)
                }
            }

            if store.blockedUsernames.isEmpty {
                Text("Nenhum usuário bloqueado no momento.")
                    .font(.inter(13))
                    .foregroundColor(JuntoColors.textMuted)
                    .padding(.top, 12)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(store.blockedUsernames, id: \.self) { handle in
                            HStack {
                                Text("@\(handle)")
                                    .font(.inter(13, weight: .bold))
                                    .foregroundColor(JuntoColors.textMain)
                                Spacer()
                                Button("Desbloquear") {
                                    store.unblockUser(handle)
                                }
                                .font(.inter(12, weight: .bold))
                                .foregroundColor(JuntoColors.primary)
                            }
                            .padding(12)
                            .background(JuntoColors.bgMain)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(JuntoColors.border, lineWidth: 1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .background(JuntoColors.surface)
    }
}
