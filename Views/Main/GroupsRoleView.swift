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

                                    if group.hasCollectivePot && group.potTarget > 0 {
                                        Text("Pote: \(JuntoStore.formatBRL(group.potBalance)) de \(JuntoStore.formatBRL(group.potTarget))")
                                            .font(.inter(13, weight: .regular))
                                            .foregroundColor(JuntoColors.pixGreen)
                                    } else {
                                        Text("\(group.category) · \(group.participants.count) pessoas")
                                            .font(.inter(13, weight: .regular))
                                            .foregroundColor(JuntoColors.textMuted)
                                    }

                                    if group.myShare > 0 {
                                        Text("Sua parte extra: \(JuntoStore.formatBRL(group.myShare))")
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

// MARK: - Tela "Criar um grupo" com Pote Coletivo Automático + Mais Categorias + Categoria Personalizada
struct CreateGroupScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    var initialType: String = "Viagem"
    var onCreated: ((UUID) -> Void)? = nil

    @State private var groupName: String = ""
    @State private var selectedType: String = "Viagem"
    @State private var showCustomCategoryInput: Bool = false
    @State private var customCategoryText: String = ""

    @State private var enableCollectivePot: Bool = true
    @State private var potTotalText: String = "300"
    @State private var selectedPeople: [SearchableUser] = []
    @State private var quickAddHandle: String = ""

    private let builtInCategories: [(name: String, icon: String)] = [
        ("Viagem", "airplane"),
        ("Churrasco", "flame"),
        ("Bar & Drinks", "wineglass"),
        ("Casa", "house"),
        ("Casal", "heart"),
        ("Festa", "party.popper"),
        ("Esporte", "figure.run"),
        ("Presente", "gift"),
        ("Trabalho", "briefcase")
    ]

    private var potTotalValue: Double {
        let normalized = potTotalText
            .replacingOccurrences(of: "R$", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        return Double(normalized) ?? 0
    }

    private var totalPeopleCount: Int {
        1 + selectedPeople.count // Você + pessoas adicionadas
    }

    private var quotaPerPerson: Double {
        guard potTotalValue > 0 else { return 0 }
        return potTotalValue / Double(totalPeopleCount)
    }

    private var finalCategory: String {
        let custom = customCategoryText.trimmingCharacters(in: .whitespacesAndNewlines)
        if showCustomCategoryInput && !custom.isEmpty {
            return custom
        }
        return selectedType
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Topo: X | Criar um grupo | ✓
            HStack {
                CircleNavButton(icon: "xmark") { dismiss() }
                Spacer()
                Text("Criar um grupo")
                    .font(.inter(17, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                CircleNavButton(icon: "checkmark", bgColor: JuntoColors.primary, fgColor: .white) {
                    handleCreate()
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 14)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // Foto + Nome do grupo
                    HStack(alignment: .center, spacing: 16) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(JuntoColors.surfaceSubtle)
                            .frame(width: 60, height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                                    .foregroundColor(JuntoColors.textLight)
                            )
                            .overlay(
                                Image(systemName: "camera")
                                    .font(.system(size: 19, weight: .regular))
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

                    // Categorias (9 prontas + botão "+ Sua categoria")
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Categoria")
                            .font(.inter(14, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(builtInCategories, id: \.name) { item in
                                    let isSelected = !showCustomCategoryInput && selectedType == item.name
                                    Button {
                                        showCustomCategoryInput = false
                                        selectedType = item.name
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: item.icon)
                                                .font(.system(size: 20, weight: .light))
                                                .foregroundColor(isSelected ? JuntoColors.primary : JuntoColors.textMain)
                                            Text(item.name)
                                                .font(.inter(12, weight: .regular))
                                                .foregroundColor(isSelected ? JuntoColors.primary : JuntoColors.textMain)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 86, height: 74)
                                        .background(isSelected ? JuntoColors.primaryLight : Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(isSelected ? JuntoColors.primary : JuntoColors.border, lineWidth: isSelected ? 1.4 : 1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }

                                // Botão para o usuário criar a própria categoria
                                Button {
                                    withAnimation { showCustomCategoryInput.toggle() }
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 20, weight: .regular))
                                            .foregroundColor(showCustomCategoryInput ? .white : JuntoColors.primary)
                                        Text("Nova")
                                            .font(.inter(12, weight: .medium))
                                            .foregroundColor(showCustomCategoryInput ? .white : JuntoColors.primary)
                                    }
                                    .frame(width: 78, height: 74)
                                    .background(showCustomCategoryInput ? JuntoColors.primary : JuntoColors.warmBg)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                                            .foregroundColor(JuntoColors.primary)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }

                        if showCustomCategoryInput {
                            CleanOutlineInput(
                                label: "Sua categoria personalizada",
                                placeholder: "Ex: Futebol, Aniversário, Faculdade...",
                                text: $customCategoryText
                            )
                        }
                    }

                    // Pote Coletivo: Valor + Pessoas + Cálculo Automático!
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle(isOn: $enableCollectivePot) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Ativar Pote Coletivo")
                                    .font(.inter(15, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                                Text("Coloque o valor e o sistema divide automaticamente entre todos.")
                                    .font(.inter(12, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                            }
                        }
                        .tint(JuntoColors.primary)

                        if enableCollectivePot {
                            CleanOutlineInput(
                                label: "Valor total do Pote (R$)",
                                placeholder: "Ex: 400",
                                text: $potTotalText,
                                keyboardType: .decimalPad,
                                leadingPrefix: "R$"
                            )
                        }

                        // Adicionar pessoas ao grupo
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Adicionar pessoas (\(totalPeopleCount) no total)")
                                .font(.inter(14, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)

                            // Seus amigos para selecionar com 1 toque
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(store.friends) { friend in
                                        let isIncluded = selectedPeople.contains(where: { $0.username == friend.username })
                                        Button {
                                            togglePerson(SearchableUser(name: friend.name, username: friend.username))
                                        } label: {
                                            HStack(spacing: 6) {
                                                GeometricAvatarView(seed: friend.username, size: 26)
                                                Text(friend.name.split(separator: " ").first.map(String.init) ?? friend.name)
                                                    .font(.inter(13, weight: .regular))
                                                    .foregroundColor(isIncluded ? .white : JuntoColors.textMain)
                                                Image(systemName: isIncluded ? "checkmark" : "plus")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(isIncluded ? .white : JuntoColors.textMuted)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 7)
                                            .background(isIncluded ? JuntoColors.primary : JuntoColors.surfaceSubtle)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                }
                            }

                            // Ou adicionar qualquer @usuário digitando
                            HStack(spacing: 8) {
                                CleanOutlineInput(
                                    label: "",
                                    placeholder: "Adicionar outro @usuário",
                                    text: $quickAddHandle,
                                    autocapitalization: .never,
                                    leadingPrefix: "@"
                                )
                                Button("Incluir") {
                                    let clean = quickAddHandle.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "").lowercased()
                                    guard clean.count >= 2 else { return }
                                    let display = store.directoryUsers.first(where: { $0.username == clean })?.name
                                        ?? clean.split(separator: ".").map { $0.capitalized }.joined(separator: " ")
                                    togglePerson(SearchableUser(name: display, username: clean), forceAdd: true)
                                    quickAddHandle = ""
                                }
                                .font(.inter(13, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(JuntoColors.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }

                        // Prévia do Cálculo Automático do Pote!
                        if enableCollectivePot && potTotalValue > 0 {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Divisão automática do Pote")
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                    Text("\(JuntoStore.formatBRL(potTotalValue)) ÷ \(totalPeopleCount) pessoa(s)")
                                        .font(.inter(13, weight: .regular))
                                        .foregroundColor(JuntoColors.textMain)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(JuntoStore.formatBRL(quotaPerPerson))
                                        .font(.inter(20, weight: .medium))
                                        .foregroundColor(JuntoColors.pixGreen)
                                    Text("por pessoa")
                                        .font(.inter(11, weight: .regular))
                                        .foregroundColor(JuntoColors.pixGreen)
                                }
                            }
                            .padding(14)
                            .background(JuntoColors.pixGreenLight)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(JuntoColors.pixGreen.opacity(0.3), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    JuntoPillButton(title: "Criar grupo e distribuir cotas", color: JuntoColors.primary) {
                        handleCreate()
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            selectedType = initialType
        }
    }

    private func togglePerson(_ person: SearchableUser, forceAdd: Bool = false) {
        if let idx = selectedPeople.firstIndex(where: { $0.username == person.username }) {
            if !forceAdd { selectedPeople.remove(at: idx) }
        } else {
            selectedPeople.append(person)
        }
    }

    private func handleCreate() {
        let clean = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            store.showToast("Informe o nome do grupo.", icon: "exclamationmark.circle")
            return
        }
        store.createNewGroup(
            title: clean,
            category: finalCategory,
            hasPot: enableCollectivePot,
            potTarget: enableCollectivePot ? potTotalValue : 0,
            invitedPeople: selectedPeople
        )
        let createdId = store.groups.first?.id
        dismiss()
        if let cid = createdId {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onCreated?(cid)
            }
        }
    }
}

// MARK: - Detalhe do Grupo 100% Funcional (Cotas Automáticas do Pote + Despesas + Membros + Pix)
struct GroupDetailSheet: View {
    @EnvironmentObject var store: JuntoStore
    let groupId: UUID
    @Environment(\.dismiss) private var dismiss

    @State private var showAddExpenseForm = false
    @State private var expenseName = ""
    @State private var expenseAmount = ""
    @State private var payFromPot = false

    @State private var showAddMemberScreen = false
    @State private var selectedParticipantForAction: GroupParticipant? = nil

    private var groupIndex: Int? {
        store.groups.firstIndex(where: { $0.id == groupId })
    }

    var body: some View {
        if let idx = groupIndex {
            let group = store.groups[idx]
            let selectedTotal = group.comandaItems.filter { $0.isSelected }.reduce(0) { $0 + $1.price }
            let canAddExpenses = store.canCurrentUserAddExpenses(in: group)

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

                    // Capa do grupo
                    ZStack(alignment: .bottomLeading) {
                        Image(group.coverImageName)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 140)
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
                            Text("\(group.participants.count) pessoa(s)")
                                .font(.inter(12, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(14)
                    }
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    // Lista de participantes rolável para o lado (ao clicar: Tornar admin / Remover)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Participantes (\(group.participants.count))")
                                .font(.inter(14, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                            Spacer()
                            Button {
                                showAddMemberScreen = true
                            } label: {
                                Label("Adicionar membro", systemImage: "person.badge.plus")
                                    .font(.inter(12, weight: .medium))
                                    .foregroundColor(JuntoColors.primary)
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(group.participants) { participant in
                                    Button {
                                        if participant.role != .owner {
                                            selectedParticipantForAction = participant
                                        }
                                    } label: {
                                        VStack(spacing: 5) {
                                            ZStack(alignment: .bottomTrailing) {
                                                GeometricAvatarView(seed: participant.username, size: 48)
                                                if participant.role == .owner || participant.role == .admin {
                                                    Image(systemName: participant.role == .owner ? "crown.fill" : "checkmark.shield.fill")
                                                        .font(.system(size: 10))
                                                        .foregroundColor(.white)
                                                        .frame(width: 18, height: 18)
                                                        .background(participant.role == .owner ? JuntoColors.primary : JuntoColors.accent)
                                                        .clipShape(Circle())
                                                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                                }
                                            }

                                            Text(participant.name.split(separator: " ").first.map(String.init) ?? participant.name)
                                                .font(.inter(12, weight: .regular))
                                                .foregroundColor(JuntoColors.textMain)
                                                .lineLimit(1)

                                            if participant.role != .member {
                                                Text(participant.role.rawValue)
                                                    .font(.inter(10, weight: .medium))
                                                    .foregroundColor(participant.role == .owner ? JuntoColors.primary : JuntoColors.orangeSave)
                                            }
                                        }
                                        .frame(width: 62)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }

                        Text("Toque em um participante para tornar admin ou remover.")
                            .font(.inter(11, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                    }

                    // POTE COLETIVO + COTAS DISTRIBUÍDAS POR PARTICIPANTE
                    if group.hasCollectivePot {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 8) {
                                JuntoPotIcon(size: 22)
                                Text("Pote Coletivo")
                                    .font(.inter(15, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                                Spacer()
                                Text("\(JuntoStore.formatBRL(group.potBalance)) / \(JuntoStore.formatBRL(group.potTarget))")
                                    .font(.inter(14, weight: .medium))
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
                                .frame(height: 7)
                            }

                            // Lista automática de quanto cada participante precisa pagar no Pote
                            VStack(spacing: 0) {
                                ForEach(group.participants) { participant in
                                    HStack(spacing: 10) {
                                        GeometricAvatarView(seed: participant.username, size: 36)

                                        VStack(alignment: .leading, spacing: 1) {
                                            HStack(spacing: 5) {
                                                Text(participant.name)
                                                    .font(.inter(14, weight: .regular))
                                                    .foregroundColor(JuntoColors.textMain)
                                                if participant.role != .member {
                                                    Text(participant.role.rawValue)
                                                        .font(.inter(10, weight: .medium))
                                                        .foregroundColor(participant.role == .owner ? JuntoColors.primary : JuntoColors.orangeSave)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(participant.role == .owner ? JuntoColors.primaryLight : JuntoColors.accentLight)
                                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                                }
                                            }
                                            Text("Cota: \(JuntoStore.formatBRL(participant.quotaAmount))")
                                                .font(.inter(12, weight: .regular))
                                                .foregroundColor(JuntoColors.textMuted)
                                        }

                                        Spacer()

                                        if participant.hasPaid {
                                            Text("Pago")
                                                .font(.inter(12, weight: .medium))
                                                .foregroundColor(JuntoColors.pixGreen)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(JuntoColors.pixGreenLight)
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                        } else {
                                            Button(participant.name == "Você" ? "Pagar Pix" : "Confirmar") {
                                                let isMe = participant.name == "Você"
                                                if isMe { dismiss() }
                                                store.payParticipantPotQuota(
                                                    groupId: groupId,
                                                    participantId: participant.id,
                                                    openPix: isMe
                                                )
                                            }
                                            .font(.inter(12, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(participant.name == "Você" ? JuntoColors.primary : JuntoColors.orangeSave)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    Divider()
                                }
                            }
                        }
                        .padding(16)
                        .background(JuntoColors.warmBg)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Despesas / Comanda do Grupo (somente Dono ou Admin podem adicionar novas despesas)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Despesas do grupo")
                                .font(.inter(15, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                            Spacer()
                            if canAddExpenses {
                                Button {
                                    withAnimation { showAddExpenseForm.toggle() }
                                } label: {
                                    Label(showAddExpenseForm ? "Cancelar" : "Nova despesa", systemImage: showAddExpenseForm ? "xmark" : "plus")
                                        .font(.inter(13, weight: .medium))
                                        .foregroundColor(JuntoColors.primary)
                                }
                            } else {
                                Text("Somente dono/admins")
                                    .font(.inter(11, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                            }
                        }

                        if canAddExpenses && showAddExpenseForm {
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
            .fullScreenCover(isPresented: $showAddMemberScreen) {
                AddGroupMemberScreen(groupId: groupId)
                    .environmentObject(store)
            }
            .confirmationDialog(
                selectedParticipantForAction?.name ?? "Participante",
                isPresented: Binding(
                    get: { selectedParticipantForAction != nil },
                    set: { if !$0 { selectedParticipantForAction = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let p = selectedParticipantForAction {
                    Button(p.role == .admin ? "Remover permissão de admin" : "Tornar admin") {
                        store.toggleParticipantAdmin(groupId: groupId, participantId: p.id)
                    }
                    Button("Remover do grupo", role: .destructive) {
                        store.removeParticipantFromGroup(groupId: groupId, participantId: p.id)
                    }
                    Button("Cancelar", role: .cancel) {}
                }
            }
        }
    }
}

// MARK: - Tela dedicada "Adicionar membro" listando os amigos já adicionados
struct AddGroupMemberScreen: View {
    @EnvironmentObject var store: JuntoStore
    let groupId: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var currentGroup: RoleGroup? {
        store.groups.first(where: { $0.id == groupId })
    }

    private var filteredFriends: [FriendItem] {
        let base = store.friends
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty { return base }
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                CircleNavButton(icon: "chevron.left") { dismiss() }
                Spacer()
                Text("Adicionar membro")
                    .font(.inter(17, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Spacer().frame(width: 44)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 16)

            CleanOutlineInput(
                label: "",
                placeholder: "Buscar entre seus amigos...",
                text: $searchText,
                autocapitalization: .never
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            Divider().opacity(0.6)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(filteredFriends) { friend in
                        let alreadyInGroup = currentGroup?.participants.contains(where: {
                            $0.username.lowercased() == friend.username.lowercased()
                        }) ?? false

                        HStack(spacing: 12) {
                            GeometricAvatarView(seed: friend.username, size: 46)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(friend.name)
                                    .font(.inter(15, weight: .regular))
                                    .foregroundColor(JuntoColors.textMain)
                                Text("@\(friend.username)")
                                    .font(.inter(12, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                            }

                            Spacer()

                            Button {
                                guard !alreadyInGroup else { return }
                                store.addMemberToGroup(groupId: groupId, memberUsername: friend.username)
                            } label: {
                                Text(alreadyInGroup ? "No grupo" : "Adicionar")
                                    .font(.inter(13, weight: .medium))
                                    .foregroundColor(alreadyInGroup ? JuntoColors.textMuted : .white)
                                    .padding(.horizontal, 14)
                                    .frame(height: 36)
                                    .background(alreadyInGroup ? JuntoColors.surfaceSubtle : JuntoColors.primary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(alreadyInGroup ? JuntoColors.border : Color.clear, lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .disabled(alreadyInGroup)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                        Divider().padding(.leading, 78)
                    }
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}
