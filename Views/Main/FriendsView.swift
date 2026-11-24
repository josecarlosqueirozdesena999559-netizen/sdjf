import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var store: JuntoStore
    @Binding var isButtonsCollapsed: Bool
    var onOpenNotifications: () -> Void

    @State private var showAddFriendScreen = false
    @State private var selectedChatFriend: FriendItem? = nil
    @State private var selectedGroupChatId: UUID? = nil
    @State private var searchText = ""

    /// Todas as conversas unificadas estilo WhatsApp: quem mandar recente fica no topo (grupos ou amigos)
    private var recentChats: [UnifiedChatItem] {
        let list = store.unifiedChatsSortedByRecent
        if searchText.isEmpty { return list }
        return list.filter {
            $0.searchKeywords.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cabeçalho estilo WhatsApp: Título | Sino + Botão "+"
            HStack(spacing: 10) {
                Text("Amigos")
                    .font(.inter(24, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)

                Spacer()

                Button(action: onOpenNotifications) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)
                            .frame(width: 40, height: 40)
                            .background(JuntoColors.surfaceSubtle)
                            .clipShape(Circle())

                        if store.unreadNotificationsCount > 0 {
                            Text("\(min(store.unreadNotificationsCount, 99))")
                                .font(.inter(10, weight: .medium))
                                .foregroundColor(.white)
                                .frame(minWidth: 18, minHeight: 18)
                                .padding(.horizontal, 4)
                                .background(JuntoColors.danger)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.white, lineWidth: 1.5))
                                .offset(x: 3, y: -3)
                        }
                    }
                }

                Button {
                    showAddFriendScreen = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(JuntoColors.primary)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 12)

            // Barra de pesquisa limpa
            AnimatedSearchBar(
                text: $searchText,
                placeholders: ["Pesquisar conversas"]
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            // Saudação limpa + resumo do saldo
            VStack(alignment: .leading, spacing: 3) {
                Text("Olá, \(store.user.firstName)")
                    .font(.inter(16, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)

                if !recentChats.isEmpty {
                    HStack(spacing: 4) {
                        Text(store.netBalance >= 0 ? "No total, você recebe" : "No total, você deve")
                            .font(.inter(13, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                        Text(JuntoStore.formatBRL(abs(store.netBalance)))
                            .font(.inter(13, weight: .medium))
                            .foregroundColor(store.netBalance >= 0 ? JuntoColors.pixGreen : JuntoColors.orangeSave)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            Divider().opacity(0.6)

            if recentChats.isEmpty {
                Spacer()
                VStack(spacing: 14) {
                    if searchText.isEmpty {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 34, weight: .thin))
                            .foregroundColor(JuntoColors.textLight)

                        Text("Nenhuma conversa por aqui")
                            .font(.inter(16, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)

                        HStack(spacing: 6) {
                            Text("Inicie uma conversa clicando no botão")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(JuntoColors.primary)
                                .clipShape(Circle())
                            Text("acima")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                    } else {
                        Text("Nenhuma conversa encontrada.")
                            .font(.inter(15, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                    }
                }
                .frame(maxWidth: .infinity)
                Spacer()
                Spacer().frame(height: 110)
            } else {
                // Lista estilo WhatsApp Real: conversas unificadas onde quem mandar recente fica sempre no topo!
                List {
                    ForEach(recentChats) { item in
                        switch item {
                        case .friend(let friend, _):
                            friendRow(friend)
                        case .group(let group, _):
                            groupRow(group)
                        }
                    }

                    // Espaço para a barra flutuante inferior
                    Color.clear
                        .frame(height: 120)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            let dy = value.translation.height
                            let dx = value.translation.width
                            guard abs(dy) > abs(dx) else { return }
                            if dy < -14 && !isButtonsCollapsed {
                                withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                                    isButtonsCollapsed = true
                                }
                            } else if dy > 14 && isButtonsCollapsed {
                                withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                                    isButtonsCollapsed = false
                                }
                            }
                        }
                )
            }
        }
        .background(Color.white)
        .fullScreenCover(isPresented: $showAddFriendScreen) {
            AddFriendScreen { friendToChat in
                selectedChatFriend = friendToChat
            }
            .environmentObject(store)
        }
        .fullScreenCover(item: $selectedChatFriend) { friend in
            FriendChatScreen(friend: friend)
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: Binding(
            get: { selectedGroupChatId != nil },
            set: { if !$0 { selectedGroupChatId = nil } }
        )) {
            if let gid = selectedGroupChatId {
                GroupChatScreen(groupId: gid)
                    .environmentObject(store)
            }
        }
    }

    // MARK: - Linha de Conversa com Amigo (Estilo WhatsApp)
    private func friendRow(_ friend: FriendItem) -> some View {
        Button {
            selectedChatFriend = friend
        } label: {
            HStack(spacing: 14) {
                // Bolinha verde online SOMENTE aqui na tela inicial quando online
                ZStack(alignment: .bottomTrailing) {
                    GeometricAvatarView(seed: friend.username, displayName: friend.name, size: 50)
                    if friend.isOnline {
                        Circle()
                            .fill(JuntoColors.pixGreen)
                            .frame(width: 13, height: 13)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text(friend.name)
                            .font(.inter(15, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                            .lineLimit(1)
                        VerifiedBadgeView(type: friend.proPlanType, size: 13)
                    }

                    Text(store.lastMessagePreview(for: friend.username))
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                        .lineLimit(1)
                }

                Spacer()

                if friend.balance > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("te deve")
                            .font(.inter(11, weight: .regular))
                            .foregroundColor(JuntoColors.pixGreen)
                        Text(JuntoStore.formatBRL(friend.balance))
                            .font(.inter(15, weight: .medium))
                            .foregroundColor(JuntoColors.pixGreen)
                    }
                } else if friend.balance < 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("você deve")
                            .font(.inter(11, weight: .regular))
                            .foregroundColor(JuntoColors.orangeSave)
                        Text(JuntoStore.formatBRL(abs(friend.balance)))
                            .font(.inter(15, weight: .medium))
                            .foregroundColor(JuntoColors.orangeSave)
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
        .listRowBackground(Color.white)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                // Se tiver dívida, o amigo continua na lista porém sem mensagens
                store.clearConversation(for: friend.username)
            } label: {
                Label("Apagar conversa", systemImage: "trash")
            }
        }
    }

    // MARK: - Linha de Conversa de Grupo (Estilo WhatsApp)
    private func groupRow(_ group: RoleGroup) -> some View {
        Button {
            selectedGroupChatId = group.id
        } label: {
            HStack(spacing: 14) {
                Group {
                    if let data = group.coverImageData, let uiImg = UIImage(data: data) {
                        Image(uiImage: uiImg).resizable().scaledToFill()
                    } else {
                        Image(group.coverImageName).resizable().scaledToFill()
                    }
                }
                .frame(width: 50, height: 50)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text(group.title)
                            .font(.inter(15, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                            .lineLimit(1)
                        Text("· \(group.participants.count)")
                            .font(.inter(12, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                    }

                    Text(store.lastGroupMessagePreview(for: group.id))
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "person.2")
                    .font(.system(size: 13))
                    .foregroundColor(JuntoColors.textLight)
            }
            .padding(.vertical, 6)
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
        .listRowBackground(Color.white)
    }
}

// MARK: - Tela do botão "+": Contatos estilo WhatsApp (Agenda + Novo Contato + Mandar Mensagem direto)
struct AddFriendScreen: View {
    @EnvironmentObject var store: JuntoStore
    @StateObject private var contactsManager = ContactsManager.shared
    @Environment(\.dismiss) private var dismiss
    var onOpenChat: ((FriendItem) -> Void)? = nil

    @State private var query: String = ""
    @State private var showNewContactPopup: Bool = false
    @State private var isOpeningContact: Bool = false
    @State private var selectedFriendForOptions: FriendItem? = nil

    private var cleanQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredSavedContacts: [FriendItem] {
        let base = store.friends
        guard !cleanQuery.isEmpty else { return base }
        let qDigits = ContactsManager.normalizeBrDigits(cleanQuery)
        return base.filter { f in
            f.name.localizedCaseInsensitiveContains(cleanQuery) ||
            f.phone.localizedCaseInsensitiveContains(cleanQuery) ||
            (!qDigits.isEmpty && ContactsManager.normalizeBrDigits(f.phone).contains(qDigits))
        }
    }

    private var filteredDeviceContacts: [PhoneContactItem] {
        let savedPhones = Set(store.friends.map { ContactsManager.normalizeBrDigits($0.phone) }.filter { !$0.isEmpty })
        let nonDuplicates = contactsManager.phoneContacts.filter { !savedPhones.contains($0.normalizedDigits) }
        guard !cleanQuery.isEmpty else { return nonDuplicates }
        let qDigits = ContactsManager.normalizeBrDigits(cleanQuery)
        return nonDuplicates.filter { c in
            c.name.localizedCaseInsensitiveContains(cleanQuery) ||
            c.phone.localizedCaseInsensitiveContains(cleanQuery) ||
            (!qDigits.isEmpty && c.normalizedDigits.contains(qDigits))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                PopupCloseButton { dismiss() }
                Spacer()
                VStack(spacing: 1) {
                    Text("Contatos")
                        .font(.inter(17, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)
                    let totalCount = filteredSavedContacts.count + filteredDeviceContacts.count
                    Text("\(totalCount) contato(s)")
                        .font(.inter(11, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }
                Spacer()
                Color.clear.frame(width: 34, height: 34)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 14)

            // Barra de busca limpa (nome ou telefone)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)

                TextField("Pesquisar nome ou telefone...", text: $query)
                    .font(.inter(14, weight: .regular))
                    .foregroundColor(JuntoColors.textMain)
                    .autocorrectionDisabled()

                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(JuntoColors.textLight)
                    }
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(JuntoColors.surfaceSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.horizontal, 18)
            .padding(.bottom, 12)

            Divider().opacity(0.6)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Opção estilo WhatsApp: "Novo contato" (abre popup com Nome + Telefone)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showNewContactPopup = true
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(JuntoColors.primary)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Novo contato")
                                    .font(.inter(15, weight: .semibold))
                                    .foregroundColor(JuntoColors.textMain)
                                Text("Salvar nome e telefone para conversar")
                                    .font(.inter(12, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(JuntoColors.textLight)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 13)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 78)

                    // Contatos já no Juntô
                    if !filteredSavedContacts.isEmpty {
                        Text("Contatos no Juntô")
                            .font(.inter(12, weight: .semibold))
                            .foregroundColor(JuntoColors.textMuted)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 6)

                        ForEach(filteredSavedContacts) { contact in
                            HStack(spacing: 12) {
                                Button {
                                    openChatAndDismiss(contact)
                                } label: {
                                    HStack(spacing: 12) {
                                        GeometricAvatarView(seed: contact.username, displayName: contact.name, size: 44)

                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 5) {
                                                Text(contact.name)
                                                    .font(.inter(15, weight: .medium))
                                                    .foregroundColor(JuntoColors.textMain)
                                                    .lineLimit(1)
                                                VerifiedBadgeView(type: contact.proPlanType, size: 13)
                                            }
                                            Text(contact.phone.isEmpty ? "Disponível para mensagem" : contact.phone)
                                                .font(.inter(12, weight: .regular))
                                                .foregroundColor(JuntoColors.textMuted)
                                                .lineLimit(1)
                                        }

                                        Spacer(minLength: 8)

                                        Text("Mensagem")
                                            .font(.inter(12, weight: .semibold))
                                            .foregroundColor(JuntoColors.primary)
                                            .padding(.horizontal, 12)
                                            .frame(height: 30)
                                            .background(JuntoColors.primary.opacity(0.10))
                                            .clipShape(Capsule())
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                Button {
                                    selectedFriendForOptions = contact
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(JuntoColors.textMuted)
                                        .frame(width: 28, height: 28)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)

                            Divider().padding(.leading, 76)
                        }
                    }

                    // Contatos da Agenda do iPhone (CNContactStore)
                    if contactsManager.authorizationStatus == .notDetermined {
                        Button {
                            contactsManager.requestAndLoadContacts()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.rectangle.stack")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(JuntoColors.primary)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Sincronizar agenda do iPhone")
                                        .font(.inter(14, weight: .medium))
                                        .foregroundColor(JuntoColors.textMain)
                                    Text("Ver seus contatos aqui como no WhatsApp")
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(JuntoColors.textLight)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(.plain)
                    } else if !filteredDeviceContacts.isEmpty {
                        Text("Contatos do telefone")
                            .font(.inter(12, weight: .semibold))
                            .foregroundColor(JuntoColors.textMuted)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 6)

                        ForEach(filteredDeviceContacts) { phoneContact in
                            Button {
                                guard !isOpeningContact else { return }
                                isOpeningContact = true
                                Task {
                                    let opened = await store.addContactAndOpenChat(name: phoneContact.name, phone: phoneContact.phone)
                                    isOpeningContact = false
                                    if let f = opened {
                                        openChatAndDismiss(f)
                                    }
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    GeometricAvatarView(seed: phoneContact.normalizedDigits, displayName: phoneContact.name, size: 44)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(phoneContact.name)
                                            .font(.inter(15, weight: .medium))
                                            .foregroundColor(JuntoColors.textMain)
                                            .lineLimit(1)
                                        Text(phoneContact.phone)
                                            .font(.inter(12, weight: .regular))
                                            .foregroundColor(JuntoColors.textMuted)
                                            .lineLimit(1)
                                    }

                                    Spacer(minLength: 8)

                                    Text("Mensagem")
                                        .font(.inter(12, weight: .semibold))
                                        .foregroundColor(JuntoColors.primary)
                                        .padding(.horizontal, 12)
                                        .frame(height: 30)
                                        .background(JuntoColors.primary.opacity(0.10))
                                        .clipShape(Capsule())
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Divider().padding(.leading, 76)
                        }
                    } else if filteredSavedContacts.isEmpty && !cleanQuery.isEmpty {
                        VStack(spacing: 10) {
                            Text("Nenhum contato encontrado.")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                            Button("Adicionar novo contato") {
                                showNewContactPopup = true
                            }
                            .font(.inter(13, weight: .semibold))
                            .foregroundColor(JuntoColors.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            contactsManager.requestAndLoadContacts()
        }
        .sheet(isPresented: $showNewContactPopup) {
            NewContactPopupSheet { name, phone in
                Task {
                    if let created = await store.addContactAndOpenChat(name: name, phone: phone) {
                        showNewContactPopup = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            openChatAndDismiss(created)
                        }
                    }
                }
            }
            .presentationDetents([.height(330), .medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .sheet(item: $selectedFriendForOptions) { friend in
            FriendOptionsSheet(
                friend: friend,
                onUnfriend: {
                    store.unfriend(username: friend.username)
                    selectedFriendForOptions = nil
                },
                onBlock: {
                    store.blockAndUnfriend(username: friend.username)
                    selectedFriendForOptions = nil
                }
            )
            .presentationDetents([.height(270)])
            .presentationCornerRadius(20)
        }
    }

    private func openChatAndDismiss(_ friend: FriendItem) {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            onOpenChat?(friend)
        }
    }
}

// MARK: - Popup "Novo contato" (Nome + Telefone, estilo WhatsApp, fechar apenas X)
private struct NewContactPopupSheet: View {
    var onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var nameText: String = ""
    @State private var phoneText: String = ""
    @State private var isSaving: Bool = false

    private var canSave: Bool {
        nameText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 &&
        ContactsManager.normalizeBrDigits(phoneText).count >= 10
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Novo contato")
                    .font(.inter(18, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                PopupCloseButton { dismiss() }
            }
            .padding(.top, 20)

            CleanOutlineInput(
                label: "Nome",
                placeholder: "Ex: João Silva",
                text: $nameText
            )

            CleanOutlineInput(
                label: "Telefone (WhatsApp)",
                placeholder: "(11) 99999-9999",
                text: $phoneText,
                keyboardType: .phonePad,
                leadingPrefix: "+55"
            )
            .onChange(of: phoneText) { _, newValue in
                let formatted = formatLivePhoneInput(newValue)
                if formatted != phoneText {
                    phoneText = formatted
                }
            }

            Button {
                guard canSave, !isSaving else { return }
                isSaving = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onSave(nameText, phoneText)
            } label: {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 13))
                        Text("Salvar e mandar mensagem")
                            .font(.inter(15, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(canSave ? JuntoColors.primary : JuntoColors.border)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!canSave || isSaving)
            .buttonStyle(JuntoTapBounceStyle(scaleAmount: 0.97))

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color.white.ignoresSafeArea())
    }

    private func formatLivePhoneInput(_ raw: String) -> String {
        let digits = String(raw.filter { $0.isNumber }.prefix(11))
        if digits.count <= 2 { return digits }
        if digits.count <= 7 {
            return "(\(digits.prefix(2))) \(digits.dropFirst(2))"
        }
        let ddd = digits.prefix(2)
        let mid = digits.dropFirst(2).prefix(digits.count == 11 ? 5 : 4)
        let end = digits.dropFirst(digits.count == 11 ? 7 : 6)
        return "(\(ddd)) \(mid)-\(end)"
    }
}

// MARK: - Sheet Claro Customizado (3 Pontos do Amigo: Desfazer Amizade / Bloquear)
struct FriendOptionsSheet: View {
    let friend: FriendItem
    let onUnfriend: () -> Void
    let onBlock: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                GeometricAvatarView(seed: friend.username, size: 46)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(friend.name)
                            .font(.inter(16, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                        VerifiedBadgeView(type: friend.proPlanType, size: 14)
                    }
                    Text("@\(friend.username)")
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }
                Spacer()
                PopupCloseButton { dismiss() }
            }
            .padding(.top, 20)

            VStack(spacing: 10) {
                Button(action: onUnfriend) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.minus")
                            .font(.system(size: 17))
                            .foregroundColor(JuntoColors.textMain)
                        Text("Desfazer amizade")
                            .font(.inter(15, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(JuntoColors.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button(action: onBlock) {
                    HStack(spacing: 12) {
                        Image(systemName: "nosign")
                            .font(.system(size: 17))
                            .foregroundColor(JuntoColors.danger)
                        Text("Bloquear usuário")
                            .font(.inter(15, weight: .medium))
                            .foregroundColor(JuntoColors.danger)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(JuntoColors.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(JuntoColors.warmBg.ignoresSafeArea())
    }
}
