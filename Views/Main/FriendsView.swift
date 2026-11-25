import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var store: JuntoStore
    @Binding var isButtonsCollapsed: Bool
    var onOpenNotifications: () -> Void

    @State private var showAddFriendScreen = false
    @State private var selectedChatFriend: FriendItem? = nil
    @State private var selectedGroupChatId: UUID? = nil
    @State private var groupPendingLeave: RoleGroup? = nil
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
            // Cabeçalho estilo WhatsApp: Título em Bold | Sino + Botão "+"
            HStack(spacing: 10) {
                Text("Amigos")
                    .font(.inter(26, weight: .bold))
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

            // Saudação em Bold + resumo do saldo em destaque (fonte mais grossa)
            VStack(alignment: .leading, spacing: 4) {
                Text("Olá, \(store.user.firstName)")
                    .font(.inter(20, weight: .bold))
                    .foregroundColor(JuntoColors.textMain)

                if !recentChats.isEmpty {
                    HStack(spacing: 5) {
                        Text(store.netBalance >= 0 ? "No total, você recebe" : "No total, você deve")
                            .font(.inter(15, weight: .semibold))
                            .foregroundColor(JuntoColors.textMain)
                        Text(JuntoStore.formatBRL(abs(store.netBalance)))
                            .font(.inter(16, weight: .bold))
                            .foregroundColor(store.netBalance >= 0 ? JuntoColors.pixGreen : JuntoColors.orangeSave)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            Divider().opacity(0.6)

            if recentChats.isEmpty {
                Spacer()
                VStack(spacing: 14) {
                    if searchText.isEmpty {
                        ZStack {
                            Circle()
                                .fill(JuntoColors.primary.opacity(0.08))
                                .frame(width: 68, height: 68)
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 26, weight: .regular))
                                .foregroundColor(JuntoColors.primary)
                        }

                        Text("Nenhuma conversa por aqui")
                            .font(.inter(17, weight: .bold))
                            .foregroundColor(JuntoColors.textMain)

                        Text("Inicie uma conversa com seus contatos do Juntô ou crie um grupo para dividir gastos.")
                            .font(.inter(14, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 36)

                        Button {
                            showAddFriendScreen = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Iniciar conversa")
                                    .font(.inter(14, weight: .semibold))
                            }
                            .foregroundColor(JuntoColors.primary)
                            .padding(.horizontal, 22)
                            .frame(height: 44)
                            .background(Color.white)
                            .overlay(Capsule().stroke(JuntoColors.primary, lineWidth: 1.2))
                            .clipShape(Capsule())
                        }
                        .padding(.top, 4)
                    } else {
                        ZStack {
                            Circle()
                                .fill(JuntoColors.surfaceSubtle)
                                .frame(width: 60, height: 60)
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                        }
                        Text("Nenhuma conversa encontrada")
                            .font(.inter(15, weight: .semibold))
                            .foregroundColor(JuntoColors.textMain)
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
        .sheet(item: $groupPendingLeave) { target in
            let isOwner = store.isCurrentUserOwner(in: target)
            CleanConfirmDeleteSheet(
                title: isOwner ? "Excluir grupo" : "Sair do grupo",
                itemName: target.title,
                isOwner: isOwner,
                confirmButtonTitle: isOwner ? "Excluir grupo" : "Sair do grupo"
            ) {
                let targetId = target.id
                groupPendingLeave = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    if isOwner {
                        store.deleteGroup(groupId: targetId)
                    } else {
                        store.leaveGroup(groupId: targetId)
                    }
                }
            }
            .presentationDetents([.height(395)])
            .presentationCornerRadius(24)
            .presentationBackground(Color.white)
        }
    }

    // MARK: - Linha de Conversa com Amigo (Estilo WhatsApp + valor devido incluso dos grupos compartilhados)
    private func friendRow(_ friend: FriendItem) -> some View {
        let debtCtx = store.sharedDebtContext(with: friend)
        let netBalance = debtCtx.netBalance
        let unread = store.unreadCount(forFriend: friend.username)

        return Button {
            store.markFriendChatAsRead(username: friend.username)
            selectedChatFriend = friend
        } label: {
            HStack(spacing: 14) {
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
                            .font(.inter(15, weight: .semibold))
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

                HStack(spacing: 8) {
                    if netBalance > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("deve a você")
                                .font(.inter(11, weight: .regular))
                                .foregroundColor(JuntoColors.pixGreen)
                            Text(JuntoStore.formatBRL(netBalance))
                                .font(.inter(15, weight: .bold))
                                .foregroundColor(JuntoColors.pixGreen)
                        }
                    } else if netBalance < 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("você deve")
                                .font(.inter(11, weight: .regular))
                                .foregroundColor(JuntoColors.orangeSave)
                            Text(JuntoStore.formatBRL(abs(netBalance)))
                                .font(.inter(15, weight: .bold))
                                .foregroundColor(JuntoColors.orangeSave)
                        }
                    }

                    if unread > 0 {
                        Text("\(unread)")
                            .font(.inter(12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .frame(minWidth: 24, minHeight: 24)
                            .background(JuntoColors.primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
        .listRowBackground(Color.white)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.clearConversation(for: friend.username)
            } label: {
                Label("Apagar conversa", systemImage: "trash")
            }
        }
    }

    // MARK: - Linha de Conversa de Grupo (Mostra "você deve R$ ..." ao criar/participar + contador real)
    private func groupRow(_ group: RoleGroup) -> some View {
        let unread = store.unreadCount(forGroup: group.id)
        let myDebt = store.myPendingAmount(in: group)

        return Button {
            store.markGroupChatAsRead(groupId: group.id)
            selectedGroupChatId = group.id
        } label: {
            HStack(spacing: 14) {
                GroupCategoryIconTile(category: group.category, size: 50)

                VStack(alignment: .leading, spacing: 3) {
                    Text(group.title)
                        .font(.inter(15, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)
                        .lineLimit(1)

                    Text(store.lastGroupMessagePreview(for: group.id))
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 8) {
                    if myDebt > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("você deve")
                                .font(.inter(11, weight: .regular))
                                .foregroundColor(JuntoColors.orangeSave)
                            Text(JuntoStore.formatBRL(myDebt))
                                .font(.inter(15, weight: .bold))
                                .foregroundColor(JuntoColors.orangeSave)
                        }
                    }

                    if unread > 0 {
                        Text("\(unread)")
                            .font(.inter(12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .frame(minWidth: 24, minHeight: 24)
                            .background(JuntoColors.primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
        .listRowBackground(Color.white)
        .contextMenu {
            Button {
                store.clearGroupConversation(for: group.id)
            } label: {
                Label("Limpar conversa", systemImage: "trash")
            }

            Button(role: .destructive) {
                groupPendingLeave = group
            } label: {
                Label("Sair do grupo", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.clearGroupConversation(for: group.id)
            } label: {
                Label("Apagar conversa", systemImage: "trash")
            }
        }
    }
}

// MARK: - Tela do botão "+": Contatos Reais em Tempo Real (No Juntô -> Mensagem | Sem conta -> Apenas Convidar com link do app)
struct AddFriendScreen: View {
    @EnvironmentObject var store: JuntoStore
    @StateObject private var contactsManager = ContactsManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    var onOpenChat: ((FriendItem) -> Void)? = nil

    @State private var query: String = ""
    @State private var showNewContactPopup: Bool = false
    @State private var isOpeningContact: Bool = false
    @State private var selectedFriendForOptions: FriendItem? = nil

    private var cleanQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func matchesSearch(name: String, phone: String) -> Bool {
        guard !cleanQuery.isEmpty else { return true }
        let qDigits = ContactsManager.normalizeBrDigits(cleanQuery)
        return name.localizedCaseInsensitiveContains(cleanQuery) ||
            phone.localizedCaseInsensitiveContains(cleanQuery) ||
            (!qDigits.isEmpty && ContactsManager.normalizeBrDigits(phone).contains(qDigits))
    }

    /// Contatos já salvos no Juntô (contas reais no PostgreSQL)
    private var filteredRegisteredFriends: [FriendItem] {
        store.friends.filter { matchesSearch(name: $0.name, phone: $0.phone) }
    }

    /// Contatos reais da agenda do iPhone que TÊM conta real no Juntô (mas ainda não estão em store.friends)
    private var filteredRegisteredDeviceContacts: [PhoneContactItem] {
        let savedPhones = Set(store.friends.map { ContactsManager.normalizeBrDigits($0.phone) }.filter { !$0.isEmpty })
        return contactsManager.phoneContacts.filter { c in
            !savedPhones.contains(c.normalizedDigits) &&
            contactsManager.matchedAccount(for: c.normalizedDigits) != nil &&
            matchesSearch(name: c.name, phone: c.phone)
        }
    }

    /// Contatos reais da agenda do iPhone que NÃO têm conta no Juntô -> APENAS convite via link (não pode enviar mensagem!)
    private var filteredUnregisteredDeviceContacts: [PhoneContactItem] {
        let savedPhones = Set(store.friends.map { ContactsManager.normalizeBrDigits($0.phone) }.filter { !$0.isEmpty })
        return contactsManager.phoneContacts.filter { c in
            !savedPhones.contains(c.normalizedDigits) &&
            contactsManager.matchedAccount(for: c.normalizedDigits) == nil &&
            matchesSearch(name: c.name, phone: c.phone)
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
                    let totalCount = filteredRegisteredFriends.count + filteredRegisteredDeviceContacts.count + filteredUnregisteredDeviceContacts.count
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
                                Text("Adicionar nome e telefone")
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

                    // 1. Contatos REAIS que usam o Juntô -> podem mandar mensagem
                    if !filteredRegisteredFriends.isEmpty || !filteredRegisteredDeviceContacts.isEmpty {
                        Text("Contatos no Juntô")
                            .font(.inter(12, weight: .semibold))
                            .foregroundColor(JuntoColors.textMuted)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 6)

                        ForEach(filteredRegisteredFriends) { contact in
                            HStack(spacing: 12) {
                                Button {
                                    openChatAndDismiss(contact)
                                } label: {
                                    HStack(spacing: 12) {
                                        GeometricAvatarView(seed: contact.username, displayName: contact.name, size: 44)

                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 5) {
                                                Text(contact.name)
                                                    .font(.inter(15, weight: .semibold))
                                                    .foregroundColor(JuntoColors.textMain)
                                                    .lineLimit(1)
                                                VerifiedBadgeView(type: contact.proPlanType, size: 13)
                                            }
                                            Text(contact.phone.isEmpty ? "No Juntô" : contact.phone)
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

                        ForEach(filteredRegisteredDeviceContacts) { phoneContact in
                            Button {
                                guard !isOpeningContact else { return }
                                isOpeningContact = true
                                Task {
                                    let res = await store.addContactAndOpenChat(name: phoneContact.name, phone: phoneContact.phone)
                                    isOpeningContact = false
                                    if let f = res.friend {
                                        openChatAndDismiss(f)
                                    }
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    GeometricAvatarView(seed: phoneContact.normalizedDigits, displayName: phoneContact.name, size: 44)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(phoneContact.name)
                                            .font(.inter(15, weight: .semibold))
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
                    }

                    // 2. Permissão de agenda ou Contatos do celular que NÃO têm conta -> APENAS Convidar (compartilhar link)
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
                                    Text("Sincronizar contatos do celular")
                                        .font(.inter(14, weight: .semibold))
                                        .foregroundColor(JuntoColors.textMain)
                                    Text("Puxa sua agenda real em tempo real")
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
                    } else if !filteredUnregisteredDeviceContacts.isEmpty {
                        Text("Convidar para o Juntô")
                            .font(.inter(12, weight: .semibold))
                            .foregroundColor(JuntoColors.textMuted)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 6)

                        ForEach(filteredUnregisteredDeviceContacts) { phoneContact in
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

                                ShareLink(item: ContactsManager.inviteMessage(for: phoneContact.name)) {
                                    Text("Convidar")
                                        .font(.inter(12, weight: .semibold))
                                        .foregroundColor(JuntoColors.textMain)
                                        .padding(.horizontal, 12)
                                        .frame(height: 30)
                                        .background(JuntoColors.surfaceSubtle)
                                        .overlay(Capsule().stroke(JuntoColors.border, lineWidth: 0.9))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)

                            Divider().padding(.leading, 76)
                        }
                    } else if filteredRegisteredFriends.isEmpty && filteredRegisteredDeviceContacts.isEmpty && !cleanQuery.isEmpty {
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
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                contactsManager.loadContactsFromDevice()
            }
        }
        .sheet(isPresented: $showNewContactPopup) {
            NewContactPopupSheet(
                onOpenRegisteredChat: { friend in
                    showNewContactPopup = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        openChatAndDismiss(friend)
                    }
                }
            )
            .environmentObject(store)
            .presentationDetents([.height(360), .medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .sheet(item: $selectedFriendForOptions) { friend in
            FriendOptionsSheet(
                friend: friend,
                onDeleteContact: {
                    store.deleteContact(username: friend.username)
                    selectedFriendForOptions = nil
                },
                onBlock: {
                    store.blockAndUnfriend(username: friend.username)
                    selectedFriendForOptions = nil
                }
            )
            .presentationDetents([.height(255)])
            .presentationCornerRadius(20)
        }
    }

    private func openChatAndDismiss(_ friend: FriendItem) {
        store.unhideConversation(for: friend.username)
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            onOpenChat?(friend)
        }
    }
}

// MARK: - Popup "Novo contato" (Salva na agenda do iPhone; se tiver conta abre chat, senão apenas convite com link do app)
private struct NewContactPopupSheet: View {
    @EnvironmentObject var store: JuntoStore
    var onOpenRegisteredChat: (FriendItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var nameText: String = ""
    @State private var phoneText: String = ""
    @State private var isSaving: Bool = false
    @State private var notOnJuntoYet: Bool = false

    private var canSave: Bool {
        nameText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 &&
        ContactsManager.normalizeBrDigits(phoneText).count >= 10
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Novo contato")
                    .font(.inter(18, weight: .bold))
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
            .onChange(of: nameText) { _, _ in notOnJuntoYet = false }

            CleanOutlineInput(
                label: "Telefone",
                placeholder: "(11) 99999-9999",
                text: $phoneText,
                keyboardType: .phonePad,
                leadingPrefix: "+55"
            )
            .onChange(of: phoneText) { _, newValue in
                notOnJuntoYet = false
                let formatted = formatLivePhoneInput(newValue)
                if formatted != phoneText {
                    phoneText = formatted
                }
            }

            if notOnJuntoYet {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Este número ainda não tem conta no Juntô. Envie um convite com o link do app:")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)

                    ShareLink(item: ContactsManager.inviteMessage(for: nameText)) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Convidar e compartilhar link do app")
                                .font(.inter(14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(JuntoColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            } else {
                Button {
                    guard canSave, !isSaving else { return }
                    isSaving = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    ContactsManager.shared.saveContactToiPhone(name: nameText, phone: phoneText)
                    Task {
                        let result = await store.addContactAndOpenChat(name: nameText, phone: phoneText)
                        isSaving = false
                        if result.isRegistered, let friend = result.friend {
                            onOpenRegisteredChat(friend)
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                notOnJuntoYet = true
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Salvar contato")
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
            }

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

// MARK: - Sheet Claro Customizado (3 Pontos do Contato: Excluir contato / Bloquear)
struct FriendOptionsSheet: View {
    let friend: FriendItem
    let onDeleteContact: () -> Void
    let onBlock: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                GeometricAvatarView(seed: friend.username, displayName: friend.name, size: 46)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(friend.name)
                            .font(.inter(16, weight: .semibold))
                            .foregroundColor(JuntoColors.textMain)
                        VerifiedBadgeView(type: friend.proPlanType, size: 14)
                    }
                    Text(friend.phone.isEmpty ? "@\(friend.username)" : friend.phone)
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }
                Spacer()
                PopupCloseButton { dismiss() }
            }
            .padding(.top, 20)

            Divider().opacity(0.6)

            Button(action: onDeleteContact) {
                HStack(spacing: 12) {
                    Image(systemName: "trash")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                    Text("Excluir contato")
                        .font(.inter(15, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Spacer()
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider().opacity(0.5)

            Button(action: onBlock) {
                HStack(spacing: 12) {
                    Image(systemName: "nosign")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(JuntoColors.danger)
                    Text("Bloquear usuário")
                        .font(.inter(15, weight: .semibold))
                        .foregroundColor(JuntoColors.danger)
                    Spacer()
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color.white.ignoresSafeArea())
    }
}
