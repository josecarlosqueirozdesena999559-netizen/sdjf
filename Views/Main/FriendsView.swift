import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var inviteHandle: String = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Adicionar amigo apenas pelo @usuário
                VStack(alignment: .leading, spacing: 10) {
                    Text("Adicionar amigos pelo @usuário")
                        .font(.inter(14, weight: .bold))
                        .foregroundColor(JuntoColors.textMain)

                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text("@")
                                .font(.inter(15, weight: .bold))
                                .foregroundColor(JuntoColors.primary)
                            TextField("digite.o.usuario", text: $inviteHandle)
                                .font(.inter(14, weight: .medium))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 46)
                        .background(JuntoColors.bgMain)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(JuntoColors.border, lineWidth: 1))
                        .cornerRadius(8)

                        Button {
                            store.sendFriendInvite(username: inviteHandle)
                            inviteHandle = ""
                        } label: {
                            Text("Enviar convite")
                                .font(.inter(12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .frame(height: 46)
                                .background(JuntoColors.primary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(16)
                .background(JuntoColors.surface)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                .cornerRadius(14)

                Text("Seus Amigos (\(store.friends.count))")
                    .font(.inter(15, weight: .heavy))
                    .foregroundColor(JuntoColors.textMain)

                VStack(spacing: 10) {
                    ForEach(store.friends) { friend in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(friend.balance < 0 ? JuntoColors.dangerLight : JuntoColors.primaryLight)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(friend.initials)
                                        .font(.inter(14, weight: .heavy))
                                        .foregroundColor(friend.balance < 0 ? JuntoColors.danger : JuntoColors.primary)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(friend.name)
                                    .font(.inter(14, weight: .bold))
                                    .foregroundColor(JuntoColors.textMain)
                                Text("@\(friend.username)")
                                    .font(.inter(12))
                                    .foregroundColor(JuntoColors.textMuted)
                            }

                            Spacer()

                            if friend.isPendingInvite {
                                Text("Convite enviado")
                                    .font(.inter(11, weight: .bold))
                                    .foregroundColor(JuntoColors.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(JuntoColors.primaryLight)
                                    .cornerRadius(6)
                            } else if friend.balance > 0 {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Te deve")
                                        .font(.inter(11, weight: .semibold))
                                        .foregroundColor(JuntoColors.secondary)
                                    Text(JuntoStore.formatBRL(friend.balance))
                                        .font(.inter(14, weight: .heavy))
                                        .foregroundColor(JuntoColors.secondary)
                                }
                            } else if friend.balance < 0 {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Você deve \(JuntoStore.formatBRL(abs(friend.balance)))")
                                        .font(.inter(12, weight: .bold))
                                        .foregroundColor(JuntoColors.danger)
                                    Button {
                                        store.openPixPayment(
                                            title: "Acerto com \(friend.name)",
                                            recipient: friend.name,
                                            amount: abs(friend.balance)
                                        )
                                    } label: {
                                        Text("Pagar Pix →")
                                            .font(.inter(11, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(JuntoColors.primary)
                                            .cornerRadius(6)
                                    }
                                }
                            } else {
                                Text("Quitado ✓")
                                    .font(.inter(12, weight: .semibold))
                                    .foregroundColor(JuntoColors.textLight)
                            }
                        }
                        .padding(14)
                        .background(JuntoColors.surface)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(JuntoColors.border, lineWidth: 1))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(16)
        }
    }
}
