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

            // Barra de pesquisa animada ("Pesquisando algum nome?" -> ao tocar fica só para digitar)
            AnimatedSearchBar(
                text: $searchText,
                placeholders: [
                    "Pesquisando algum nome?",
                    "Buscar @pedro.santos...",
                    "Procurando um amigo?",
                    "Pesquisando algum nome?"
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
                                GeometricAvatarView(seed: friend.username, size: 48)

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

// MARK: - Tela Completa de Adicionar Amigo (digitar @nome_de_usuario e enviar convite)
struct AddFriendScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss
    @State private var handle: String = ""

    private var cleanHandle: String {
        handle.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "").lowercased()
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
            .padding(.bottom, 26)

            VStack(alignment: .leading, spacing: 20) {
                // Prévia ao vivo do avatar ilustrado do amigo conforme digita
                if cleanHandle.count >= 2 {
                    HStack(spacing: 14) {
                        GeometricAvatarView(seed: cleanHandle, size: 54)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("@\(cleanHandle)")
                                .font(.inter(16, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                            Text("Pronto para receber seu convite no Juntô")
                                .font(.inter(13, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(JuntoColors.warmBg)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(JuntoColors.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Digite o nome de usuário")
                        .font(.inter(22, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                    Text("Informe o @usuário da pessoa para enviar o convite.")
                        .font(.inter(14, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }

                CleanOutlineInput(
                    label: "Nome de usuário",
                    placeholder: "ex: ana.paula",
                    text: $handle,
                    autocapitalization: .never,
                    leadingPrefix: "@"
                )

                JuntoPillButton(title: "Enviar convite", icon: "paperplane", color: JuntoColors.primary) {
                    guard cleanHandle.count >= 3 else {
                        store.showToast("Digite um nome de usuário válido.", icon: "exclamationmark.circle")
                        return
                    }
                    store.sendFriendInvite(username: cleanHandle)
                    dismiss()
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 22)

            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
    }
}
