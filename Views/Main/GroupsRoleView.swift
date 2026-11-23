import SwiftUI
import PhotosUI

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
                            HStack(spacing: 12) {
                                groupCoverImage(group)
                                    .frame(width: 54, height: 54)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(group.title)
                                            .font(.inter(15, weight: .medium))
                                            .foregroundColor(JuntoColors.textMain)
                                            .lineLimit(1)
                                            .truncationMode(.tail)

                                        if group.hasCollectivePot && group.potTarget > 0 {
                                            let pct = Int(min((group.potBalance / group.potTarget) * 100, 100))
                                            Text("\(pct)%")
                                                .font(.inter(11, weight: .medium))
                                                .foregroundColor(JuntoColors.pixGreen)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(JuntoColors.pixGreenLight)
                                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                        }
                                    }

                                    if group.hasCollectivePot && group.potTarget > 0 {
                                        Text("\(JuntoStore.formatBRL(group.potBalance)) de \(JuntoStore.formatBRL(group.potTarget))")
                                            .font(.inter(13, weight: .regular))
                                            .foregroundColor(JuntoColors.textMuted)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.85)
                                    } else {
                                        Text("\(group.category) · \(group.participants.count) pessoas")
                                            .font(.inter(13, weight: .regular))
                                            .foregroundColor(JuntoColors.textMuted)
                                            .lineLimit(1)
                                    }

                                    if group.myShare > 0 {
                                        Text("Sua parte: \(JuntoStore.formatBRL(group.myShare))")
                                            .font(.inter(12, weight: .regular))
                                            .foregroundColor(JuntoColors.orangeSave)
                                            .lineLimit(1)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(JuntoColors.textLight)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
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

    @ViewBuilder
    private func groupCoverImage(_ group: RoleGroup) -> some View {
        if let data = group.coverImageData, let uiImg = UIImage(data: data) {
            Image(uiImage: uiImg)
                .resizable()
                .scaledToFill()
        } else {
            Image(group.coverImageName)
                .resizable()
                .scaledToFill()
        }
    }
}

