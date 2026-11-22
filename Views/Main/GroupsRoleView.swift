import SwiftUI

struct GroupsRoleView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var quickUsername: String = ""
    @State private var showCreateRole = false
    @State private var selectedGroupForComanda: RoleGroup? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // 1. Card de Convite Rápido apenas com @usuário
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Adicionar amigo pelo @usuário", systemImage: "person.badge.plus")
                            .font(.inter(13, weight: .bold))
                            .foregroundColor(JuntoColors.textMain)
                        Spacer()
                        Text("Rápido")
                            .font(.inter(11, weight: .semibold))
                            .foregroundColor(JuntoColors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(JuntoColors.primaryLight)
                            .cornerRadius(6)
                    }

                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text("@")
                                .font(.inter(14, weight: .bold))
                                .foregroundColor(JuntoColors.primary)
                            TextField("nome.do.amigo", text: $quickUsername)
                                .font(.inter(13, weight: .medium))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(JuntoColors.bgMain)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(JuntoColors.border, lineWidth: 1))
                        .cornerRadius(8)

                        Button {
                            store.sendFriendInvite(username: quickUsername)
                            quickUsername = ""
                        } label: {
                            HStack(spacing: 5) {
                                Text("Enviar convite")
                                    .font(.inter(12, weight: .bold))
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(JuntoColors.primary)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(14)
                .background(JuntoColors.surface)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                .cornerRadius(14)

                // 2. Resumo Financeiro Flat (BRL)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Você vai receber")
                            .font(.inter(12, weight: .semibold))
                            .foregroundColor(JuntoColors.textMuted)
                        Text(JuntoStore.formatBRL(store.totalToReceive))
                            .font(.inter(18, weight: .heavy))
                            .foregroundColor(JuntoColors.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(JuntoColors.surface)
                    .overlay(
                        HStack {
                            Rectangle().fill(JuntoColors.secondary).frame(width: 4)
                            Spacer()
                        }
                    )
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(JuntoColors.border, lineWidth: 1))
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sua parte a pagar")
                            .font(.inter(12, weight: .semibold))
                            .foregroundColor(JuntoColors.textMuted)
                        Text(JuntoStore.formatBRL(store.totalToPay))
                            .font(.inter(18, weight: .heavy))
                            .foregroundColor(JuntoColors.danger)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(JuntoColors.surface)
                    .overlay(
                        HStack {
                            Rectangle().fill(JuntoColors.danger).frame(width: 4)
                            Spacer()
                        }
                    )
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(JuntoColors.border, lineWidth: 1))
                    .cornerRadius(12)
                }

                // 3. Cabeçalho da Seção de Grupos / Rolês (Nosso Diferencial)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Seus Rolês & Potes")
                            .font(.inter(16, weight: .heavy))
                            .foregroundColor(JuntoColors.textMain)
                        Text("Com Pote Coletivo, Comanda IA e Pix")
                            .font(.inter(12))
                            .foregroundColor(JuntoColors.textMuted)
                    }
                    Spacer()
                    Button {
                        showCreateRole = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Novo Rolê")
                        }
                        .font(.inter(12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(JuntoColors.primary)
                        .cornerRadius(8)
                    }
                }
                .padding(.top, 4)

                // 4. Cards Inovadores de Rolês com Fotos Reais
                ForEach(store.groups) { group in
                    RoleGroupCard(
                        group: group,
                        onOpenComanda: { selectedGroupForComanda = group },
                        onRechargePot: {
                            store.openPixPayment(
                                title: "Recarga do Pote • \(group.title)",
                                recipient: "Pote Coletivo Juntô",
                                amount: 50.00
                            )
                        },
                        onRefundPot: {
                            store.refundPotRemainder(for: group.id)
                        },
                        onPayShare: {
                            store.openPixPayment(
                                title: group.title,
                                recipient: "Grupo \(group.title)",
                                amount: max(group.myShare, 25.00)
                            )
                        }
                    )
                }
            }
            .padding(16)
        }
        .sheet(isPresented: $showCreateRole) {
            CreateRoleSheetView()
                .environmentObject(store)
                .presentationDetents([.medium])
        }
        .sheet(item: $selectedGroupForComanda) { group in
            ComandaIASheetView(group: group)
                .environmentObject(store)
                .presentationDetents([.medium, .large])
        }
    }
}

