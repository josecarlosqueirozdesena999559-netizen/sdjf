import SwiftUI

struct GroupsRoleView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var showCreateGroup = false
    @State private var selectedGroupId: UUID? = nil
    @State private var searchText = ""

    private var filteredGroups: [RoleGroup] {
        if searchText.isEmpty { return store.groups }
        return store.groups.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Topo estilo WhatsApp: "Grupos" + botão "+" à direita
            HStack {
                Text("Grupos")
                    .font(.inter(24, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Button {
                    showCreateGroup = true
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

            AnimatedSearchBar(
                text: $searchText,
                placeholders: [
                    "Pesquisar Viagem Ubatuba",
                    "Pesquisar Churrasco",
                    "Pesquisar Contas do Apê"
                ]
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            Divider().opacity(0.6)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredGroups) { group in
                        Button {
                            selectedGroupId = group.id
                        } label: {
                            HStack(spacing: 14) {
                                Image(group.coverImageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 58, height: 58)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(group.title)
                                        .font(.inter(16, weight: .regular))
                                        .foregroundColor(JuntoColors.textMain)

                                    if group.hasCollectivePot {
                                        Text("Pote Coletivo: \(JuntoStore.formatBRL(group.potBalance))")
                                            .font(.inter(13, weight: .regular))
                                            .foregroundColor(JuntoColors.pixGreen)
                                    } else {
                                        Text(group.category)
                                            .font(.inter(13, weight: .regular))
                                            .foregroundColor(JuntoColors.textMuted)
                                    }

                                    if group.myShare > 0 {
                                        Text("Sua parte: \(JuntoStore.formatBRL(group.myShare))")
                                            .font(.inter(12, weight: .regular))
                                            .foregroundColor(JuntoColors.orangeSave)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(JuntoColors.textLight)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        }

                        Divider().padding(.leading, 92)
                    }
                }
                .padding(.bottom, 140)
            }
        }
        .background(Color.white)
        .fullScreenCover(isPresented: $showCreateGroup) {
            CreateGroupScreen(initialType: store.openCreateGroupWithCategory ?? "Viagem") { createdGroupId in
                selectedGroupId = createdGroupId
            }
            .environmentObject(store)
            .onDisappear {
                store.openCreateGroupWithCategory = nil
            }
        }
        .onAppear {
            if store.openCreateGroupWithCategory != nil {
                showCreateGroup = true
            }
        }
        .sheet(isPresented: Binding(
            get: { selectedGroupId != nil },
            set: { if !$0 { selectedGroupId = nil } }
        )) {
            if let gid = selectedGroupId {
                GroupDetailSheet(groupId: gid)
                    .environmentObject(store)
                    .presentationDetents([.large])
            }
        }
    }
}

// MARK: - Tela "Criar um grupo"
struct CreateGroupScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    var initialType: String = "Viagem"
    var onCreated: ((UUID) -> Void)? = nil

    @State private var groupName: String = ""
    @State private var selectedType: String = "Viagem"
    @State private var enableCollectivePot: Bool = true

    private let types: [(name: String, icon: String)] = [
        ("Viagem", "airplane"),
        ("Casa", "house"),
        ("Casal", "heart"),
        ("Outros", "list.bullet.rectangle")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                CircleNavButton(icon: "xmark") { dismiss() }
                Spacer()
                Text("Criar um grupo")
                    .font(.inter(17, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                CircleNavButton(icon: "checkmark", bgColor: JuntoColors.primary, fgColor: .white) {
                    let clean = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !clean.isEmpty else {
                        store.showToast("Informe o nome do grupo.", icon: "exclamationmark.circle")
                        return
                    }
                    store.createNewGroup(title: clean, category: selectedType, hasPot: enableCollectivePot)
                    let createdId = store.groups.first?.id
                    dismiss()
                    if let cid = createdId {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            onCreated?(cid)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 24)

            HStack(alignment: .center, spacing: 16) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(JuntoColors.surfaceSubtle)
                    .frame(width: 62, height: 62)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .foregroundColor(JuntoColors.textLight)
                    )
                    .overlay(
                        Image(systemName: "camera")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Nome do grupo")
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)

                    TextField("Ex: Churrasco de Sábado", text: $groupName)
                        .font(.inter(16, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)

                    Rectangle()
                        .fill(JuntoColors.primary)
                        .frame(height: 1.5)
                }
            }
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 14) {
                Text("Tipo")
                    .font(.inter(14, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)

                HStack(spacing: 10) {
                    ForEach(types, id: \.name) { item in
                        let isSelected = selectedType == item.name
                        Button {
                            selectedType = item.name
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 22, weight: .light))
                                    .foregroundColor(isSelected ? JuntoColors.primary : JuntoColors.textMain)
                                Text(item.name)
                                    .font(.inter(13, weight: .regular))
                                    .foregroundColor(isSelected ? JuntoColors.primary : JuntoColors.textMain)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 82)
                            .background(isSelected ? JuntoColors.primaryLight : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? JuntoColors.primary : JuntoColors.border, lineWidth: isSelected ? 1.3 : 1)
                            )
                            .cornerRadius(12)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)

            Toggle(isOn: $enableCollectivePot) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ativar Pote Coletivo")
                        .font(.inter(14, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Text("Reúna o saldo do grupo para pagar as despesas juntos.")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }
            }
            .tint(JuntoColors.primary)
            .padding(.horizontal, 20)
            .padding(.top, 28)

            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            selectedType = initialType
        }
    }
}