// MARK: - Tela "Criar um grupo" (Imagem real via PhotosPicker + Pote sempre automático + Tela de amigos)
struct CreateGroupScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    var initialType: String = "Viagem"
    var onCreated: ((UUID) -> Void)? = nil

    @State private var groupName: String = ""
    @State private var selectedType: String = "Viagem"
    @State private var showCustomCategoryInput: Bool = false
    @State private var customCategoryText: String = ""

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var coverImageData: Data? = nil

    @State private var potTotalText: String = "300"
    @State private var startDate: Date = Date()
    @State private var targetDate: Date = Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date()
    @State private var selectedPeople: [SearchableUser] = []
    @State private var showSelectFriendsScreen: Bool = false

    private let builtInCategories: [(name: String, icon: String)] = [
        ("Viagem", "airplane.departure"),
        ("Churrasco", "fork.knife"),
        ("Bar & Drinks", "mug"),
        ("Casa", "house"),
        ("Casal", "heart"),
        ("Festa", "sparkles"),
        ("Esporte", "sportscourt"),
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
        1 + selectedPeople.count
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
                    // Foto do grupo (PhotosPicker real!) + Nome do grupo
                    HStack(alignment: .center, spacing: 16) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Group {
                                if let data = coverImageData, let uiImg = UIImage(data: data) {
                                    Image(uiImage: uiImg)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 64)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 11))
                                                .foregroundColor(.white)
                                                .padding(5)
                                                .background(JuntoColors.primary)
                                                .clipShape(Circle())
                                                .offset(x: 4, y: 4),
                                            alignment: .bottomTrailing
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(JuntoColors.surfaceSubtle)
                                        .frame(width: 64, height: 64)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                                                .foregroundColor(JuntoColors.textLight)
                                        )
                                        .overlay(
                                            VStack(spacing: 3) {
                                                Image(systemName: "photo.badge.plus")
                                                    .font(.system(size: 18, weight: .regular))
                                                    .foregroundColor(JuntoColors.primary)
                                                Text("Foto")
                                                    .font(.inter(10, weight: .regular))
                                                    .foregroundColor(JuntoColors.textMuted)
                                            }
                                        )
                                }
                            }
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    coverImageData = data
                                }
                            }
                        }

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

                    // Categorias (9 prontas + botão "+ Nova")
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

                    // Pote Coletivo SEMPRE AUTOMÁTICO (sem toggle)
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 10) {
                            JuntoPotIcon(size: 34)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pote Coletivo")
                                    .font(.inter(15, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                                Text("O sistema divide o valor automaticamente entre os membros.")
                                    .font(.inter(12, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                            }
                        }

                        CleanOutlineInput(
                            label: "Valor total do Pote (R$)",
                            placeholder: "Ex: 400",
                            text: $potTotalText,
                            keyboardType: .decimalPad,
                            leadingPrefix: "R$"
                        )

                        // Data de início e Meta até o dia (linhas empilhadas nativas iOS — nunca desconfigura!)
                        VStack(spacing: 0) {
                            HStack {
                                Label("Data de início", systemImage: "calendar")
                                    .font(.inter(14, weight: .regular))
                                    .foregroundColor(JuntoColors.textMain)
                                Spacer()
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .environment(\.locale, Locale(identifier: "pt_BR"))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)

                            Divider().padding(.leading, 14)

                            HStack {
                                Label("Meta até o dia", systemImage: "flag")
                                    .font(.inter(14, weight: .regular))
                                    .foregroundColor(JuntoColors.textMain)
                                Spacer()
                                DatePicker("", selection: $targetDate, in: startDate..., displayedComponents: .date)
                                    .labelsHidden()
                                    .environment(\.locale, Locale(identifier: "pt_BR"))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                        }
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 11).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 11))

                        // Botão "Adicionar membros" -> abre tela com a lista de amigos!
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Membros (\(totalPeopleCount))")
                                    .font(.inter(14, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                                Spacer()
                                Button {
                                    showSelectFriendsScreen = true
                                } label: {
                                    Label("Adicionar membros", systemImage: "person.badge.plus")
                                        .font(.inter(13, weight: .medium))
                                        .foregroundColor(JuntoColors.primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(JuntoColors.primaryLight)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }

                            if !selectedPeople.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(selectedPeople) { person in
                                            HStack(spacing: 6) {
                                                GeometricAvatarView(seed: person.username, size: 24)
                                                Text(person.name.split(separator: " ").first.map(String.init) ?? person.name)
                                                    .font(.inter(13, weight: .regular))
                                                    .foregroundColor(JuntoColors.textMain)
                                                Button {
                                                    selectedPeople.removeAll { $0.username == person.username }
                                                } label: {
                                                    Image(systemName: "xmark")
                                                        .font(.system(size: 10, weight: .medium))
                                                        .foregroundColor(JuntoColors.textMuted)
                                                }
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(JuntoColors.surfaceSubtle)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                }
                            }
                        }

                        // Cálculo automático ao vivo
                        if potTotalValue > 0 {
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
        .fullScreenCover(isPresented: $showSelectFriendsScreen) {
            SelectFriendsForGroupScreen(selectedPeople: $selectedPeople)
                .environmentObject(store)
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
            hasPot: true,
            potTarget: potTotalValue,
            invitedPeople: selectedPeople,
            coverImageData: coverImageData,
            startDate: startDate,
            targetDate: targetDate
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

// MARK: - Tela de Seleção de Amigos ao Criar Grupo
struct SelectFriendsForGroupScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Binding var selectedPeople: [SearchableUser]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredFriends: [FriendItem] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty { return store.friends }
        return store.friends.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                CircleNavButton(icon: "chevron.left") { dismiss() }
                Spacer()
                Text("Adicionar membros")
                    .font(.inter(17, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Button("Pronto") { dismiss() }
                    .font(.inter(15, weight: .medium))
                    .foregroundColor(JuntoColors.primary)
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
                        let isAdded = selectedPeople.contains(where: { $0.username == friend.username })

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
                                if isAdded {
                                    selectedPeople.removeAll { $0.username == friend.username }
                                } else {
                                    selectedPeople.append(SearchableUser(name: friend.name, username: friend.username))
                                }
                            } label: {
                                Text(isAdded ? "Adicionado" : "Adicionar")
                                    .font(.inter(13, weight: .medium))
                                    .foregroundColor(isAdded ? JuntoColors.textMain : .white)
                                    .padding(.horizontal, 14)
                                    .frame(height: 36)
                                    .background(isAdded ? JuntoColors.surfaceSubtle : JuntoColors.primary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isAdded ? JuntoColors.border : Color.clear, lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
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

// MARK: - Detalhe do Grupo 100% Funcional (Porcentagem aprimorada + Sheet customizado claro de Admin/Remover)
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
    @State private var showWithdrawSheet = false
    @State private var pendingPaymentSheet: GroupPaymentRequest? = nil

    struct GroupPaymentRequest: Identifiable {
        let id = UUID()
        let title: String
        let amount: Double
        let participantId: UUID? // se preenchido = cota do pote; se nil = despesas da comanda
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        return f
    }()

    private var groupIndex: Int? {
        store.groups.firstIndex(where: { $0.id == groupId })
    }

    var body: some View {
        if let idx = groupIndex {
            let group = store.groups[idx]
            let selectedTotal = group.comandaItems.filter { $0.isSelected }.reduce(0) { $0 + $1.price }
            let canAddExpenses = store.canCurrentUserAddExpenses(in: group)
            let potPercent = group.potTarget > 0 ? min(Int((group.potBalance / group.potTarget) * 100), 100) : 0
            let paidCount = group.participants.filter { $0.hasPaid }.count

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

                    // Capa do grupo (suporta foto escolhida da galeria!)
                    ZStack(alignment: .bottomLeading) {
                        if let data = group.coverImageData, let uiImg = UIImage(data: data) {
                            Image(uiImage: uiImg)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 145)
                                .clipped()
                        } else {
                            Image(group.coverImageName)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 145)
                                .clipped()
                        }

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
                    .frame(height: 145)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    // Lista de participantes rolável para o lado (toque abre Sheet claro customizado!)
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

                        Text("Toque em um participante para gerenciar admin ou remover.")
                            .font(.inter(11, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                    }

                    // POTE COLETIVO COM PORCENTAGEM APRIMORADA
                    if group.hasCollectivePot {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 10) {
                                JuntoPotIcon(size: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Pote Coletivo")
                                        .font(.inter(15, weight: .medium))
                                        .foregroundColor(JuntoColors.textMain)
                                    Text("\(paidCount) de \(group.participants.count) pagaram")
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                }
                                Spacer()
                                Text("\(potPercent)%")
                                    .font(.inter(14, weight: .medium))
                                    .foregroundColor(JuntoColors.pixGreen)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(JuntoColors.pixGreenLight)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            if group.potTarget > 0 {
                                VStack(spacing: 6) {
                                    GeometryReader { geo in
                                        let ratio = min(group.potBalance / group.potTarget, 1.0)
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 6).fill(JuntoColors.border.opacity(0.7))
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [JuntoColors.pixGreen, Color(hex: "#10B981")],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: max(geo.size.width * ratio, ratio > 0 ? 12 : 0))
                                        }
                                    }
                                    .frame(height: 10)

                                    HStack {
                                        Text("Arrecadado: \(JuntoStore.formatBRL(group.potBalance))")
                                            .font(.inter(12, weight: .medium))
                                            .foregroundColor(JuntoColors.textMain)
                                        Spacer()
                                        Text("Meta: \(JuntoStore.formatBRL(group.potTarget))")
                                            .font(.inter(12, weight: .regular))
                                            .foregroundColor(JuntoColors.textMuted)
                                    }

                                    HStack(spacing: 12) {
                                        Label("Início: \(Self.dateFormatter.string(from: group.startDate))", systemImage: "calendar")
                                        Spacer()
                                        Label("Meta até: \(Self.dateFormatter.string(from: group.targetDate))", systemImage: "flag")
                                    }
                                    .font(.inter(11, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                    .padding(.top, 2)
                                }
                            }

                            // Botão de Saque via Pix (sem mencionar EFI — exclusivo para o responsável/dono do grupo)
                            if store.isCurrentUserOwner(in: group) && group.potBalance > 0 {
                                JuntoPillButton(
                                    title: "Sacar \(JuntoStore.formatBRL(group.potBalance))",
                                    icon: "arrow.up.right.circle",
                                    color: JuntoColors.primary
                                ) {
                                    showWithdrawSheet = true
                                }
                            }

                            // Lista automática de cotas
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
                                            Button(participant.name == "Você" ? "Pagar" : "Confirmar") {
                                                if participant.name == "Você" {
                                                    pendingPaymentSheet = GroupPaymentRequest(
                                                        title: "Cota do Pote • \(group.title)",
                                                        amount: participant.quotaAmount,
                                                        participantId: participant.id
                                                    )
                                                } else {
                                                    store.payParticipantPotQuota(
                                                        groupId: groupId,
                                                        participantId: participant.id,
                                                        openPix: false
                                                    )
                                                }
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

                    // Despesas / Comanda do Grupo (somente Dono ou Admin)
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
                            Text("Nenhuma despesa lançada ainda.")
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
                                JuntoPillButton(title: "Pagar \(JuntoStore.formatBRL(selectedTotal))", color: JuntoColors.pixGreen) {
                                    pendingPaymentSheet = GroupPaymentRequest(
                                        title: "Despesas • \(group.title)",
                                        amount: selectedTotal,
                                        participantId: nil
                                    )
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
            // Sheet customizado claro na paleta do sistema (sem popup padrão do iOS!)
            .sheet(item: $selectedParticipantForAction) { participant in
                ParticipantActionSheet(
                    participant: participant,
                    onToggleAdmin: {
                        store.toggleParticipantAdmin(groupId: groupId, participantId: participant.id)
                        selectedParticipantForAction = nil
                    },
                    onRemove: {
                        store.removeParticipantFromGroup(groupId: groupId, participantId: participant.id)
                        selectedParticipantForAction = nil
                    }
                )
                .presentationDetents([.height(270)])
                .presentationCornerRadius(20)
            }
            .sheet(isPresented: $showWithdrawSheet) {
                PotWithdrawSheet(
                    groupTitle: group.title,
                    availableAmount: group.potBalance,
                    pixKey: store.user.pixKey
                ) { amountToWithdraw in
                    store.withdrawPotViaEfi(groupId: groupId, amount: amountToWithdraw)
                }
                .presentationDetents([.height(390)])
                .presentationCornerRadius(20)
            }
            .sheet(item: $pendingPaymentSheet) { request in
                GroupPaymentMethodSheet(
                    title: request.title,
                    amount: request.amount,
                    walletBalance: store.walletBalance,
                    onPayWithWallet: {
                        if let pid = request.participantId {
                            _ = store.payParticipantPotQuotaWithWallet(groupId: groupId, participantId: pid)
                        } else {
                            _ = store.payGroupExpensesWithWallet(groupId: groupId, amount: request.amount)
                        }
                        pendingPaymentSheet = nil
                    },
                    onPayWithPix: {
                        pendingPaymentSheet = nil
                        dismiss()
                        if let pid = request.participantId {
                            store.payParticipantPotQuota(groupId: groupId, participantId: pid, openPix: true)
                        } else {
                            store.openPixPayment(title: request.title, recipient: group.title, amount: request.amount)
                        }
                    }
                )
                .presentationDetents([.height(310)])
                .presentationCornerRadius(20)
            }
        }
    }
}

// MARK: - Sheet de Escolha de Pagamento do Grupo (Saldo da Carteira OU Pix)
struct GroupPaymentMethodSheet: View {
    let title: String
    let amount: Double
    let walletBalance: Double
    let onPayWithWallet: () -> Void
    let onPayWithPix: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var hasEnoughBalance: Bool {
        walletBalance >= amount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Como deseja pagar?")
                        .font(.inter(18, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Text("\(title) · \(JuntoStore.formatBRL(amount))")
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                        .lineLimit(1)
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
                // Opção 1: Carteira Juntô
                Button(action: onPayWithWallet) {
                    HStack(spacing: 12) {
                        Image(systemName: "wallet.pass.fill")
                            .font(.system(size: 18))
                            .foregroundColor(hasEnoughBalance ? JuntoColors.primary : JuntoColors.textLight)
                            .frame(width: 36, height: 36)
                            .background(hasEnoughBalance ? JuntoColors.primaryLight : JuntoColors.surfaceSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Saldo da Carteira")
                                .font(.inter(15, weight: .medium))
                                .foregroundColor(hasEnoughBalance ? JuntoColors.textMain : JuntoColors.textMuted)
                            Text(
                                hasEnoughBalance
                                    ? "Disponível: \(JuntoStore.formatBRL(walletBalance))"
                                    : "Saldo insuficiente (\(JuntoStore.formatBRL(walletBalance)))"
                            )
                            .font(.inter(12, weight: .regular))
                            .foregroundColor(hasEnoughBalance ? JuntoColors.pixGreen : JuntoColors.danger)
                        }

                        Spacer()

                        if hasEnoughBalance {
                            Text("Pagar")
                                .font(.inter(13, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(JuntoColors.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                        }
                    }
                    .padding(14)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(hasEnoughBalance ? JuntoColors.primary.opacity(0.35) : JuntoColors.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!hasEnoughBalance)

                // Opção 2: Pix
                Button(action: onPayWithPix) {
                    HStack(spacing: 12) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 18))
                            .foregroundColor(JuntoColors.pixGreen)
                            .frame(width: 36, height: 36)
                            .background(JuntoColors.pixGreenLight)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pagar via Pix")
                                .font(.inter(15, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                            Text("QR Code ou Pix Copia e Cola")
                                .font(.inter(12, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13))
                            .foregroundColor(JuntoColors.textLight)
                    }
                    .padding(14)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(JuntoColors.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(JuntoColors.warmBg.ignoresSafeArea())
    }
}

// MARK: - Tela de Saque do Pote com Animação Premium (sem mencionar EFI)
struct PotWithdrawSheet: View {
    let groupTitle: String
    let availableAmount: Double
    let pixKey: String
    let onConfirm: (Double) -> Void
    @Environment(\.dismiss) private var dismiss

    enum WithdrawState {
        case review
        case processing
        case success
    }

    @State private var state: WithdrawState = .review
    @State private var checkScale: CGFloat = 0.4
    @State private var ringOpacity: Double = 0.0

    var body: some View {
        ZStack {
            JuntoColors.warmBg.ignoresSafeArea()

            switch state {
            case .review:
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        HStack(spacing: 10) {
                            JuntoPotIcon(size: 34)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sacar do Pote")
                                    .font(.inter(17, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                                Text(groupTitle)
                                    .font(.inter(12, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                            }
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

                    // Valor em destaque
                    VStack(spacing: 4) {
                        Text("Valor disponível para saque")
                            .font(.inter(12, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                        Text(JuntoStore.formatBRL(availableAmount))
                            .font(.inter(32, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(JuntoColors.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Destino Pix
                    VStack(spacing: 10) {
                        HStack {
                            Text("Sua chave Pix")
                                .font(.inter(13, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                            Spacer()
                            Text(pixKey)
                                .font(.inter(13, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                                .lineLimit(1)
                        }
                        Divider()
                        HStack {
                            Text("Prazo de envio")
                                .font(.inter(13, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                            Spacer()
                            Text("Pix instantâneo · Sem taxa")
                                .font(.inter(13, weight: .medium))
                                .foregroundColor(JuntoColors.pixGreen)
                        }
                    }
                    .padding(14)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(JuntoColors.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    JuntoPillButton(
                        title: "Confirmar saque",
                        icon: "arrow.up.right.circle",
                        color: JuntoColors.primary
                    ) {
                        startWithdrawAnimation()
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)

            case .processing:
                VStack(spacing: 18) {
                    ProgressView()
                        .scaleEffect(1.3)
                        .tint(JuntoColors.primary)
                    Text("Transferindo via Pix...")
                        .font(.inter(17, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Text("Enviando \(JuntoStore.formatBRL(availableAmount)) para \(pixKey)")
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(24)

            case .success:
                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .stroke(JuntoColors.pixGreen.opacity(0.25), lineWidth: 12)
                            .frame(width: 96, height: 96)
                            .scaleEffect(checkScale * 1.15)
                            .opacity(ringOpacity)

                        Circle()
                            .fill(JuntoColors.pixGreen)
                            .frame(width: 78, height: 78)
                            .scaleEffect(checkScale)

                        Image(systemName: "checkmark")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundColor(.white)
                            .scaleEffect(checkScale)
                    }

                    VStack(spacing: 6) {
                        Text("Saque realizado!")
                            .font(.inter(22, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)

                        Text("\(JuntoStore.formatBRL(availableAmount)) enviado via Pix para \(pixKey)")
                            .font(.inter(14, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                            .multilineTextAlignment(.center)
                    }

                    JuntoPillButton(title: "Concluir", color: JuntoColors.primary) {
                        dismiss()
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func startWithdrawAnimation() {
        withAnimation(.easeInOut(duration: 0.2)) {
            state = .processing
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            onConfirm(availableAmount)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                state = .success
                checkScale = 1.0
                ringOpacity = 1.0
            }
        }
    }
}

// MARK: - Sheet Customizado Claro (Gerenciar Participante: Tornar Admin / Remover)
struct ParticipantActionSheet: View {
    let participant: GroupParticipant
    let onToggleAdmin: () -> Void
    let onRemove: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                GeometricAvatarView(seed: participant.username, size: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(participant.name)
                        .font(.inter(16, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Text("@\(participant.username) · \(participant.role.rawValue)")
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
                Button(action: onToggleAdmin) {
                    HStack(spacing: 12) {
                        Image(systemName: participant.role == .admin ? "shield.slash" : "checkmark.shield")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(JuntoColors.primary)
                        Text(participant.role == .admin ? "Remover permissão de admin" : "Tornar admin do grupo")
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

                Button(action: onRemove) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.minus")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(JuntoColors.danger)
                        Text("Remover do grupo")
                            .font(.inter(15, weight: .medium))
                            .foregroundColor(JuntoColors.danger)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(JuntoColors.dangerLight)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(JuntoColors.danger.opacity(0.25), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(JuntoColors.warmBg.ignoresSafeArea())
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
