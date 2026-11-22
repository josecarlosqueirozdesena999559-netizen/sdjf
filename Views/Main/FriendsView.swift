import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var store: JuntoStore
    var onOpenNotifications: () -> Void

    @State private var showAddFriendScreen = false
    @State private var searchText = ""

    private var filteredFriends: [FriendItem] {
        if searchText.isEmpty { return store.friends }
        return store.friends.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cabeçalho estilo WhatsApp: Título à esquerda | Sino + Botão "+" à direita (SEM lupa!)
            HStack(spacing: 10) {
                Text("Amigos")
                    .font(.inter(24, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)

                Spacer()

                // Sino de notificações
                Button(action: onOpenNotifications) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)
                            .frame(width: 40, height: 40)
                            .background(JuntoColors.surfaceSubtle)
                            .clipShape(Circle())

                        if store.unreadNotificationsCount > 0 {
                            Circle()
                                .fill(JuntoColors.accent)
                                .frame(width: 8, height: 8)
                                .offset(x: -9, y: 9)
                        }
                    }
                }

                // Botão "+" estilo WhatsApp para adicionar amigos
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

            // Barra de pesquisa com animação digitando letra por letra ("@lucas123", "@ana.paula"...)
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

                if !store.friends.isEmpty {
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

            if filteredFriends.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Text(searchText.isEmpty ? "Você ainda não adicionou amigos." : "Nenhum amigo encontrado.")
                        .font(.inter(15, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)

                    if searchText.isEmpty {
                        JuntoPillButton(title: "Adicionar amigo", icon: "person.badge.plus", color: JuntoColors.primary) {
                            showAddFriendScreen = true
                        }
                        .padding(.horizontal, 40)
                    }
                }
                .frame(maxWidth: .infinity)
                Spacer()
                Spacer().frame(height: 100)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(filteredFriends) { friend in
                            HStack(spacing: 14) {
                                GeometricAvatarView(seed: friend.username, displayName: friend.name, size: 48)

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
                                        .foregroundColor(JuntoColors.primary)
                                } else if friend.balance > 0 {
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("te deve")
                                            .font(.inter(11, weight: .regular))
                                            .foregroundColor(JuntoColors.pixGreen)
                                        Text(JuntoStore.formatBRL(friend.balance))
                                            .font(.inter(15, weight: .medium))
                                            .foregroundColor(JuntoColors.pixGreen)
                                    }
                                } else if friend.balance < 0 {
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("você deve \(JuntoStore.formatBRL(abs(friend.balance)))")
                                            .font(.inter(12, weight: .regular))
                                            .foregroundColor(JuntoColors.orangeSave)
                                        Button("Pagar Pix") {
                                            store.openPixPayment(
                                                title: "Acerto com \(friend.name)",
                                                recipient: friend.name,
                                                amount: abs(friend.balance)
                                            )
                                        }
                                        .font(.inter(12, weight: .medium))
                                        .foregroundColor(JuntoColors.primary)
                                    }
                                } else {
                                    Text("quitado")
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textLight)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 13)

                            Divider().padding(.leading, 82)
                        }
                    }
                    .padding(.bottom, 140)
                }
            }
        }
        .background(Color.white)
        .fullScreenCover(isPresented: $showAddFriendScreen) {
            AddFriendScreen()
                .environmentObject(store)
        }
    }
}

// MARK: - Tela Completa de Adicionar Amigo (busca letra por letra + avatar + Adicionar / Convite enviado bloqueado)
struct AddFriendScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    private var cleanQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "").lowercased()
    }

    private var searchResults: [SearchableUser] {
        guard !cleanQuery.isEmpty else { return [] }
        var matches = store.directoryUsers.filter {
            $0.username.lowercased().contains(cleanQuery) ||
            $0.name.lowercased().contains(cleanQuery)
        }
        // Se digitou um @username exato com 3+ letras que não está no diretório, permite convidar também
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
                Text("Adicionar amigo")
                    .font(.inter(17, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Spacer().frame(width: 44)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 18)

            VStack(alignment: .leading, spacing: 14) {
                Text("Pesquise pelo @usuário ou nome")
                    .font(.inter(14, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)

                CleanOutlineInput(
                    label: "",
                    placeholder: "Digite uma letra ou @usuário (ex: ana)",
                    text: $query,
                    autocapitalization: .never,
                    leadingPrefix: "@"
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            Divider().opacity(0.6)

            if cleanQuery.isEmpty {
                VStack(spacing: 10) {
                    Spacer().frame(height: 50)
                    Image(systemName: "person.2")
                        .font(.system(size: 32, weight: .thin))
                        .foregroundColor(JuntoColors.textLight)
                    Text("Comece a digitar para encontrar amigos no Juntô")
                        .font(.inter(14, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(searchResults) { person in
                            let alreadySent = store.isInviteSent(for: person.username)

                            HStack(spacing: 12) {
                                GeometricAvatarView(seed: person.username, displayName: person.name, size: 46)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(person.name)
                                        .font(.inter(15, weight: .regular))
                                        .foregroundColor(JuntoColors.textMain)
                                    Text("@\(person.username)")
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                }

                                Spacer()

                                Button {
                                    if alreadySent {
                                        store.cancelFriendInvite(username: person.username)
                                    } else {
                                        store.sendFriendInvite(username: person.username, displayName: person.name)
                                    }
                                } label: {
                                    Text(alreadySent ? "Convite enviado" : "Adicionar")
                                        .font(.inter(13, weight: .medium))
                                        .foregroundColor(alreadySent ? JuntoColors.textMain : .white)
                                        .padding(.horizontal, 14)
                                        .frame(height: 36)
                                        .background(alreadySent ? JuntoColors.surfaceSubtle : JuntoColors.primary)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(alreadySent ? JuntoColors.border : Color.clear, lineWidth: 1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)

                            Divider().padding(.leading, 78)
                        }
                    }
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}