struct RoleGroupCard: View {
    let group: RoleGroup
    let onOpenComanda: () -> Void
    let onRechargePot: () -> Void
    let onRefundPot: () -> Void
    let onPayShare: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Capa Real do Rolê
            ZStack(alignment: .bottomLeading) {
                Image(group.coverImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 118)
                    .clipped()

                LinearGradient(
                    colors: [Color.black.opacity(0.15), Color.black.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(group.category.uppercased())
                        .font(.inter(10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.22))
                        .cornerRadius(6)

                    Text(group.title)
                        .font(.inter(17, weight: .heavy))
                        .foregroundColor(.white)
                }
                .padding(14)
            }
            .frame(height: 118)

            // Corpo do Card
            VStack(alignment: .leading, spacing: 12) {
                if group.hasCollectivePot {
                    // DIFERENCIAL: Pote Coletivo do Rolê
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Pote Coletivo", systemImage: "tray.and.arrow.down.fill")
                                .font(.inter(12, weight: .bold))
                                .foregroundColor(JuntoColors.textMain)
                            Spacer()
                            Text("Saldo: \(JuntoStore.formatBRL(group.potBalance))")
                                .font(.inter(12, weight: .heavy))
                                .foregroundColor(JuntoColors.secondary)
                        }

                        GeometryReader { geo in
                            let ratio = group.potTarget > 0 ? min(group.potBalance / group.potTarget, 1.0) : 0
                            ZStack(alignment: .leading) {
                                Capsule().fill(JuntoColors.border)
                                Capsule()
                                    .fill(JuntoColors.secondary)
                                    .frame(width: geo.size.width * ratio)
                            }
                        }
                        .frame(height: 6)

                        HStack(spacing: 8) {
                            Button(action: onRechargePot) {
                                Label("Recarregar Pix", systemImage: "bolt.fill")
                                    .font(.inter(11, weight: .bold))
                                    .foregroundColor(JuntoColors.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 34)
                                    .background(JuntoColors.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(JuntoColors.border, lineWidth: 1))
                                    .cornerRadius(8)
                            }

                            Button(action: onRefundPot) {
                                Label("Devolver Sobra", systemImage: "arrow.uturn.left")
                                    .font(.inter(11, weight: .bold))
                                    .foregroundColor(JuntoColors.secondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 34)
                                    .background(JuntoColors.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(JuntoColors.border, lineWidth: 1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(12)
                    .background(JuntoColors.surfaceSubtle)
                    .cornerRadius(10)
                }

                // Linha de Ação: Comanda IA & Pagamento Pix
                HStack(spacing: 8) {
                    Button(action: onOpenComanda) {
                        Label("Comanda IA", systemImage: "doc.text.viewfinder")
                            .font(.inter(12, weight: .bold))
                            .foregroundColor(JuntoColors.textMain)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(JuntoColors.bgMain)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(JuntoColors.border, lineWidth: 1))
                            .cornerRadius(8)
                    }

                    if group.myShare > 0 {
                        Button(action: onPayShare) {
                            Label("Pagar \(JuntoStore.formatBRL(group.myShare))", systemImage: "bolt.fill")
                                .font(.inter(12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(JuntoColors.primary)
                                .cornerRadius(8)
                        }
                    }
                }

                // Rodapé: Participantes e Gasto Total
                HStack {
                    HStack(spacing: -6) {
                        ForEach(group.members.prefix(5), id: \.self) { m in
                            Text(m)
                                .font(.inter(9, weight: .bold))
                                .foregroundColor(JuntoColors.textMain)
                                .frame(width: 26, height: 26)
                                .background(JuntoColors.primaryLight)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .clipShape(Circle())
                        }
                    }

                    Spacer()

                    Text("Total do rolê: \(JuntoStore.formatBRL(group.totalSpent))")
                        .font(.inter(11, weight: .semibold))
                        .foregroundColor(JuntoColors.textMuted)
                }
            }
            .padding(14)
        }
        .background(JuntoColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(JuntoColors.border, lineWidth: 1))
        .cornerRadius(16)
    }
}

// MARK: - Sheet Comanda Inteligente com IA
struct ComandaIASheetView: View {
    @EnvironmentObject var store: JuntoStore
    @State var group: RoleGroup
    @Environment(\.dismiss) private var dismiss

    private var selectedTotal: Double {
        group.comandaItems.filter { $0.isSelected }.reduce(0) { $0 + $1.price }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Comanda Inteligente (IA)")
                        .font(.inter(18, weight: .heavy))
                        .foregroundColor(JuntoColors.textMain)
                    Text("Toque apenas no que você consumiu em \(group.title)")
                        .font(.inter(12))
                        .foregroundColor(JuntoColors.textMuted)
                }
                Spacer()
            }
            .padding(.top, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach($group.comandaItems) { $item in
                        Button {
                            item.isSelected.toggle()
                        } label: {
                            HStack {
                                Image(systemName: item.isSelected ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 20))
                                    .foregroundColor(item.isSelected ? JuntoColors.primary : JuntoColors.textLight)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.inter(13, weight: .bold))
                                        .foregroundColor(JuntoColors.textMain)
                                    Text(item.detail)
                                        .font(.inter(11))
                                        .foregroundColor(JuntoColors.textMuted)
                                }

                                Spacer()

                                Text(JuntoStore.formatBRL(item.price))
                                    .font(.inter(14, weight: .heavy))
                                    .foregroundColor(JuntoColors.textMain)
                            }
                            .padding(12)
                            .background(item.isSelected ? JuntoColors.primaryLight.opacity(0.55) : JuntoColors.bgMain)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(item.isSelected ? JuntoColors.primary : JuntoColors.border, lineWidth: 1)
                            )
                            .cornerRadius(10)
                        }
                    }
                }
            }

            HStack {
                Text("Sua cota selecionada:")
                    .font(.inter(14, weight: .bold))
                    .foregroundColor(JuntoColors.secondary)
                Spacer()
                Text(JuntoStore.formatBRL(selectedTotal))
                    .font(.inter(20, weight: .heavy))
                    .foregroundColor(JuntoColors.secondary)
            }
            .padding(14)
            .background(JuntoColors.secondaryLight)
            .cornerRadius(10)

            JuntoPrimaryButton(title: "Pagar \(JuntoStore.formatBRL(selectedTotal)) via Pix", icon: "bolt.fill") {
                dismiss()
                store.openPixPayment(title: "Comanda • \(group.title)", recipient: group.title, amount: selectedTotal)
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 20)
        .background(JuntoColors.surface)
    }
}

