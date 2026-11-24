import SwiftUI
import PhotosUI
import CoreImage.CIFilterBuiltins

struct GroupsRoleView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var showCreateGroup = false
    @State private var showProPaywall = false
    @State private var selectedGroupId: UUID? = nil
    @State private var searchText = ""

    private var filteredGroups: [RoleGroup] {
        if searchText.isEmpty { return store.groups }
        return store.groups.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Topo: "Grupos" + botão "+" que cria diretamente um novo grupo/viagem/rolê
            HStack {
                Text("Grupos")
                    .font(.inter(24, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Button {
                    if store.canCreateMoreGroups() {
                        showCreateGroup = true
                    } else {
                        store.showToast("Plano gratuito permite 1 grupo. Assine o Juntô Pro para grupos ilimitados.", icon: "lock")
                        showProPaywall = true
                    }
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
                    "Pesquisar Viagem",
                    "Pesquisar Churrasco",
                    "Pesquisar Rolê"
                ]
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            Divider().opacity(0.6)

            if filteredGroups.isEmpty {
                Spacer()
                VStack(spacing: 14) {
                    if searchText.isEmpty {
                        Image(systemName: "person.2")
                            .font(.system(size: 34, weight: .thin))
                            .foregroundColor(JuntoColors.textLight)

                        Text("Nenhum grupo por aqui")
                            .font(.inter(17, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)

                        Text("Crie seu primeiro rolê, viagem ou grupo clicando no botão '+' no topo.")
                            .font(.inter(14, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    } else {
                        Text("Nenhum grupo encontrado.")
                            .font(.inter(15, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                    }
                }
                .frame(maxWidth: .infinity)
                Spacer()
                Spacer().frame(height: 110)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredGroups) { group in
                            Button {
                                selectedGroupId = group.id
                            } label: {
                                HStack(spacing: 12) {
                                    groupCoverImage(group)
                                        .frame(width: 52, height: 52)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Text(group.title)
                                                .font(.inter(15, weight: .medium))
                                                .foregroundColor(JuntoColors.textMain)
                                                .lineLimit(1)
                                                .truncationMode(.tail)

                                            if group.hasCollectivePot && group.potTarget > 0 {
                                                let pct = group.overallGoalPercent
                                                Text("· \(pct)%")
                                                    .font(.inter(12, weight: .medium))
                                                    .foregroundColor(JuntoColors.pixGreen)
                                            }
                                        }

                                        if group.potMode == .monthly && group.potTarget > 0 {
                                            let mIdx = min(max(0, group.selectedMonthIndex), max(0, group.monthlyCycles.count - 1))
                                            let mPct = group.monthCompletionPercent(at: mIdx)
                                            let mLabel = group.monthlyCycles.indices.contains(mIdx) ? group.monthlyCycles[mIdx].label : "Mês \(mIdx + 1)"
                                            Text("\(mLabel): \(mPct)% · Meta: \(JuntoStore.formatBRL(group.potBalance)) de \(JuntoStore.formatBRL(group.potTarget))")
                                                .font(.inter(12, weight: .regular))
                                                .foregroundColor(JuntoColors.textMuted)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.85)
                                        } else if group.hasCollectivePot && group.potTarget > 0 {
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

                            Divider().padding(.leading, 86)
                        }
                    }
                    .padding(.bottom, 140)
                }
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
        .fullScreenCover(isPresented: $showProPaywall) {
            JuntoProSubscriptionScreen()
                .environmentObject(store)
        }
        .onAppear {
            if store.openCreateGroupWithCategory != nil {
                if store.canCreateMoreGroups() {
                    showCreateGroup = true
                } else {
                    store.openCreateGroupWithCategory = nil
                    showProPaywall = true
                }
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

// MARK: - Sheet ao clicar em "+" na tela de Grupos (Lista limpa nativa iOS sem retângulos pesados)
struct CreateGroupOrPotChoiceSheet: View {
    let isPro: Bool
    let onSelectGroupPot: () -> Void
    let onSelectPersonalPot: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Criar novo")
                    .font(.inter(17, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(JuntoColors.textMuted)
                        .frame(width: 30, height: 30)
                        .background(JuntoColors.surfaceSubtle)
                        .clipShape(Circle())
                }
            }
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider()

            Button(action: onSelectGroupPot) {
                HStack(spacing: 14) {
                    Image(systemName: "person.2")
                        .font(.system(size: 19, weight: .regular))
                        .foregroundColor(JuntoColors.primary)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Grupo / Pote Coletivo")
                            .font(.inter(15, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                        Text("Para viagens, rolês, excursões mensais ou casa")
                            .font(.inter(12, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundColor(JuntoColors.textLight)
                }
                .padding(.vertical, 16)
            }

            Divider().padding(.leading, 42)

            Button(action: onSelectPersonalPot) {
                HStack(spacing: 14) {
                    Image(systemName: isPro ? "archivebox" : "lock")
                        .font(.system(size: 19, weight: .regular))
                        .foregroundColor(JuntoColors.primary)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Pote Pessoal (Caixinha)")
                                .font(.inter(15, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                            Text("PRO")
                                .font(.inter(9, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(JuntoColors.primary)
                                .clipShape(Capsule())
                        }
                        Text("Guarde finanças individualmente para uma ocasião")
                            .font(.inter(12, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                    }
                    Spacer()
                    Image(systemName: isPro ? "chevron.right" : "lock.fill")
                        .font(.system(size: 13))
                        .foregroundColor(JuntoColors.textLight)
                }
                .padding(.vertical, 16)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color.white.ignoresSafeArea())
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

    @State private var potTotalText: String = ""
    @State private var potMode: PotRecurrenceMode = .single
    @State private var startDate: Date = Date()
    @State private var targetDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var isPublicGroup: Bool = false
    @State private var maxParticipants: Int = 30
    @State private var publicUntilDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var selectedPeople: [SearchableUser] = []
    @State private var showSelectFriendsScreen: Bool = false
    @State private var showReceiptScanner: Bool = false
    @State private var scannedReceiptItems: [ComandaItem] = []

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

    private var calculatedMonthsCount: Int {
        let comps = Calendar.current.dateComponents([.month, .day], from: startDate, to: targetDate)
        let m = comps.month ?? 0
        let d = comps.day ?? 0
        let total = d > 0 ? m + 1 : m
        return max(1, total)
    }

    private var activeMonthsCount: Int {
        potMode == .monthly ? calculatedMonthsCount : 1
    }

    private var quotaPerPerson: Double {
        guard potTotalValue > 0 else { return 0 }
        return (potTotalValue / Double(activeMonthsCount)) / Double(totalPeopleCount)
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

                    // Categorias em pílulas horizontais limpas (sem blocos quadrados grandes)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Categoria")
                            .font(.inter(14, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(builtInCategories, id: \.name) { item in
                                    let isSelected = !showCustomCategoryInput && selectedType == item.name
                                    Button {
                                        showCustomCategoryInput = false
                                        selectedType = item.name
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: item.icon)
                                                .font(.system(size: 14, weight: .regular))
                                            Text(item.name)
                                                .font(.inter(13, weight: .medium))
                                                .lineLimit(1)
                                        }
                                        .foregroundColor(isSelected ? .white : JuntoColors.textMain)
                                        .padding(.horizontal, 14)
                                        .frame(height: 36)
                                        .background(isSelected ? JuntoColors.primary : JuntoColors.surfaceSubtle)
                                        .clipShape(Capsule())
                                    }
                                }

                                Button {
                                    withAnimation { showCustomCategoryInput.toggle() }
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 13, weight: .medium))
                                        Text("Outra")
                                            .font(.inter(13, weight: .medium))
                                    }
                                    .foregroundColor(showCustomCategoryInput ? .white : JuntoColors.primary)
                                    .padding(.horizontal, 14)
                                    .frame(height: 36)
                                    .background(showCustomCategoryInput ? JuntoColors.primary : JuntoColors.surfaceSubtle)
                                    .clipShape(Capsule())
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

                    Divider()

                    // Pote Coletivo / Pote Mensal organizado em formato nativo iOS
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Pote do grupo")
                                .font(.inter(16, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                            Text("Defina uma meta única para o rolê ou parcelas mensais para excursões.")
                                .font(.inter(13, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                        }

                        // Seletor segmentado nativo iOS: Meta única vs Mensal (Excursão)
                        HStack(spacing: 4) {
                            ForEach(PotRecurrenceMode.allCases, id: \.self) { mode in
                                let active = potMode == mode
                                Button {
                                    withAnimation(.easeInOut(duration: 0.16)) { potMode = mode }
                                } label: {
                                    Text(mode.rawValue)
                                        .font(.inter(13, weight: .medium))
                                        .foregroundColor(active ? JuntoColors.textMain : JuntoColors.textMuted)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 34)
                                        .background(active ? Color.white : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                                        .shadow(color: active ? Color.black.opacity(0.06) : .clear, radius: 2, y: 1)
                                }
                            }
                        }
                        .padding(3)
                        .background(JuntoColors.surfaceSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                        HStack(alignment: .bottom, spacing: 10) {
                            CleanOutlineInput(
                                label: "Meta total do Pote (R$)",
                                placeholder: "Ex: 3000",
                                text: $potTotalText,
                                keyboardType: .decimalPad,
                                leadingPrefix: "R$"
                            )

                            Button {
                                showReceiptScanner = true
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "doc.viewfinder")
                                        .font(.system(size: 19, weight: .regular))
                                        .foregroundColor(JuntoColors.primary)
                                    Text("Escanear")
                                        .font(.inter(11, weight: .medium))
                                        .foregroundColor(JuntoColors.primary)
                                }
                                .frame(width: 74, height: 50)
                                .background(JuntoColors.surfaceSubtle)
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 11)
                                        .stroke(JuntoColors.primary.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }

                        if !scannedReceiptItems.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(JuntoColors.pixGreen)
                                        .font(.system(size: 13))
                                    Text("\(scannedReceiptItems.count) itens importados da comanda")
                                        .font(.inter(13, weight: .medium))
                                        .foregroundColor(JuntoColors.textMain)
                                    Spacer()
                                    Button("Limpar") {
                                        scannedReceiptItems = []
                                        potTotalText = ""
                                    }
                                    .font(.inter(12, weight: .regular))
                                    .foregroundColor(JuntoColors.danger)
                                }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(scannedReceiptItems) { itm in
                                            HStack(spacing: 4) {
                                                Text("\(itm.quantity)x \(itm.name)")
                                                    .font(.inter(12, weight: .regular))
                                                    .foregroundColor(JuntoColors.textMain)
                                                Text("• \(JuntoStore.formatBRL(itm.price))")
                                                    .font(.inter(12, weight: .medium))
                                                    .foregroundColor(JuntoColors.primary)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(JuntoColors.surfaceSubtle)
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                            .padding(12)
                            .background(JuntoColors.surfaceSubtle.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        if potMode == .monthly {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Duração calculada pelo período")
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                    Text("\(calculatedMonthsCount) mês(es) de parcelas")
                                        .font(.inter(15, weight: .medium))
                                        .foregroundColor(JuntoColors.primary)
                                }
                                Spacer()
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(JuntoColors.primary)
                            }
                            .padding(12)
                            .background(JuntoColors.surfaceSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }

                        // Data de início e Meta até o dia (linhas limpas nativas iOS que calculam os meses sozinho)
                        VStack(spacing: 0) {
                            Divider()
                            HStack {
                                Label("Data de início", systemImage: "calendar")
                                    .font(.inter(14, weight: .regular))
                                    .foregroundColor(JuntoColors.textMain)
                                Spacer()
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .environment(\.locale, Locale(identifier: "pt_BR"))
                            }
                            .padding(.vertical, 10)

                            Divider()

                            HStack {
                                Label("Meta até o dia", systemImage: "flag")
                                    .font(.inter(14, weight: .regular))
                                    .foregroundColor(JuntoColors.textMain)
                                Spacer()
                                DatePicker("", selection: $targetDate, in: startDate..., displayedComponents: .date)
                                    .labelsHidden()
                                    .environment(\.locale, Locale(identifier: "pt_BR"))
                            }
                            .padding(.vertical, 10)
                            Divider()
                        }

                        // Configuração de Grupo Público (Próximos)
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $isPublicGroup) {
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "globe.americas.fill")
                                            .font(.system(size: 15))
                                            .foregroundColor(isPublicGroup ? JuntoColors.primary : JuntoColors.textMuted)
                                        Text("Grupo Público (Próximos)")
                                            .font(.inter(15, weight: .medium))
                                            .foregroundColor(JuntoColors.textMain)
                                    }
                                    Text("Pessoas da sua cidade ou região podem encontrar e entrar no grupo.")
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                }
                            }
                            .tint(JuntoColors.primary)

                            if isPublicGroup {
                                VStack(alignment: .leading, spacing: 12) {
                                    // Limite de pessoas (até 100)
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text("Limite de vagas")
                                                .font(.inter(13, weight: .regular))
                                                .foregroundColor(JuntoColors.textMain)
                                            Spacer()
                                            Text("\(maxParticipants) pessoas (máx. 100)")
                                                .font(.inter(13, weight: .medium))
                                                .foregroundColor(JuntoColors.primary)
                                        }

                                        Stepper(value: $maxParticipants, in: 2...100, step: 1) {
                                            Text("Vagas: \(maxParticipants)")
                                                .font(.inter(13, weight: .regular))
                                                .foregroundColor(JuntoColors.textMuted)
                                        }
                                        .labelsHidden()

                                        Text("Ao preencher as vagas, o grupo sai da aba pública automaticamente. Se alguém sair, fica disponível novamente.")
                                            .font(.inter(11, weight: .regular))
                                            .foregroundColor(JuntoColors.textMuted)
                                    }
                                    .padding(12)
                                    .background(JuntoColors.surfaceSubtle)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                    // Fica no ar até o dia
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Fica no ar até o dia")
                                                .font(.inter(13, weight: .regular))
                                                .foregroundColor(JuntoColors.textMain)
                                            Text("Após esta data, não aceita novos membros")
                                                .font(.inter(11, weight: .regular))
                                                .foregroundColor(JuntoColors.textMuted)
                                        }
                                        Spacer()
                                        DatePicker("", selection: $publicUntilDate, in: Date()..., displayedComponents: .date)
                                            .labelsHidden()
                                            .environment(\.locale, Locale(identifier: "pt_BR"))
                                    }
                                    .padding(.vertical, 4)

                                    Text("💡 O valor por pessoa é recalculado dinamicamente conforme novos membros entram no grupo.")
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.primary)
                                        .padding(10)
                                        .background(JuntoColors.primaryLight.opacity(0.5))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }

                        // Membros
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
                                }
                            }

                            if !selectedPeople.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(selectedPeople) { person in
                                            HStack(spacing: 6) {
                                                GeometricAvatarView(seed: person.username, size: 22)
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
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }

                        // Cálculo automático ao vivo limpo (sem caixa retangular)
                        if potTotalValue > 0 {
                            Divider()
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(potMode == .monthly ? "Parcela mensal por pessoa (\(activeMonthsCount) meses)" : "Cota individual do Pote")
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                    Text(potMode == .monthly
                                         ? "\(JuntoStore.formatBRL(potTotalValue)) ÷ \(activeMonthsCount) meses ÷ \(totalPeopleCount) pessoa(s)"
                                         : "\(JuntoStore.formatBRL(potTotalValue)) ÷ \(totalPeopleCount) pessoa(s)")
                                        .font(.inter(13, weight: .regular))
                                        .foregroundColor(JuntoColors.textMain)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 1) {
                                    Text(JuntoStore.formatBRL(quotaPerPerson))
                                        .font(.inter(20, weight: .medium))
                                        .foregroundColor(JuntoColors.pixGreen)
                                    Text(potMode == .monthly ? "por pessoa / mês" : "por pessoa")
                                        .font(.inter(11, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                }
                            }
                            .padding(.vertical, 4)
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
        .sheet(isPresented: $showReceiptScanner) {
            ReceiptScannerModal { items, total in
                scannedReceiptItems = items
                potTotalText = String(format: "%.2f", total).replacingOccurrences(of: ".", with: ",")
            }
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
            potMode: potMode,
            totalMonths: activeMonthsCount,
            invitedPeople: selectedPeople,
            coverImageData: coverImageData,
            startDate: startDate,
            targetDate: targetDate,
            isPublic: isPublicGroup,
            maxParticipants: maxParticipants,
            publicUntilDate: publicUntilDate,
            comandaItems: scannedReceiptItems
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

            // Barra de busca compacta
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)

                TextField("Buscar entre seus amigos...", text: $searchText)
                    .font(.inter(14, weight: .regular))
                    .foregroundColor(JuntoColors.textMain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
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

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(filteredFriends) { friend in
                        let isAdded = selectedPeople.contains(where: { $0.username == friend.username })

                        HStack(spacing: 10) {
                            GeometricAvatarView(seed: friend.username, size: 34)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(friend.name)
                                    .font(.inter(13, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                                    .lineLimit(1)
                                Text("@\(friend.username)")
                                    .font(.inter(11, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 6)

                            Button {
                                if isAdded {
                                    selectedPeople.removeAll { $0.username == friend.username }
                                } else {
                                    selectedPeople.append(SearchableUser(name: friend.name, username: friend.username))
                                }
                            } label: {
                                Text(isAdded ? "Adicionado" : "Adicionar")
                                    .font(.inter(11, weight: .medium))
                                    .foregroundColor(isAdded ? JuntoColors.textMain : .white)
                                    .padding(.horizontal, 10)
                                    .frame(height: 28)
                                    .background(isAdded ? JuntoColors.surfaceSubtle : JuntoColors.primary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(isAdded ? JuntoColors.border : Color.clear, lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 7)

                        Divider().padding(.leading, 62)
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
    @State private var showGroupReceiptScanner = false
    @State private var selectedItemForConsumers: ComandaItem? = nil

    @State private var showAddMemberScreen = false
    @State private var selectedParticipantForAction: GroupParticipant? = nil
    @State private var pendingPaymentSheet: GroupPaymentRequest? = nil
    @State private var showGroupChat = false
    @State private var showMembersSheet = false
    @State private var showDeleteGroupConfirm = false

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
            let canAddExpenses = store.canCurrentUserAddExpenses(in: group)
            let activeMonthIdx = min(max(0, group.selectedMonthIndex), max(0, group.monthlyCycles.count - 1))
            let monthPercent = group.monthCompletionPercent(at: activeMonthIdx)
            let overallPercent = group.overallGoalPercent
            let paidCount = group.paidParticipantsCount(at: activeMonthIdx)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Topo (Fechar | Nome do Grupo | Chat do Grupo)
                    HStack {
                        CircleNavButton(icon: "xmark") { dismiss() }
                        Spacer()
                        Button {
                            showMembersSheet = true
                        } label: {
                            HStack(spacing: 5) {
                                Text(group.title)
                                    .font(.inter(17, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                                    .lineLimit(1)
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(JuntoColors.primary)
                            }
                        }
                        Spacer()
                        CircleNavButton(icon: "bubble.left.and.bubble.right", bgColor: JuntoColors.primary, fgColor: .white) {
                            showGroupChat = true
                        }
                    }
                    .padding(.top, 16)

                    // Capa do grupo ampla (sem cortes verticais)
                    ZStack(alignment: .bottomLeading) {
                        if let data = group.coverImageData, let uiImg = UIImage(data: data) {
                            Image(uiImage: uiImg)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 195)
                                .clipped()
                        } else {
                            Image(group.coverImageName)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 195)
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

                    Divider()

                    // POTE COLETIVO / POTE MENSAL LIMPO E ORGANIZADO (Hierarquia nativa iOS sem caixas retangulares)
                    if group.hasCollectivePot {
                        VStack(alignment: .leading, spacing: 16) {
                            // 1. Cabeçalho do Pote + Meta Geral
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(group.potMode == .monthly ? "Pote Mensal" : "Pote Coletivo")
                                        .font(.inter(16, weight: .medium))
                                        .foregroundColor(JuntoColors.textMain)

                                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                                        Text(JuntoStore.formatBRL(group.potBalance))
                                            .font(.inter(24, weight: .medium))
                                            .foregroundColor(JuntoColors.textMain)
                                        Text("de \(JuntoStore.formatBRL(group.potTarget))")
                                            .font(.inter(13, weight: .regular))
                                            .foregroundColor(JuntoColors.textMuted)
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(overallPercent)%")
                                        .font(.inter(22, weight: .medium))
                                        .foregroundColor(overallPercent == 100 ? JuntoColors.pixGreen : JuntoColors.primary)
                                    Text("da meta geral")
                                        .font(.inter(11, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                }
                            }

                            // Barra de progresso da meta geral
                            if group.potTarget > 0 {
                                GeometryReader { geo in
                                    let ratio = min(max(Double(overallPercent) / 100.0, 0), 1.0)
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3).fill(JuntoColors.surfaceSubtle)
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(ratio >= 1.0 ? JuntoColors.pixGreen : JuntoColors.primary)
                                            .frame(width: max(geo.size.width * ratio, ratio > 0 ? 8 : 0))
                                    }
                                }
                                .frame(height: 6)
                            }

                            // 2. Se for Pote Mensal: Seletor de meses + progresso do mês selecionado
                            if group.potMode == .monthly && !group.monthlyCycles.isEmpty {
                                let currentCycle = group.monthlyCycles[activeMonthIdx]
                                let monthCollected = Double(paidCount) * group.monthlyQuotaPerPerson

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(Array(group.monthlyCycles.enumerated()), id: \.element.id) { mIdx, cycle in
                                            let isSelected = activeMonthIdx == mIdx
                                            let cPct = group.monthCompletionPercent(at: mIdx)
                                            Button {
                                                withAnimation(.easeInOut(duration: 0.16)) {
                                                    store.groups[idx].selectedMonthIndex = mIdx
                                                }
                                            } label: {
                                                HStack(spacing: 5) {
                                                    if cPct == 100 {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundColor(isSelected ? .white : JuntoColors.pixGreen)
                                                    }
                                                    Text(cycle.label)
                                                        .font(.inter(12, weight: .medium))
                                                    Text("· \(cPct)%")
                                                        .font(.inter(12, weight: .regular))
                                                        .opacity(0.85)
                                                }
                                                .foregroundColor(isSelected ? .white : JuntoColors.textMain)
                                                .padding(.horizontal, 14)
                                                .frame(height: 34)
                                                .background(isSelected ? JuntoColors.primary : JuntoColors.surfaceSubtle)
                                                .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }

                                VStack(spacing: 6) {
                                    HStack {
                                        Text("\(currentCycle.label) · \(paidCount) de \(group.participants.count) pagaram")
                                            .font(.inter(13, weight: .medium))
                                            .foregroundColor(JuntoColors.textMain)
                                        Spacer()
                                        Text("\(JuntoStore.formatBRL(monthCollected)) de \(JuntoStore.formatBRL(group.monthlyTargetAmount)) (\(monthPercent)%)")
                                            .font(.inter(12, weight: .regular))
                                            .foregroundColor(monthPercent == 100 ? JuntoColors.pixGreen : JuntoColors.textMuted)
                                    }

                                    GeometryReader { geo in
                                        let ratio = min(max(Double(monthPercent) / 100.0, 0), 1.0)
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 2.5).fill(JuntoColors.surfaceSubtle)
                                            RoundedRectangle(cornerRadius: 2.5)
                                                .fill(ratio >= 1.0 ? JuntoColors.pixGreen : JuntoColors.primary)
                                                .frame(width: max(geo.size.width * ratio, ratio > 0 ? 6 : 0))
                                        }
                                    }
                                    .frame(height: 5)
                                }
                            } else if group.potTarget > 0 {
                                HStack {
                                    Text("\(paidCount) de \(group.participants.count) pagaram")
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                    Spacer()
                                    Text("Meta até \(Self.dateFormatter.string(from: group.targetDate))")
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                }
                            }

                            // 3. Lista nativa iOS de cotas por participante
                            let isOwner = store.isCurrentUserOwner(in: group)
                            VStack(spacing: 0) {
                                ForEach(Array(group.participants.enumerated()), id: \.element.id) { pIndex, participant in
                                    let uname = participant.username.lowercased()
                                    let isPaidInCurrentCycle: Bool = {
                                        if group.potMode == .monthly, group.monthlyCycles.indices.contains(activeMonthIdx) {
                                            return group.monthlyCycles[activeMonthIdx].paidUsernames.contains(uname)
                                        }
                                        return participant.hasPaid
                                    }()
                                    let isMarkedInCurrentCycle: Bool = {
                                        if group.potMode == .monthly, group.monthlyCycles.indices.contains(activeMonthIdx) {
                                            return group.monthlyCycles[activeMonthIdx].markedPaidUsernames.contains(uname)
                                        }
                                        return participant.markedPaidByMember
                                    }()
                                    let monthLabelText: String = (group.potMode == .monthly && group.monthlyCycles.indices.contains(activeMonthIdx))
                                        ? " (\(group.monthlyCycles[activeMonthIdx].label))"
                                        : ""

                                    HStack(spacing: 12) {
                                        GeometricAvatarView(seed: participant.username, size: 36)

                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 5) {
                                                Text(participant.name)
                                                    .font(.inter(14, weight: .medium))
                                                    .foregroundColor(JuntoColors.textMain)
                                                VerifiedBadgeView(type: participant.proPlanType, size: 12)
                                                if participant.role != .member {
                                                    Text("· \(participant.role.rawValue)")
                                                        .font(.inter(11, weight: .regular))
                                                        .foregroundColor(JuntoColors.textMuted)
                                                }
                                            }
                                            if isMarkedInCurrentCycle && !isPaidInCurrentCycle {
                                                Text("\(JuntoStore.formatBRL(participant.quotaAmount)) · Informou pago")
                                                    .font(.inter(12, weight: .medium))
                                                    .foregroundColor(JuntoColors.orangeSave)
                                            } else {
                                                Text("Cota: \(JuntoStore.formatBRL(participant.quotaAmount))")
                                                    .font(.inter(12, weight: .regular))
                                                    .foregroundColor(JuntoColors.textMuted)
                                            }
                                        }

                                        Spacer()

                                        if isPaidInCurrentCycle {
                                            HStack(spacing: 4) {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 11, weight: .semibold))
                                                Text("Pago")
                                                    .font(.inter(13, weight: .medium))
                                            }
                                            .foregroundColor(JuntoColors.pixGreen)
                                        } else if participant.name == "Você" {
                                            if isMarkedInCurrentCycle {
                                                if isOwner {
                                                    Button("Confirmar") {
                                                        store.ownerConfirmParticipantPaid(groupId: groupId, participantId: participant.id, monthIndex: activeMonthIdx)
                                                    }
                                                    .font(.inter(12, weight: .medium))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(JuntoColors.pixGreen)
                                                    .clipShape(Capsule())
                                                } else {
                                                    Text("Aguardando")
                                                        .font(.inter(12, weight: .medium))
                                                        .foregroundColor(JuntoColors.orangeSave)
                                                }
                                            } else {
                                                Button("Pagar") {
                                                    pendingPaymentSheet = GroupPaymentRequest(
                                                        title: "Cota\(monthLabelText) • \(group.title)",
                                                        amount: participant.quotaAmount,
                                                        participantId: participant.id
                                                    )
                                                }
                                                .font(.inter(12, weight: .medium))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 6)
                                                .background(JuntoColors.primary)
                                                .clipShape(Capsule())
                                            }
                                        } else if isOwner {
                                            Button("Confirmar") {
                                                store.ownerConfirmParticipantPaid(groupId: groupId, participantId: participant.id, monthIndex: activeMonthIdx)
                                            }
                                            .font(.inter(12, weight: .medium))
                                            .foregroundColor(isMarkedInCurrentCycle ? .white : JuntoColors.primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(isMarkedInCurrentCycle ? JuntoColors.pixGreen : JuntoColors.surfaceSubtle)
                                            .clipShape(Capsule())
                                        } else {
                                            Text(isMarkedInCurrentCycle ? "Aguardando" : "Pendente")
                                                .font(.inter(12, weight: .regular))
                                                .foregroundColor(JuntoColors.textMuted)
                                        }
                                    }
                                    .padding(.vertical, 10)

                                    if pIndex < group.participants.count - 1 {
                                        Divider().padding(.leading, 48)
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    // Despesas / Comanda do Grupo (somente Dono ou Admin)
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Despesas do grupo")
                                .font(.inter(16, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                            Spacer()
                            if canAddExpenses {
                                HStack(spacing: 8) {
                                    Button {
                                        showGroupReceiptScanner = true
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "doc.viewfinder")
                                                .font(.system(size: 12))
                                            Text("Recibo")
                                                .font(.inter(12, weight: .medium))
                                        }
                                        .foregroundColor(JuntoColors.primary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(JuntoColors.surfaceSubtle)
                                        .clipShape(Capsule())
                                    }

                                    Button {
                                        withAnimation { showAddExpenseForm.toggle() }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: showAddExpenseForm ? "xmark" : "plus")
                                                .font(.system(size: 11))
                                            Text(showAddExpenseForm ? "Fechar" : "Manual")
                                                .font(.inter(12, weight: .medium))
                                        }
                                        .foregroundColor(JuntoColors.primary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(JuntoColors.surfaceSubtle)
                                        .clipShape(Capsule())
                                    }
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
                            .padding(.vertical, 8)
                        }

                        if group.comandaItems.isEmpty {
                            Text("Nenhuma despesa lançada ainda.")
                                .font(.inter(13, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .padding(.vertical, 8)
                        } else {
                            // Checklist interativo de itens da comanda / recibo
                            VStack(spacing: 0) {
                                ForEach(store.groups[idx].comandaItems.indices, id: \.self) { itemIdx in
                                    let item = store.groups[idx].comandaItems[itemIdx]
                                    let isAssignedToMe = item.assignedUsernames.contains(store.user.username.lowercased())
                                    let shareForThisItem = item.sharePerConsumer(totalMembersCount: group.participants.count)

                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(alignment: .top, spacing: 10) {
                                            Button {
                                                store.groups[idx].comandaItems[itemIdx].isSelected.toggle()
                                            } label: {
                                                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                                    .font(.system(size: 20, weight: .regular))
                                                    .foregroundColor(item.isSelected ? JuntoColors.primary : JuntoColors.textLight)
                                            }

                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(item.name)
                                                    .font(.inter(15, weight: .medium))
                                                    .foregroundColor(item.isSelected ? JuntoColors.textMain : JuntoColors.textMuted)

                                                HStack(spacing: 6) {
                                                    Text("\(item.quantity) un • \(JuntoStore.formatBRL(item.price))")
                                                        .font(.inter(12, weight: .regular))
                                                        .foregroundColor(JuntoColors.textMuted)

                                                    if item.quantity > 1 {
                                                        Text("(\(JuntoStore.formatBRL(item.unitPrice)) cada)")
                                                            .font(.inter(11, weight: .regular))
                                                            .foregroundColor(JuntoColors.textLight)
                                                    }
                                                }
                                            }

                                            Spacer()

                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text(JuntoStore.formatBRL(item.price))
                                                    .font(.inter(15, weight: .medium))
                                                    .foregroundColor(JuntoColors.textMain)
                                                Text("Cota: \(JuntoStore.formatBRL(shareForThisItem))")
                                                    .font(.inter(11, weight: .regular))
                                                    .foregroundColor(JuntoColors.textMuted)
                                            }
                                        }

                                        // Linha de checklist por consumo
                                        HStack(spacing: 8) {
                                            Button {
                                                store.toggleMemberAssignedToComandaItem(
                                                    groupId: groupId,
                                                    itemId: item.id,
                                                    username: store.user.username
                                                )
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Image(systemName: isAssignedToMe ? "checkmark.square.fill" : "square")
                                                        .font(.system(size: 13))
                                                    Text(isAssignedToMe ? "Eu consumi" : "Marcar que consumi")
                                                        .font(.inter(11, weight: .medium))
                                                }
                                                .foregroundColor(isAssignedToMe ? JuntoColors.pixGreen : JuntoColors.textMuted)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(isAssignedToMe ? JuntoColors.pixGreenLight : JuntoColors.surfaceSubtle)
                                                .clipShape(Capsule())
                                            }

                                            Spacer()

                                            Button {
                                                selectedItemForConsumers = item
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "person.2")
                                                        .font(.system(size: 11))
                                                    Text(item.assignedUsernames.isEmpty ? "Todos (\(group.participants.count))" : "\(item.assignedUsernames.count) pessoa(s)")
                                                        .font(.inter(11, weight: .regular))
                                                }
                                                .foregroundColor(JuntoColors.textMuted)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(JuntoColors.surfaceSubtle)
                                                .clipShape(Capsule())
                                            }
                                        }
                                        .padding(.leading, 30)
                                    }
                                    .padding(.vertical, 10)
                                    Divider()
                                }
                            }

                            // Resumo de cálculo da comanda com base no checklist
                            let myShare = store.userShareForComanda(in: group, username: store.user.username)
                            if myShare > 0 {
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Sua parte na comanda")
                                            .font(.inter(12, weight: .regular))
                                            .foregroundColor(JuntoColors.textMuted)
                                        Text(JuntoStore.formatBRL(myShare))
                                            .font(.inter(18, weight: .medium))
                                            .foregroundColor(JuntoColors.pixGreen)
                                    }

                                    Spacer()

                                    JuntoPillButton(title: "Pagar \(JuntoStore.formatBRL(myShare))", color: JuntoColors.primary) {
                                        pendingPaymentSheet = GroupPaymentRequest(
                                            title: "Comanda • \(group.title)",
                                            amount: myShare,
                                            participantId: nil
                                        )
                                    }
                                    .frame(width: 170)
                                }
                                .padding(.top, 8)
                            }
                        }
                    }

                    // Botão Excluir Grupo limpo (sem caixa retangular)
                    if store.isCurrentUserOwner(in: group) {
                        Divider()
                        Button {
                            showDeleteGroupConfirm = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash")
                                    .font(.system(size: 15, weight: .regular))
                                Text("Excluir grupo")
                                    .font(.inter(15, weight: .medium))
                            }
                            .foregroundColor(JuntoColors.danger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(Color.white)
            .fullScreenCover(isPresented: $showGroupChat) {
                GroupChatScreen(groupId: groupId)
                    .environmentObject(store)
            }
            .alert("Excluir \"\(group.title)\"?", isPresented: $showDeleteGroupConfirm) {
                Button("Cancelar", role: .cancel) {}
                Button("Excluir grupo", role: .destructive) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        store.deleteGroup(groupId: groupId)
                    }
                }
            } message: {
                Text("Ao excluir este grupo, todas as cotas e toda a conversa em grupo serão apagadas permanentemente.")
            }
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
            .sheet(item: $pendingPaymentSheet) { request in
                let organizer = store.organizerPixInfo(for: group)
                OrganizerPixPaymentSheet(
                    title: request.title,
                    organizerName: organizer.name,
                    organizerPixKey: organizer.pixKey,
                    amount: request.amount,
                    onMarkAsPaid: {
                        if let pid = request.participantId {
                            store.memberMarkQuotaAsPaid(groupId: groupId, participantId: pid, monthIndex: activeMonthIdx)
                        } else {
                            store.memberMarkGroupExpensesAsPaid(groupId: groupId, amount: request.amount)
                        }
                        pendingPaymentSheet = nil
                    },
                    onSendReceipt: { imgData, fileName in
                        store.sendGroupReceipt(groupId: groupId, amount: request.amount, imageData: imgData, fileName: fileName)
                    }
                )
                .presentationDetents([.height(540), .large])
                .presentationCornerRadius(20)
            }
            .sheet(isPresented: $showMembersSheet) {
                GroupMembersSheet(group: group)
                    .environmentObject(store)
                    .presentationDetents([.fraction(0.68), .large])
                    .presentationCornerRadius(24)
            }
            .sheet(isPresented: $showGroupReceiptScanner) {
                ReceiptScannerModal { items, total in
                    store.addReceiptItemsToGroup(groupId: groupId, items: items, payFromPot: payFromPot)
                }
            }
            .sheet(item: $selectedItemForConsumers) { itm in
                AssignItemConsumersSheet(group: group, item: itm) { updatedItem in
                    if let gIdx = store.groups.firstIndex(where: { $0.id == groupId }),
                       let iIdx = store.groups[gIdx].comandaItems.firstIndex(where: { $0.id == itm.id }) {
                        store.groups[gIdx].comandaItems[iIdx] = updatedItem
                    }
                    selectedItemForConsumers = nil
                }
                .presentationDetents([.medium])
            }
        }
    }
}

// MARK: - Sheet de Visualização e Gestão de Membros do Grupo
struct GroupMembersSheet: View {
    let group: RoleGroup
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    private var currentGroup: RoleGroup {
        store.groups.first(where: { $0.id == group.id }) ?? group
    }

    private var filteredParticipants: [GroupParticipant] {
        if searchText.isEmpty { return currentGroup.participants }
        let clean = searchText.lowercased()
        return currentGroup.participants.filter {
            $0.name.lowercased().contains(clean) || $0.username.lowercased().contains(clean)
        }
    }

    private var isCurrentUserOwnerOrAdmin: Bool {
        store.isCurrentUserGroupOwnerOrAdmin(in: currentGroup)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Topo do Sheet
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Membros do Grupo")
                        .font(.inter(18, weight: .bold))
                        .foregroundColor(JuntoColors.textMain)
                    Text("\(currentGroup.participants.count) participante(s) · \(currentGroup.title)")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(JuntoColors.textMuted)
                        .frame(width: 32, height: 32)
                        .background(JuntoColors.surfaceSubtle)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            // Barra de busca
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(JuntoColors.textMuted)
                    .font(.system(size: 14))
                TextField("Buscar membro...", text: $searchText)
                    .font(.inter(14, weight: .regular))
            }
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(JuntoColors.surfaceSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // Lista de participantes
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(filteredParticipants) { participant in
                        let isMe = participant.username.lowercased() == store.user.username.lowercased()

                        HStack(spacing: 12) {
                            GeometricAvatarView(seed: participant.username, displayName: participant.name, size: 42)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text(isMe ? "\(participant.name) (Você)" : participant.name)
                                        .font(.inter(14, weight: .medium))
                                        .foregroundColor(JuntoColors.textMain)

                                    VerifiedBadgeView(type: participant.proPlanType, size: 13)

                                    if participant.role == .owner {
                                        Text("Dono")
                                            .font(.inter(10, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 1.5)
                                            .background(JuntoColors.primary)
                                            .clipShape(Capsule())
                                    } else if participant.role == .admin {
                                        Text("Admin")
                                            .font(.inter(10, weight: .bold))
                                            .foregroundColor(JuntoColors.primary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 1.5)
                                            .background(JuntoColors.surfaceSubtle)
                                            .clipShape(Capsule())
                                    }
                                }

                                Text("@\(participant.username)")
                                    .font(.inter(12, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                            }

                            Spacer()

                            if currentGroup.isPublic {
                                // Em grupos públicos: botão Adicionar / Amigos (ao clicar desfaz amizade)
                                if !isMe {
                                    let isFriend = store.friends.contains { $0.username.lowercased() == participant.username.lowercased() && !$0.isPendingInvite }
                                    Button {
                                        withAnimation {
                                            if isFriend {
                                                store.unfriend(username: participant.username)
                                            } else {
                                                store.addFriend(username: participant.username, name: participant.name)
                                            }
                                        }
                                    } label: {
                                        if isFriend {
                                            HStack(spacing: 3) {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 9, weight: .bold))
                                                Text("Amigos")
                                                    .font(.inter(11, weight: .medium))
                                            }
                                            .foregroundColor(JuntoColors.textMuted)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(JuntoColors.surfaceSubtle)
                                            .clipShape(Capsule())
                                        } else {
                                            HStack(spacing: 3) {
                                                Image(systemName: "plus")
                                                    .font(.system(size: 9, weight: .bold))
                                                Text("Adicionar")
                                                    .font(.inter(11, weight: .medium))
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(JuntoColors.primary)
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                            } else {
                                // Status de Pagamento (Grupos Fechados / Rolês)
                                if participant.hasPaid {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 13))
                                        Text("Pago")
                                            .font(.inter(12, weight: .bold))
                                    }
                                    .foregroundColor(JuntoColors.pixGreen)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(JuntoColors.pixGreen.opacity(0.12))
                                    .clipShape(Capsule())
                                } else {
                                    Text("Pendente")
                                        .font(.inter(12, weight: .medium))
                                        .foregroundColor(JuntoColors.orangeSave)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(JuntoColors.orangeSave.opacity(0.12))
                                        .clipShape(Capsule())
                                }

                                // Ação rápida para Dono/Admin
                                if isCurrentUserOwnerOrAdmin {
                                    Button {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        store.ownerConfirmParticipantPaid(
                                            groupId: currentGroup.id,
                                            participantId: participant.id,
                                            monthIndex: currentGroup.selectedMonthIndex
                                        )
                                    } label: {
                                        Image(systemName: participant.hasPaid ? "arrow.uturn.backward.circle" : "checkmark.seal")
                                            .font(.system(size: 18))
                                            .foregroundColor(participant.hasPaid ? JuntoColors.textMuted : JuntoColors.primary)
                                    }
                                    .padding(.leading, 4)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)

                        Divider().padding(.leading, 74)
                    }
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}

// MARK: - Sheet de Pagamento Direto ao Organizador (Vencimento de 5 minutos + Anexo de comprovante)
struct OrganizerPixPaymentSheet: View {
    let title: String
    let organizerName: String
    let organizerPixKey: String
    let amount: Double
    let onMarkAsPaid: () -> Void
    var onSendReceipt: ((Data?, String?) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    enum PixTab: String, CaseIterable {
        case qrCode = "QR Code Pix"
        case copyKey = "Copiar chave Pix"
    }

    @State private var selectedTab: PixTab = .qrCode
    @State private var copiedKey = false
    @State private var copiedPayload = false
    @State private var timeRemaining = 300 // 5 minutos = 300 segundos
    @State private var timer: Timer? = nil

    // Anexo de comprovante (Foto ou PDF)
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showFileImporter = false
    @State private var attachedData: Data? = nil
    @State private var attachedFileName: String? = nil

    private var formattedTime: String {
        let mins = timeRemaining / 60
        let secs = timeRemaining % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private var pixPayload: String {
        let formattedValue = String(format: "%.2f", amount)
        return "00020126420014br.gov.bcb.pix0120\(organizerPixKey)520400005303986540\(formattedValue.count)\(formattedValue)5802BR5914\(organizerName.prefix(14).uppercased())6009SAO PAULO62070503***6304E1F9"
    }

    private func generateQRCodeImage(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let outputImage = filter.outputImage else { return nil }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Cabeçalho limpo
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pagar via Pix")
                        .font(.inter(18, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Text("\(title) · Para: \(organizerName)")
                        .font(.inter(12, weight: .regular))
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
            .padding(.top, 18)

            // Valor a transferir e tempo (5 minutos de vencimento)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Valor a transferir")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                    if timeRemaining > 0 {
                        Text("Chave Pix válida por \(formattedTime)")
                            .font(.inter(11, weight: .regular))
                            .foregroundColor(timeRemaining < 60 ? JuntoColors.danger : JuntoColors.textLight)
                            .monospacedDigit()
                    } else {
                        Text("Chave expirada")
                            .font(.inter(11, weight: .medium))
                            .foregroundColor(JuntoColors.danger)
                    }
                }
                Spacer()
                Text(JuntoStore.formatBRL(amount))
                    .font(.inter(20, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(JuntoColors.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Abas: QR Code Pix | Copiar chave Pix
            HStack(spacing: 8) {
                ForEach(PixTab.allCases, id: \.self) { tab in
                    let active = selectedTab == tab
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) { selectedTab = tab }
                    } label: {
                        Text(tab.rawValue)
                            .font(.inter(13, weight: .medium))
                            .foregroundColor(active ? .white : JuntoColors.textMain)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(active ? JuntoColors.primary : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(active ? JuntoColors.primary : JuntoColors.border, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            // Conteúdo da aba selecionada
            if selectedTab == .qrCode {
                VStack(spacing: 10) {
                    Text("Aponte a câmera do celular ou leitor Pix do seu banco")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)

                    if let qrImg = generateQRCodeImage(from: pixPayload) {
                        Image(uiImage: qrImg)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 155, height: 155)
                            .padding(8)
                            .background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(JuntoColors.border, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        UIPasteboard.general.string = pixPayload
                        copiedPayload = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedPayload = false }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: copiedPayload ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 13, weight: .medium))
                            Text(copiedPayload ? "Código Pix copiado" : "Copiar código Pix Copia e Cola")
                                .font(.inter(13, weight: .medium))
                        }
                        .foregroundColor(JuntoColors.primary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chave Pix de \(organizerName)")
                            .font(.inter(12, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                        Text(organizerPixKey)
                            .font(.inter(16, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(JuntoColors.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    JuntoOutlineButton(
                        title: copiedKey ? "Chave Pix copiada" : "Copiar chave Pix",
                        icon: copiedKey ? "checkmark" : "doc.on.doc",
                        color: JuntoColors.primary
                    ) {
                        UIPasteboard.general.string = organizerPixKey
                        copiedKey = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedKey = false }
                    }

                    Text("Transfira o valor no seu banco e anexe o comprovante abaixo para o organizador.")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }
                .padding(.vertical, 4)
            }

            Spacer(minLength: 4)

            // Comprovante anexado (se houver)
            if let fName = attachedFileName {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(JuntoColors.pixGreen)
                    Text("Comprovante: \(fName)")
                        .font(.inter(12, weight: .medium))
                        .foregroundColor(JuntoColors.pixGreen)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        attachedData = nil
                        attachedFileName = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(JuntoColors.textMuted)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(JuntoColors.pixGreen.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Botões de Ação: Anexar Comprovante (Foto ou PDF) + Já Paguei
            HStack(spacing: 10) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.system(size: 13))
                        Text("Foto")
                            .font(.inter(13, weight: .medium))
                    }
                    .foregroundColor(JuntoColors.primary)
                    .frame(height: 48)
                    .padding(.horizontal, 12)
                    .background(JuntoColors.surfaceSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showFileImporter = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 13))
                        Text("PDF")
                            .font(.inter(13, weight: .medium))
                    }
                    .foregroundColor(JuntoColors.primary)
                    .frame(height: 48)
                    .padding(.horizontal, 12)
                    .background(JuntoColors.surfaceSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    onSendReceipt?(attachedData, attachedFileName ?? (attachedData != nil ? "comprovante.jpg" : nil))
                    onMarkAsPaid()
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                        Text(attachedData != nil || attachedFileName != nil ? "Enviar e Confirmar" : "Já paguei via Pix")
                            .font(.inter(14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(JuntoColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 20)
        .background(Color.white.ignoresSafeArea())
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    attachedData = data
                    attachedFileName = "comprovante_pix.jpg"
                }
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                attachedData = try? Data(contentsOf: url)
                attachedFileName = url.lastPathComponent
            }
        }
        .onAppear {
            timeRemaining = 300
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timer?.invalidate()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
}

// MARK: - Sheet Customizado Claro (Gerenciar Participante: Tornar Admin / Remover — Lista limpa nativa iOS)
struct ParticipantActionSheet: View {
    let participant: GroupParticipant
    let onToggleAdmin: () -> Void
    let onRemove: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                GeometricAvatarView(seed: participant.username, size: 48)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(participant.name)
                            .font(.inter(16, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                        VerifiedBadgeView(type: participant.proPlanType, size: 14)
                    }
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
            .padding(.bottom, 16)

            Divider()

            Button(action: onToggleAdmin) {
                HStack(spacing: 14) {
                    Image(systemName: participant.role == .admin ? "shield.slash" : "checkmark.shield")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(JuntoColors.primary)
                        .frame(width: 24)
                    Text(participant.role == .admin ? "Remover permissão de admin" : "Tornar admin do grupo")
                        .font(.inter(15, weight: .regular))
                        .foregroundColor(JuntoColors.textMain)
                    Spacer()
                }
                .padding(.vertical, 16)
            }

            Divider().padding(.leading, 38)

            Button(action: onRemove) {
                HStack(spacing: 14) {
                    Image(systemName: "person.badge.minus")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(JuntoColors.danger)
                        .frame(width: 24)
                    Text("Remover do grupo")
                        .font(.inter(15, weight: .regular))
                        .foregroundColor(JuntoColors.danger)
                    Spacer()
                }
                .padding(.vertical, 16)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color.white.ignoresSafeArea())
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

// MARK: - Criar Pote Pessoal (Caixinha Individual para uma Ocasião — Exclusivo Juntô Pro)
struct CreatePersonalPotScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var selectedOccasion: String = "Viagem"
    @State private var targetAmountText: String = ""
    @State private var targetDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()

    private let occasions: [(name: String, icon: String)] = [
        ("Viagem", "airplane"),
        ("Show / Festival", "music.note"),
        ("Formatura", "graduationcap"),
        ("Aniversário", "gift"),
        ("Reserva", "lock.shield"),
        ("Casa Nova", "house")
    ]

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "dd 'de' MMM. 'de' yyyy"
        return f
    }()

    private var selectedIcon: String {
        occasions.first(where: { $0.name == selectedOccasion })?.icon ?? "dollarsign.circle"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                CircleNavButton(icon: "xmark") { dismiss() }
                Spacer()
                Text("Nova Caixinha Pessoal")
                    .font(.inter(17, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                CircleNavButton(icon: "checkmark", bgColor: JuntoColors.primary, fgColor: .white) {
                    handleSave()
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    CleanOutlineInput(
                        label: "Nome da Caixinha",
                        placeholder: "Ex: Réveillon em Pipa, Lollapalooza...",
                        text: $title
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ocasião")
                            .font(.inter(13, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(occasions, id: \.name) { item in
                                    let active = selectedOccasion == item.name
                                    Button {
                                        selectedOccasion = item.name
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: item.icon)
                                                .font(.system(size: 14, weight: .regular))
                                            Text(item.name)
                                                .font(.inter(13, weight: .medium))
                                        }
                                        .foregroundColor(active ? .white : JuntoColors.textMain)
                                        .padding(.horizontal, 14)
                                        .frame(height: 36)
                                        .background(active ? JuntoColors.primary : JuntoColors.surfaceSubtle)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }

                    CleanOutlineInput(
                        label: "Meta para guardar (R$)",
                        placeholder: "Ex: 1500",
                        text: $targetAmountText,
                        keyboardType: .decimalPad,
                        leadingPrefix: "R$"
                    )

                    VStack(spacing: 0) {
                        Divider()
                        HStack {
                            Label("Data da ocasião", systemImage: "calendar")
                                .font(.inter(14, weight: .regular))
                                .foregroundColor(JuntoColors.textMain)
                            Spacer()
                            DatePicker("", selection: $targetDate, in: Date()..., displayedComponents: .date)
                                .labelsHidden()
                                .environment(\.locale, Locale(identifier: "pt_BR"))
                        }
                        .padding(.vertical, 10)
                        Divider()
                    }

                    JuntoPillButton(title: "Criar Caixinha Pessoal", color: JuntoColors.primary) {
                        handleSave()
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }

    private func handleSave() {
        let normalized = targetAmountText
            .replacingOccurrences(of: "R$", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        let val = Double(normalized) ?? 0
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, val > 0 else {
            store.showToast("Informe o nome e a meta da caixinha.", icon: "exclamationmark.circle")
            return
        }
        let dateStr = Self.dateFormatter.string(from: targetDate)
        store.createPersonalPot(
            title: title,
            occasion: selectedOccasion,
            icon: selectedIcon,
            targetAmount: val,
            targetDateText: dateStr
        )
        dismiss()
    }
}

// MARK: - Detalhes do Pote Pessoal (Caixinha Individual — Guardar dinheiro, acompanhar % da meta e histórico)
struct PersonalPotDetailSheet: View {
    @EnvironmentObject var store: JuntoStore
    let potId: UUID
    @Environment(\.dismiss) private var dismiss

    @State private var depositAmountText: String = ""
    @State private var depositNoteText: String = ""
    @State private var showDepositForm: Bool = false

    private var potIndex: Int? {
        store.personalPots.firstIndex(where: { $0.id == potId })
    }

    var body: some View {
        if let idx = potIndex {
            let pot = store.personalPots[idx]

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pot.title)
                                .font(.inter(18, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                            Text("Caixinha Pessoal · \(pot.occasion)")
                                .font(.inter(12, weight: .regular))
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
                    .padding(.top, 18)

                    Divider()

                    // Resumo detalhado da Caixinha (% da meta, guardado, falta — sem caixa retangular)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Total guardado")
                                    .font(.inter(12, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                Text(JuntoStore.formatBRL(pot.currentAmount))
                                    .font(.inter(28, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(pot.percentCompleted)%")
                                    .font(.inter(22, weight: .medium))
                                    .foregroundColor(pot.percentCompleted == 100 ? JuntoColors.pixGreen : JuntoColors.primary)
                                Text("da meta de \(JuntoStore.formatBRL(pot.targetAmount))")
                                    .font(.inter(11, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                            }
                        }

                        GeometryReader { geo in
                            let ratio = pot.targetAmount > 0 ? min(pot.currentAmount / pot.targetAmount, 1.0) : 0
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3).fill(JuntoColors.surfaceSubtle)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(pot.percentCompleted == 100 ? JuntoColors.pixGreen : JuntoColors.primary)
                                    .frame(width: max(geo.size.width * ratio, ratio > 0 ? 10 : 0))
                            }
                        }
                        .frame(height: 6)

                        HStack {
                            Text(pot.remainingAmount > 0 ? "Faltam \(JuntoStore.formatBRL(pot.remainingAmount))" : "Meta 100% atingida!")
                                .font(.inter(12, weight: .medium))
                                .foregroundColor(pot.remainingAmount > 0 ? JuntoColors.textMain : JuntoColors.pixGreen)
                            Spacer()
                            Text("Para: \(pot.targetDateText)")
                                .font(.inter(12, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                        }
                    }

                    // Botão / Formulário para Guardar valor na Caixinha
                    if showDepositForm {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Guardar dinheiro na caixinha")
                                .font(.inter(14, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)

                            CleanOutlineInput(
                                label: "Valor (R$)",
                                placeholder: "0,00",
                                text: $depositAmountText,
                                keyboardType: .decimalPad,
                                leadingPrefix: "R$"
                            )

                            CleanOutlineInput(
                                label: "Observação (opcional)",
                                placeholder: "Ex: Economia deste mês",
                                text: $depositNoteText
                            )

                            HStack(spacing: 10) {
                                JuntoOutlineButton(title: "Cancelar", color: JuntoColors.textMuted) {
                                    showDepositForm = false
                                }
                                JuntoPillButton(title: "Confirmar", color: JuntoColors.primary) {
                                    let val = Double(depositAmountText.replacingOccurrences(of: ",", with: ".")) ?? 0
                                    store.depositIntoPersonalPot(potId: potId, amount: val, note: depositNoteText)
                                    depositAmountText = ""
                                    depositNoteText = ""
                                    showDepositForm = false
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    } else {
                        JuntoPillButton(title: "Guardar valor na caixinha", icon: "plus", color: JuntoColors.primary) {
                            withAnimation { showDepositForm = true }
                        }
                    }

                    Divider()

                    // Histórico de depósitos na Caixinha
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Histórico da caixinha")
                            .font(.inter(14, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)

                        if pot.deposits.isEmpty {
                            Text("Nenhum valor guardado ainda.")
                                .font(.inter(13, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(pot.deposits) { dep in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(dep.note)
                                                .font(.inter(14, weight: .regular))
                                                .foregroundColor(JuntoColors.textMain)
                                            Text(dep.dateText)
                                                .font(.inter(12, weight: .regular))
                                                .foregroundColor(JuntoColors.textMuted)
                                        }
                                        Spacer()
                                        Text("+ \(JuntoStore.formatBRL(dep.amount))")
                                            .font(.inter(14, weight: .medium))
                                            .foregroundColor(JuntoColors.pixGreen)
                                    }
                                    .padding(.vertical, 10)
                                    Divider()
                                }
                            }
                        }
                    }

                    Divider()

                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            store.deletePersonalPot(potId: potId)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .regular))
                            Text("Excluir caixinha")
                                .font(.inter(14, weight: .medium))
                        }
                        .foregroundColor(JuntoColors.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(Color.white.ignoresSafeArea())
        }
    }
}

// MARK: - Sheet para Definir Participantes de um Item da Comanda
struct AssignItemConsumersSheet: View {
    let group: RoleGroup
    let item: ComandaItem
    var onSave: (ComandaItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var currentAssigned: Set<String> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(item.name)
                        .font(.inter(17, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Text("\(item.quantity) un • \(JuntoStore.formatBRL(item.price))")
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }
                .padding(.top, 14)

                HStack {
                    Button("Selecionar todos") {
                        currentAssigned = Set(group.participants.map { $0.username.lowercased() })
                    }
                    .font(.inter(12, weight: .regular))
                    .foregroundColor(JuntoColors.primary)

                    Spacer()

                    Button("Limpar (Dividir por todos)") {
                        currentAssigned = []
                    }
                    .font(.inter(12, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
                }
                .padding(.horizontal, 20)

                Divider()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(group.participants) { p in
                            let isIncluded = currentAssigned.contains(p.username.lowercased())
                            Button {
                                let uname = p.username.lowercased()
                                if currentAssigned.contains(uname) {
                                    currentAssigned.remove(uname)
                                } else {
                                    currentAssigned.insert(uname)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    GeometricAvatarView(seed: p.username, size: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(p.name)
                                            .font(.inter(14, weight: .medium))
                                            .foregroundColor(JuntoColors.textMain)
                                        Text("@\(p.username)")
                                            .font(.inter(12, weight: .regular))
                                            .foregroundColor(JuntoColors.textMuted)
                                    }
                                    Spacer()
                                    Image(systemName: isIncluded ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(isIncluded ? JuntoColors.primary : JuntoColors.textLight)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                            }
                            Divider().padding(.leading, 68)
                        }
                    }
                }

                Divider()

                JuntoPillButton(title: "Salvar divisão do item", color: JuntoColors.primary) {
                    var updated = item
                    updated.assignedUsernames = currentAssigned
                    onSave(updated)
                    dismiss()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .navigationTitle("Quem consumiu?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                        .foregroundColor(JuntoColors.textMain)
                }
            }
            .onAppear {
                currentAssigned = item.assignedUsernames
            }
        }
    }
}