// MARK: - Detalhe do Grupo 100% Funcional (Pote Coletivo sem devolver sobra + Despesas + Membros + Pix)
struct GroupDetailSheet: View {
    @EnvironmentObject var store: JuntoStore
    let groupId: UUID
    @Environment(\.dismiss) private var dismiss

    @State private var showAddExpenseForm = false
    @State private var expenseName = ""
    @State private var expenseAmount = ""
    @State private var payFromPot = false

    @State private var showAddMemberForm = false
    @State private var newMemberHandle = ""

    @State private var selectedPotAmount: Double = 50.00

    private var groupIndex: Int? {
        store.groups.firstIndex(where: { $0.id == groupId })
    }

    var body: some View {
        if let idx = groupIndex {
            let group = store.groups[idx]
            let selectedTotal = group.comandaItems.filter { $0.isSelected }.reduce(0) { $0 + $1.price }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Topo
                    HStack {
                        CircleNavButton(icon: "xmark") { dismiss() }
                        Spacer()
                        Text(group.title)
                            .font(.inter(17, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                            .lineLimit(1)
                        Spacer()
                        Spacer().frame(width: 44)
                    }
                    .padding(.top, 16)

                    // Capa do grupo + resumo
                    ZStack(alignment: .bottomLeading) {
                        Image(group.coverImageName)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 145)
                            .clipped()

                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.category)
                                    .font(.inter(11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                                Text("Total gasto: \(JuntoStore.formatBRL(group.totalSpent))")
                                    .font(.inter(15, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Text("\(group.members.count) participante(s)")
                                .font(.inter(12, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(14)
                    }
                    .frame(height: 145)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    // Membros + Adicionar membro funcional
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Participantes")
                                .font(.inter(14, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                            Spacer()
                            Button {
                                withAnimation { showAddMemberForm.toggle() }
                            } label: {
                                Label(showAddMemberForm ? "Fechar" : "Adicionar membro", systemImage: showAddMemberForm ? "xmark" : "person.badge.plus")
                                    .font(.inter(12, weight: .medium))
                                    .foregroundColor(JuntoColors.primary)
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(group.members, id: \.self) { m in
                                    VStack(spacing: 4) {
                                        GeometricAvatarView(seed: "\(group.title)_\(m)", size: 40)
                                        Text(m)
                                            .font(.inter(11, weight: .regular))
                                            .foregroundColor(JuntoColors.textMuted)
                                    }
                                }
                            }
                        }

                        if showAddMemberForm {
                            HStack(spacing: 8) {
                                CleanOutlineInput(
                                    label: "",
                                    placeholder: "ex: ana.paula",
                                    text: $newMemberHandle,
                                    autocapitalization: .never,
                                    leadingPrefix: "@"
                                )
                                Button("Incluir") {
                                    store.addMemberToGroup(groupId: groupId, memberUsername: newMemberHandle)
                                    newMemberHandle = ""
                                    showAddMemberForm = false
                                }
                                .font(.inter(13, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(JuntoColors.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }

                    // POTE COLETIVO (sem "Devolver sobra" — 100% funcional para contribuir via Pix)
                    if group.hasCollectivePot {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Pote Coletivo", systemImage: "dollarsign.circle")
                                    .font(.inter(15, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                                Spacer()
                                Text(JuntoStore.formatBRL(group.potBalance))
                                    .font(.inter(16, weight: .medium))
                                    .foregroundColor(JuntoColors.pixGreen)
                            }

                            if group.potTarget > 0 {
                                GeometryReader { geo in
                                    let ratio = min(group.potBalance / group.potTarget, 1.0)
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4).fill(JuntoColors.border)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(JuntoColors.pixGreen)
                                            .frame(width: geo.size.width * ratio)
                                    }
                                }
                                .frame(height: 6)

                                Text("Meta do pote: \(JuntoStore.formatBRL(group.potTarget))")
                                    .font(.inter(12, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                            }

                            // Valores rápidos de contribuição
                            HStack(spacing: 8) {
                                ForEach([25.0, 50.0, 100.0], id: \.self) { amount in
                                    let active = selectedPotAmount == amount
                                    Button {
                                        selectedPotAmount = amount
                                    } label: {
                                        Text("+ \(JuntoStore.formatBRL(amount))")
                                            .font(.inter(13, weight: .medium))
                                            .foregroundColor(active ? .white : JuntoColors.textMain)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 36)
                                            .background(active ? JuntoColors.primary : Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(active ? JuntoColors.primary : JuntoColors.border, lineWidth: 1)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }

                            JuntoPillButton(
                                title: "Contribuir \(JuntoStore.formatBRL(selectedPotAmount)) via Pix",
                                color: JuntoColors.primary
                            ) {
                                dismiss()
                                store.contributeToPot(groupId: groupId, amount: selectedPotAmount)
                            }
                        }
                        .padding(16)
                        .background(JuntoColors.warmBg)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Despesas / Comanda do Grupo (com botão funcional "+ Nova despesa")
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Despesas do grupo")
                                .font(.inter(15, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                            Spacer()
                            Button {
                                withAnimation { showAddExpenseForm.toggle() }
                            } label: {
                                Label(showAddExpenseForm ? "Cancelar" : "Nova despesa", systemImage: showAddExpenseForm ? "xmark" : "plus")
                                    .font(.inter(13, weight: .medium))
                                    .foregroundColor(JuntoColors.primary)
                            }
                        }

                        if showAddExpenseForm {
                            VStack(spacing: 12) {
                                CleanOutlineInput(label: "Descrição", placeholder: "Ex: Mercado, Bebidas, Uber", text: $expenseName)
                                CleanOutlineInput(label: "Valor total (R$)", placeholder: "0,00", text: $expenseAmount, keyboardType: .decimalPad, leadingPrefix: "R$")

                                if group.hasCollectivePot && group.potBalance > 0 {
                                    Toggle("Descontar do saldo do Pote Coletivo", isOn: $payFromPot)
                                        .font(.inter(13, weight: .regular))
                                        .tint(JuntoColors.primary)
                                }

                                JuntoPillButton(title: "Salvar despesa", color: JuntoColors.primary) {
                                    let val = Double(expenseAmount.replacingOccurrences(of: ",", with: ".")) ?? 0
                                    store.addExpenseToGroup(groupId: groupId, name: expenseName, totalAmount: val, payFromPot: payFromPot)
                                    expenseName = ""
                                    expenseAmount = ""
                                    payFromPot = false
                                    showAddExpenseForm = false
                                }
                            }
                            .padding(14)
                            .background(JuntoColors.warmBg)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(JuntoColors.border, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        if group.comandaItems.isEmpty {
                            Text("Nenhuma despesa lançada ainda. Toque em \"Nova despesa\" para começar.")
                                .font(.inter(13, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .padding(.vertical, 12)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(store.groups[idx].comandaItems.indices, id: \.self) { itemIdx in
                                    let item = store.groups[idx].comandaItems[itemIdx]
                                    Button {
                                        store.groups[idx].comandaItems[itemIdx].isSelected.toggle()
                                    } label: {
                                        HStack {
                                            Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 19, weight: .regular))
                                                .foregroundColor(item.isSelected ? JuntoColors.primary : JuntoColors.textLight)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.name)
                                                    .font(.inter(14, weight: .regular))
                                                    .foregroundColor(JuntoColors.textMain)
                                                Text(item.detail)
                                                    .font(.inter(12, weight: .regular))
                                                    .foregroundColor(JuntoColors.textMuted)
                                            }
                                            Spacer()
                                            Text(JuntoStore.formatBRL(item.price))
                                                .font(.inter(14, weight: .medium))
                                                .foregroundColor(JuntoColors.textMain)
                                        }
                                        .padding(.vertical, 12)
                                    }
                                    Divider()
                                }
                            }

                            if selectedTotal > 0 {
                                JuntoPillButton(title: "Pagar \(JuntoStore.formatBRL(selectedTotal)) via Pix", color: JuntoColors.pixGreen) {
                                    dismiss()
                                    store.openPixPayment(title: group.title, recipient: group.title, amount: selectedTotal)
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(Color.white)
        }
    }
}