// MARK: - Sheet Criar Novo Rolê
struct CreateRoleSheetView: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var category: String = "Churrasco"
    @State private var enablePot: Bool = true
    @State private var potGoal: String = "300"

    private let categories = ["Churrasco", "Bar & Drinks", "Viagem Praia"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Criar Novo Rolê")
                .font(.inter(20, weight: .heavy))
                .foregroundColor(JuntoColors.textMain)
                .padding(.top, 20)

            FlatInputField(label: "Nome do rolê", placeholder: "Ex: Churrasco de Sábado", text: $title)

            VStack(alignment: .leading, spacing: 6) {
                Text("Tema do Rolê")
                    .font(.inter(13, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { cat in
                        Button {
                            category = cat
                        } label: {
                            Text(cat)
                                .font(.inter(12, weight: .bold))
                                .foregroundColor(category == cat ? .white : JuntoColors.textMain)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(category == cat ? JuntoColors.primary : JuntoColors.bgMain)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(JuntoColors.border, lineWidth: 1))
                                .cornerRadius(8)
                        }
                    }
                }
            }

            Toggle(isOn: $enablePot) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ativar Pote Coletivo")
                        .font(.inter(13, weight: .bold))
                        .foregroundColor(JuntoColors.textMain)
                    Text("A galera deposita antes e o que sobrar volta por Pix")
                        .font(.inter(11))
                        .foregroundColor(JuntoColors.textMuted)
                }
            }
            .tint(JuntoColors.secondary)

            if enablePot {
                FlatInputField(label: "Meta do Pote (BRL)", placeholder: "300", text: $potGoal, keyboardType: .numberPad, leadingPrefix: "R$")
            }

            Spacer()

            JuntoPrimaryButton(title: "Criar Rolê Agora", icon: "sparkles") {
                store.createNewRole(
                    title: title,
                    category: category,
                    hasPot: enablePot,
                    initialPotTarget: Double(potGoal) ?? 300
                )
                dismiss()
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 20)
        .background(JuntoColors.surface)
    }
}
