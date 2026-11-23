import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var store: JuntoStore
    var onOpenNotifications: () -> Void

    @State private var showAddFriendScreen = false
    @State private var selectedChatFriend: FriendItem? = nil
    @State private var selectedGroupChatId: UUID? = nil
    @State private var searchText = ""

    /// Na tela inicial aparecem SOMENTE amigos que te devem ou a quem você deve (balance != 0)
    private var activeDebtFriends: [FriendItem] {
        let withDebt = store.friends.filter { $0.balance != 0 }
        if searchText.isEmpty { return withDebt }
        return withDebt.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Conversas automáticas de todos os grupos criados (desaparecem automaticamente ao excluir o grupo)
    private var activeGroupChats: [RoleGroup] {
        if searchText.isEmpty { return store.groups }
        return store.groups.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
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

            // Barra de pesquisa com animação digitando letra por letra
            AnimatedSearchBar(
                text: $searchText,
                placeholders: [
                    "Pesquisar @lucas123",
                    "Pesquisar @ana.paula",
                    "Pesquisar @pedro.santos",
                    "Pesquisar @camila.rocha"
                ]
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            // Saudação limpa + resumo do saldo
            VStack(alignment: .leading, spacing: 3) {
                Text("Olá, \(store.user.firstName)")
                    .font(.inter(16, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)

                if !activeDebtFriends.isEmpty {
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

            if activeDebtFriends.isEmpty && activeGroupChats.isEmpty {
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
                        Text("Nenhum amigo encontrado.")
                            .font(.inter(15, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                    }
                }
                .frame(maxWidth: .infinity)
                Spacer()
                Spacer().frame(height: 110)
            } else {
                // Lista estilo WhatsApp: Conversas de Grupos (automáticas) + Amigos com saldo ativo
                List {
                    ForEach(activeGroupChats) { group in
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

                    ForEach(activeDebtFriends) { friend in
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
                                    Text(friend.name)
                                        .font(.inter(15, weight: .medium))
                                        .foregroundColor(JuntoColors.textMain)
                                        .lineLimit(1)

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

                    // Espaço para a barra flutuante inferior
                    Color.clear
                        .frame(height: 120)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
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
}

// MARK: - Tela do botão "+": Lista de todos os amigos + Busca de novos amigos letra por letra
struct AddFriendScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss
    var onOpenChat: ((FriendItem) -> Void)? = nil

    @State private var query: String = ""
    @State private var selectedFriendForOptions: FriendItem? = nil

    private var cleanQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "").lowercased()
    }

    private var searchResults: [SearchableUser] {
        guard !cleanQuery.isEmpty else { return [] }
        var matches = store.directoryUsers.filter {
            $0.username.lowercased().contains(cleanQuery) ||
            $0.name.localizedCaseInsensitiveContains(cleanQuery)
        }
        if cleanQuery.count >= 3 && !matches.contains(where: { $0.username.lowercased() == cleanQuery }) {
            let formattedName = cleanQuery
                .split(separator: ".")
                .map { $0.capitalized }
                .joined(separator: " ")
            matches.append(SearchableUser(name: formattedName, username: cleanQuery))
        }
        return matches
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                CircleNavButton(icon: "chevron.left") { dismiss() }
                Spacer()
                Text("Amigos e convites")
                    .font(.inter(17, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Spacer().frame(width: 44)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 16)

            // Barra de busca compacta para pesquisar novos amigos
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)

                TextField("Buscar por @usuário ou nome...", text: $query)
                    .font(.inter(14, weight: .regular))
                    .foregroundColor(JuntoColors.textMain)
                    .textInputAutocapitalization(.never)
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
            .frame(height: 38)
            .background(JuntoColors.surfaceSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.horizontal, 18)
            .padding(.bottom, 10)

            Divider().opacity(0.6)

            if cleanQuery.isEmpty {
                // Lista completa de todos os amigos já adicionados (inclusive quitados)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Seus amigos (\(store.friends.count))")
                            .font(.inter(13, weight: .medium))
                            .foregroundColor(JuntoColors.textMuted)
                            .padding(.horizontal, 20)
                            .padding(.top, 14)
                            .padding(.bottom, 8)

                        ForEach(store.friends) { friend in
                            Button {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onOpenChat?(friend)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack(alignment: .bottomTrailing) {
                                        GeometricAvatarView(seed: friend.username, displayName: friend.name, size: 46)
                                        if friend.isOnline {
                                            Circle()
                                                .fill(JuntoColors.pixGreen)
                                                .frame(width: 12, height: 12)
                                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(friend.name)
                                            .font(.inter(15, weight: .regular))
                                            .foregroundColor(JuntoColors.textMain)
                                        Text("@\(friend.username)")
                                            .font(.inter(12, weight: .regular))
                                            .foregroundColor(JuntoColors.textMuted)
                                    }

                                    Spacer()

                                    if friend.isPendingInvite {
                                        Text("Convite enviado")
                                            .font(.inter(12, weight: .regular))
                                            .foregroundColor(JuntoColors.textMuted)
                                    } else if friend.balance > 0 {
                                        Text("+ \(JuntoStore.formatBRL(friend.balance))")
                                            .font(.inter(13, weight: .medium))
                                            .foregroundColor(JuntoColors.pixGreen)
                                    } else if friend.balance < 0 {
                                        Text("- \(JuntoStore.formatBRL(abs(friend.balance)))")
                                            .font(.inter(13, weight: .medium))
                                            .foregroundColor(JuntoColors.orangeSave)
                                    } else {
                                        Text("Conversar")
                                            .font(.inter(12, weight: .medium))
                                            .foregroundColor(JuntoColors.primary)
                                    }

                                    // Botão 3 pontos (Desfazer amizade / Bloquear)
                                    Button {
                                        selectedFriendForOptions = friend
                                    } label: {
                                        Image(systemName: "ellipsis")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(JuntoColors.textMuted)
                                            .frame(width: 32, height: 32)
                                            .background(JuntoColors.surfaceSubtle)
                                            .clipShape(Circle())
                                    }
                                    .padding(.leading, 4)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                            }

                            Divider().padding(.leading, 78)
                        }
                    }
                }
            } else {
                // Busca letra por letra bem compacta para adicionar novos amigos
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(searchResults) { person in
                            let alreadySent = store.isInviteSent(for: person.username)

                            HStack(spacing: 10) {
                                GeometricAvatarView(seed: person.username, displayName: person.name, size: 32)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(person.name)
                                        .font(.inter(13, weight: .medium))
                                        .foregroundColor(JuntoColors.textMain)
                                        .lineLimit(1)
                                    Text("@\(person.username)")
                                        .font(.inter(11, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                        .lineLimit(1)
                                }

                                Spacer(minLength: 6)

                                Button {
                                    if alreadySent {
                                        store.cancelFriendInvite(username: person.username)
                                    } else {
                                        store.sendFriendInvite(username: person.username, displayName: person.name)
                                    }
                                } label: {
                                    Text(alreadySent ? "Enviado" : "Adicionar")
                                        .font(.inter(11, weight: .medium))
                                        .foregroundColor(alreadySent ? JuntoColors.textMain : .white)
                                        .padding(.horizontal, 10)
                                        .frame(height: 28)
                                        .background(alreadySent ? JuntoColors.surfaceSubtle : JuntoColors.primary)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .stroke(alreadySent ? JuntoColors.border : Color.clear, lineWidth: 1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 6)

                            Divider().padding(.leading, 60)
                        }
                    }
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
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
                    Text(friend.name)
                        .font(.inter(16, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Text("@\(friend.username)")
                        .font(.inter(13, weight: .regular))
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
