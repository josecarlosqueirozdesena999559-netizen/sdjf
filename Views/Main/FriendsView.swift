import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var store: JuntoStore
    var onOpenNotifications: () -> Void

    @State private var showInviteSheet = false
    @State private var searchText = ""
    @State private var showSearchBar = false

    private var filteredFriends: [FriendItem] {
        if searchText.isEmpty { return store.friends }
        return store.friends.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            SubtleFacetBackground()

            VStack(alignment: .leading, spacing: 0) {
                // Topo exatamente como no modelo: Lupa à esquerda, Sino + Pílula "Adicionar amigos" à direita
                HStack(spacing: 10) {
                    CircleNavButton(icon: "magnifyingglass") {
                        withAnimation { showSearchBar.toggle() }
                    }

                    Spacer()

                    // Sino de notificações discreto
                    Button(action: onOpenNotifications) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(JuntoColors.textMain)
                                .frame(width: 44, height: 44)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                                .overlay(Circle().stroke(JuntoColors.border.opacity(0.6), lineWidth: 0.6))

                            if store.unreadNotificationsCount > 0 {
                                Circle()
                                    .fill(JuntoColors.primary)
                                    .frame(width: 8, height: 8)
                                    .offset(x: -10, y: 10)
                            }
                        }
                    }

                    Button {
                        showInviteSheet = true
                    } label: {
                        Text("Adicionar amigos")
                            .font(.inter(14, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)
                            .padding(.horizontal, 18)
                            .frame(height: 44)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                            .overlay(Capsule().stroke(JuntoColors.border.opacity(0.6), lineWidth: 0.6))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 14)

                Divider().opacity(0.5)

                if showSearchBar {
                    CleanOutlineInput(label: "", placeholder: "Buscar amigo por nome ou @usuário", text: $searchText)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                }

                // Saudação limpa + resumo total de saldo
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bem-vindo(a) ao Juntô, \(store.user.firstName)!")
                        .font(.inter(18, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)

                    if !store.friends.isEmpty {
                        HStack(spacing: 4) {
                            Text(store.netBalance >= 0 ? "No total, você recebe" : "No total, você deve")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                            Text(JuntoStore.formatBRL(abs(store.netBalance)))
                                .font(.inter(14, weight: .medium))
                                .foregroundColor(store.netBalance >= 0 ? JuntoColors.pixGreen : JuntoColors.orangeSave)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)

                if filteredFriends.isEmpty {
                    // Empty state limpo com o logo geométrico do Juntô
                    Spacer()

                    VStack(spacing: 24) {
                        Text("Você não adicionou amigos ainda.")
                            .font(.inter(16, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)

                        JuntoPillButton(title: "Adicionar amigos no Juntô", icon: "person.badge.plus", color: JuntoColors.primary) {
                            showInviteSheet = true
                        }
                        .padding(.horizontal, 34)

                        JuntoLogoMark(size: 104)
                            .opacity(0.92)
                            .padding(.top, 16)
                    }
                    .frame(maxWidth: .infinity)

                    Spacer()
                    Spacer().frame(height: 110)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(filteredFriends) { friend in
                                HStack(spacing: 14) {
                                    GeometricAvatarView(
                                        seed: friend.username,
                                        size: 44
                                    )

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
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.85))

                                Divider().padding(.leading, 78)
                            }
                        }
                        .padding(.top, 14)
                        .padding(.bottom, 140)
                    }
                }
            }
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteFriendByUsernameSheet()
                .environmentObject(store)
                .presentationDetents([.height(290)])
        }
    }
}

struct InviteFriendByUsernameSheet: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss
    @State private var handle: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                CircleNavButton(icon: "xmark") { dismiss() }
                Spacer()
                Text("Adicionar amigo")
                    .font(.inter(17, weight: .regular))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Spacer().frame(width: 44)
            }
            .padding(.top, 16)

            CleanOutlineInput(
                label: "Nome de usuário do amigo",
                placeholder: "nome.do.amigo",
                text: $handle,
                autocapitalization: .never,
                leadingPrefix: "@"
            )

            JuntoPillButton(title: "Enviar convite", color: JuntoColors.primary) {
                store.sendFriendInvite(username: handle)
                dismiss()
            }

            Spacer()
        }
        .padding(.horizontal, 22)
        .background(Color.white)
    }
}
