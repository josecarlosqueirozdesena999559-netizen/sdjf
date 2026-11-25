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
            // Topo: "Grupos" em Bold + botão "+"
            HStack {
                Text("Grupos")
                    .font(.inter(26, weight: .bold))
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
                placeholders: ["Pesquisar grupos"]
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            if !filteredGroups.isEmpty {
                let totalPending = store.totalPersonalPendingAmount
                let totalPaid = store.totalPersonalPaidAmount
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(totalPending > 0 ? "Nos grupos, falta pagar" : "Nos grupos, você já pagou")
                            .font(.inter(15, weight: .semibold))
                            .foregroundColor(JuntoColors.textMain)
                        Text(JuntoStore.formatBRL(totalPending > 0 ? totalPending : totalPaid))
                            .font(.inter(16, weight: .bold))
                            .foregroundColor(totalPending > 0 ? JuntoColors.orangeSave : JuntoColors.pixGreen)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }

            Divider().opacity(0.6)

            if filteredGroups.isEmpty {
                Spacer()
                VStack(spacing: 14) {
                    if searchText.isEmpty {
                        ZStack {
                            Circle()
                                .fill(JuntoColors.primary.opacity(0.08))
                                .frame(width: 68, height: 68)
                            Image(systemName: "person.2")
                                .font(.system(size: 26, weight: .regular))
                                .foregroundColor(JuntoColors.primary)
                        }

                        Text("Nenhum grupo por aqui")
                            .font(.inter(17, weight: .bold))
                            .foregroundColor(JuntoColors.textMain)

                        Text("Organize viagens, casa ou rolês e divida contas com facilidade.")
                            .font(.inter(14, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 36)

                        Button {
                            if store.canCreateMoreGroups() {
                                showCreateGroup = true
                            } else {
                                store.showToast("Plano gratuito permite 1 grupo. Assine o Juntô Pro para grupos ilimitados.", icon: "lock")
                                showProPaywall = true
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "person.2.badge.plus")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Começar um novo grupo")
                                    .font(.inter(14, weight: .semibold))
                            }
                            .foregroundColor(JuntoColors.primary)
                            .padding(.horizontal, 22)
                            .frame(height: 44)
                            .background(Color.white)
                            .overlay(Capsule().stroke(JuntoColors.primary, lineWidth: 1.2))
                            .clipShape(Capsule())
                        }
                        .padding(.top, 4)
                    } else {
                        ZStack {
                            Circle()
                                .fill(JuntoColors.surfaceSubtle)
                                .frame(width: 60, height: 60)
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                        }
                        Text("Nenhum grupo encontrado")
                            .font(.inter(15, weight: .semibold))
                            .foregroundColor(JuntoColors.textMain)
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
                                HStack(spacing: 14) {
                                    // Sem imagens genéricas: sempre ícone limpo da categoria (ou foto se o usuário escolheu)
                                    GroupCategoryIconTile(category: group.category, size: 50)

                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Text(group.title)
                                                .font(.inter(16, weight: .semibold))
                                                .foregroundColor(JuntoColors.textMain)
                                                .lineLimit(1)
                                                .truncationMode(.tail)

                                            if group.hasCollectivePot && group.potTarget > 0 {
                                                let pct = group.overallGoalPercent
                                                Text("· \(pct)%")
                                                    .font(.inter(12, weight: .bold))
                                                    .foregroundColor(JuntoColors.pixGreen)
                                            }
                                        }

                                        // Breve descrição limpa do grupo
                                        if group.potMode == .monthly && group.potTarget > 0 {
                                            let mIdx = min(max(0, group.selectedMonthIndex), max(0, group.monthlyCycles.count - 1))
                                            let mLabel = group.monthlyCycles.indices.contains(mIdx) ? group.monthlyCycles[mIdx].label : "Mês \(mIdx + 1)"
                                            Text("\(group.category) · \(group.participants.count) pessoas · \(mLabel)")
                                                .font(.inter(12, weight: .regular))
                                                .foregroundColor(JuntoColors.textMuted)
                                                .lineLimit(1)
                                        } else {
                                            Text("\(group.category) · \(group.participants.count) pessoas")
                                                .font(.inter(13, weight: .regular))
                                                .foregroundColor(JuntoColors.textMuted)
                                                .lineLimit(1)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    if group.myShare > 0 {
                                        VStack(alignment: .trailing, spacing: 1) {
                                            Text("você deve")
                                                .font(.inter(11, weight: .regular))
                                                .foregroundColor(JuntoColors.orangeSave)
                                            Text(JuntoStore.formatBRL(group.myShare))
                                                .font(.inter(15, weight: .bold))
                                                .foregroundColor(JuntoColors.orangeSave)
                                        }
                                    } else if group.hasCollectivePot && group.potTarget > 0 {
                                        VStack(alignment: .trailing, spacing: 1) {
                                            Text("arrecadado")
                                                .font(.inter(11, weight: .regular))
                                                .foregroundColor(JuntoColors.pixGreen)
                                            Text(JuntoStore.formatBRL(group.potBalance))
                                                .font(.inter(15, weight: .bold))
                                                .foregroundColor(JuntoColors.pixGreen)
                                        }
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundColor(JuntoColors.textLight)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 13)
                            }

                            Divider().padding(.leading, 84)
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
                PopupCloseButton { dismiss() }
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
                        Text("Para viagens, rolês, rateios mensais ou casa")
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

// MARK: - Tela "Criar um grupo" (Fiel ao modelo limpo com cores Juntô)
private struct GroupTypePointerTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct CreateGroupScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    var initialType: String = "Viagem"
    var onCreated: ((UUID) -> Void)? = nil

    @State private var groupName: String = ""
    @State private var selectedType: String = "Viagem"
    @State private var customCategoryText: String = ""

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var coverImageData: Data? = nil

    @State private var addTripDates: Bool = true
    @State private var startDate: Date = Date()
    @State private var targetDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var hasEndDate: Bool = false

    @State private var potTotalText: String = ""
    @State private var potMode: PotRecurrenceMode = .single
    @State private var isPublicGroup: Bool = false
    @State private var maxParticipants: Int = 30
    @State private var publicUntilDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var selectedPeople: [SearchableUser] = []
    @State private var showSelectFriendsScreen: Bool = false
    @State private var showReceiptScanner: Bool = false
    @State private var scannedReceiptItems: [ComandaItem] = []

    private let primaryTypes: [(name: String, icon: String)] = [
        ("Viagem", "airplane"),
        ("Casa", "house"),
        ("Casal", "heart"),
        ("Outros", "list.bullet.rectangle")
    ]

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "d 'de' MMM 'de' yyyy"
        return f
    }()

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
        if selectedType == "Outros" && !custom.isEmpty {
            return custom
        }
        return selectedType
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Topo fiel ao modelo: X | Criar um grupo | ✓
            HStack {
                PopupCloseButton { dismiss() }
                Spacer()
                Text("Criar um grupo")
                    .font(.inter(17, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                CircleNavButton(icon: "checkmark", bgColor: JuntoColors.primary, fgColor: .white) {
                    handleCreate()
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 18)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    // Nome do grupo limpo com linha inferior (grupos usam ícone da categoria, sem foto)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nome do grupo")
                            .font(.inter(13, weight: .semibold))
                            .foregroundColor(JuntoColors.textMain)

                        TextField("Viagem a SP", text: $groupName)
                            .font(.inter(17, weight: .regular))
                            .foregroundColor(JuntoColors.textMain)

                        Rectangle()
                            .fill(groupName.isEmpty ? JuntoColors.border : JuntoColors.primary)
                            .frame(height: 1.2)
                    }

                    // Seção "Tipo" com 4 cards quadrados limpos lado a lado (sem formato balão)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tipo")
                            .font(.inter(14, weight: .semibold))
                            .foregroundColor(JuntoColors.textMain)

                        HStack(spacing: 10) {
                            ForEach(primaryTypes, id: \.name) { item in
                                let isSelected = selectedType == item.name
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.easeInOut(duration: 0.16)) {
                                        selectedType = item.name
                                    }
                                } label: {
                                    VStack(spacing: 7) {
                                        Image(systemName: item.icon)
                                            .font(.system(size: 21, weight: .regular))
                                        Text(item.name)
                                            .font(.inter(13, weight: isSelected ? .semibold : .medium))
                                            .lineLimit(1)
                                    }
                                    .foregroundColor(isSelected ? JuntoColors.primary : JuntoColors.textMain)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 76)
                                    .background(isSelected ? JuntoColors.primary.opacity(0.09) : Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(isSelected ? JuntoColors.primary : JuntoColors.border, lineWidth: isSelected ? 1.5 : 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if selectedType == "Outros" {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Categoria personalizada (opcional)")
                                    .font(.inter(12, weight: .medium))
                                    .foregroundColor(JuntoColors.textMuted)
                                TextField("Ex: Churrasco, Festa, Esporte...", text: $customCategoryText)
                                    .font(.inter(15, weight: .regular))
                                    .foregroundColor(JuntoColors.textMain)
                                Rectangle()
                                    .fill(JuntoColors.border)
                                    .frame(height: 1)
                            }
                            .padding(.top, 4)
                        }
                    }

                    // Toggle "Adicionar datas" fiel ao modelo
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(selectedType == "Viagem" ? "Adicionar datas de viagem" : "Adicionar datas")
                                .font(.inter(16, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                            Spacer()
                            Toggle("", isOn: $addTripDates)
                                .labelsHidden()
                                .tint(JuntoColors.primary)
                        }

                        Text("O Juntô lembrará os amigos de entrar, adicionar despesas e quitar com base nas datas que você definir.")
                            .font(.inter(13, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                            .fixedSize(horizontal: false, vertical: true)

                        if addTripDates {
                            HStack(spacing: 18) {
                                // Iniciar
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Iniciar")
                                        .font(.inter(12, weight: .medium))
                                        .foregroundColor(JuntoColors.textMuted)

                                    ZStack {
                                        HStack {
                                            Text(Self.shortDateFormatter.string(from: startDate))
                                                .font(.inter(14, weight: .regular))
                                                .foregroundColor(JuntoColors.textMain)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.85)
                                            Spacer()
                                            Image(systemName: "calendar")
                                                .font(.system(size: 16, weight: .regular))
                                                .foregroundColor(JuntoColors.textMain)
                                        }

                                        DatePicker("", selection: $startDate, displayedComponents: .date)
                                            .labelsHidden()
                                            .environment(\.locale, Locale(identifier: "pt_BR"))
                                            .blendMode(.destinationOver)
                                    }

                                    Rectangle()
                                        .fill(JuntoColors.border)
                                        .frame(height: 1)
                                }
                                .frame(maxWidth: .infinity)

                                // Encerrar
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Encerrar")
                                        .font(.inter(12, weight: .medium))
                                        .foregroundColor(JuntoColors.textMuted)

                                    ZStack {
                                        HStack {
                                            Text(hasEndDate ? Self.shortDateFormatter.string(from: targetDate) : "")
                                                .font(.inter(14, weight: .regular))
                                                .foregroundColor(JuntoColors.textMain)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.85)
                                            Spacer()
                                            Image(systemName: "calendar")
                                                .font(.system(size: 16, weight: .regular))
                                                .foregroundColor(JuntoColors.textMain)
                                        }

                                        DatePicker("", selection: $targetDate, in: startDate..., displayedComponents: .date)
                                            .labelsHidden()
                                            .environment(\.locale, Locale(identifier: "pt_BR"))
                                            .blendMode(.destinationOver)
                                            .onChange(of: targetDate) { _, _ in
                                                hasEndDate = true
                                            }
                                    }

                                    Rectangle()
                                        .fill(JuntoColors.border)
                                        .frame(height: 1)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.top, 8)
                        }
                    }

                    Divider().opacity(0.6)

                    // Modelo de cobrança do pote (seletor segmentado limpo sem ícones) + valor e membros
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Frequência da meta")
                                .font(.inter(13, weight: .semibold))
                                .foregroundColor(JuntoColors.textMain)

                            HStack(spacing: 4) {
                                ForEach(PotRecurrenceMode.allCases, id: \.self) { mode in
                                    let active = potMode == mode
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                                            potMode = mode
                                        }
                                    } label: {
                                        VStack(spacing: 2) {
                                            Text(mode == .single ? "Valor único" : "Mensal")
                                                .font(.inter(14, weight: active ? .semibold : .medium))
                                                .foregroundColor(active ? JuntoColors.primary : JuntoColors.textMuted)
                                            Text(mode == .single ? "Dividido uma vez" : "Parcelas por mês")
                                                .font(.inter(11, weight: .regular))
                                                .foregroundColor(JuntoColors.textMuted)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(active ? Color.white : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .shadow(color: active ? Color.black.opacity(0.06) : .clear, radius: 4, y: 1)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(4)
                            .background(JuntoColors.surfaceSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        HStack(alignment: .bottom, spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Meta do pote (opcional)")
                                    .font(.inter(12, weight: .medium))
                                    .foregroundColor(JuntoColors.textMuted)
                                HStack(spacing: 6) {
                                    Text("R$")
                                        .font(.inter(16, weight: .medium))
                                        .foregroundColor(JuntoColors.textMuted)
                                    TextField("0,00", text: $potTotalText)
                                        .font(.inter(17, weight: .regular))
                                        .foregroundColor(JuntoColors.textMain)
                                        .keyboardType(.decimalPad)
                                }
                                Rectangle()
                                    .fill(JuntoColors.border)
                                    .frame(height: 1)
                            }

                            Button {
                                showReceiptScanner = true
                            } label: {
                                Image(systemName: "doc.viewfinder")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(JuntoColors.primary)
                                    .frame(width: 40, height: 40)
                            }
                        }

                        if !scannedReceiptItems.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(JuntoColors.pixGreen)
                                    .font(.system(size: 13))
                                Text("\(scannedReceiptItems.count) itens da comanda")
                                    .font(.inter(13, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                                Spacer()
                                Button("Limpar") {
                                    scannedReceiptItems = []
                                    potTotalText = ""
                                }
                                .font(.inter(12, weight: .medium))
                                .foregroundColor(JuntoColors.danger)
                            }
                        }

                        // Membros (botão somente ícone sem texto)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Membros (\(totalPeopleCount))")
                                    .font(.inter(14, weight: .semibold))
                                    .foregroundColor(JuntoColors.textMain)
                                Spacer()
                                Button {
                                    showSelectFriendsScreen = true
                                } label: {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(JuntoColors.primary)
                                        .frame(width: 36, height: 36)
                                        .background(JuntoColors.primary.opacity(0.09))
                                        .clipShape(Circle())
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

                        if potTotalValue > 0 {
                            HStack {
                                Text(potMode == .monthly ? "Parcela (\(activeMonthsCount)x) por pessoa" : "Cota por pessoa")
                                    .font(.inter(13, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                Spacer()
                                Text(JuntoStore.formatBRL(quotaPerPerson))
                                    .font(.inter(18, weight: .bold))
                                    .foregroundColor(JuntoColors.pixGreen)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            if primaryTypes.contains(where: { $0.name == initialType }) {
                selectedType = initialType
            } else {
                selectedType = "Outros"
                customCategoryText = initialType
            }
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
                PopupCloseButton { dismiss() }
                Spacer()
                Text("Adicionar membros")
                    .font(.inter(17, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                CircleNavButton(icon: "checkmark", bgColor: JuntoColors.primary, fgColor: .white) {
                    dismiss()
                }
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
    @State private var showGroupSettings = false
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
        store.resolvedGroupIndex(for: groupId)
    }

    var body: some View {
        if let idx = groupIndex {
            let group = store.groups[idx]
            let resolvedId = group.id
            let canAddExpenses = store.canCurrentUserAddExpenses(in: group)
            let activeMonthIdx = min(max(0, group.selectedMonthIndex), max(0, group.monthlyCycles.count - 1))
            let monthPercent = group.monthCompletionPercent(at: activeMonthIdx)
            let overallPercent = group.overallGoalPercent
            let paidCount = group.paidParticipantsCount(at: activeMonthIdx)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Topo (Fechar | Nome do Grupo | Configurações)
                    HStack(spacing: 10) {
                        PopupCloseButton { dismiss() }
                        Spacer()
                        Button {
                            showGroupSettings = true
                        } label: {
                            Text(group.title)
                                .font(.inter(17, weight: .bold))
                                .foregroundColor(JuntoColors.textMain)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button {
                            showGroupSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(JuntoColors.textMain)
                                .frame(width: 36, height: 36)
                        }
                    }
                    .padding(.top, 16)

                    // Cabeçalho limpo sem foto de capa (sempre ícone da categoria + resumo)
                    HStack(spacing: 12) {
                        GroupCategoryIconTile(category: group.category, size: 46)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(group.category) · \(group.participants.count) pessoa(s)")
                                .font(.inter(12, weight: .medium))
                                .foregroundColor(JuntoColors.textMuted)
                            Text("Total gasto: \(JuntoStore.formatBRL(group.totalSpent))")
                                .font(.inter(16, weight: .bold))
                                .foregroundColor(JuntoColors.textMain)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)

                    // Pix rápido fixado (flat limpo: ícone oficial BC + valor + chave + copiar)
                    if group.pixQuickPinEnabled {
                        let organizer = store.organizerPixInfo(for: group)
                        let quotaVal = group.dynamicQuotaPerPerson
                        VStack(spacing: 0) {
                            Divider().opacity(0.55)
                            HStack(spacing: 12) {
                                PixOfficialIcon(size: 18, color: Color(hex: "#32BCAD"))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(quotaVal > 0 ? "\(JuntoStore.formatBRL(quotaVal)) por pessoa" : "Pix do organizador")
                                        .font(.inter(13, weight: .semibold))
                                        .foregroundColor(JuntoColors.textMain)
                                        .lineLimit(1)
                                    Text(organizer.pixKey.isEmpty ? "Chave Pix não cadastrada" : organizer.pixKey)
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }

                                Spacer(minLength: 8)

                                if !organizer.pixKey.isEmpty {
                                    Button {
                                        UIPasteboard.general.string = organizer.pixKey
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        store.showToast("Chave Pix copiada!", icon: "doc.on.doc")
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(JuntoColors.primary)
                                            .frame(width: 34, height: 34)
                                    }
                                }
                            }
                            .padding(.vertical, 10)
                            Divider().opacity(0.55)
                        }
                    }

                    // Lista de participantes rolável para o lado (botão adicionar somente ícone!)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Participantes (\(group.participants.count))")
                                .font(.inter(14, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                            Spacer()
                            Button {
                                showAddMemberScreen = true
                            } label: {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(JuntoColors.primary)
                                    .frame(width: 36, height: 36)
                                    .background(JuntoColors.primary.opacity(0.09))
                                    .clipShape(Circle())
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
                                                Text("\(JuntoStore.formatBRL(participant.quotaAmount)) · Aguardando confirmação")
                                                    .font(.inter(12, weight: .medium))
                                                    .foregroundColor(JuntoColors.orangeSave)
                                            } else {
                                                Text(JuntoStore.formatBRL(participant.quotaAmount))
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
                                                    .background(JuntoColors.primary)
                                                    .clipShape(Capsule())
                                                } else {
                                                    Text("Aguardando")
                                                        .font(.inter(12, weight: .medium))
                                                        .foregroundColor(JuntoColors.orangeSave)
                                                }
                                            } else {
                                                Button("Pagar") {
                                                    pendingPaymentSheet = GroupPaymentRequest(
                                                        title: "\(group.title)\(monthLabelText)",
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
                                        Image(systemName: showAddExpenseForm ? "xmark" : "plus")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(JuntoColors.primary)
                                            .frame(width: 30, height: 30)
                                            .background(JuntoColors.surfaceSubtle)
                                            .clipShape(Circle())
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

                                HStack(spacing: 16) {
                                    Spacer()
                                    CircleNavButton(icon: "xmark", bgColor: JuntoColors.surfaceSubtle, fgColor: JuntoColors.textMain) {
                                        withAnimation { showAddExpenseForm = false }
                                    }
                                    CircleNavButton(icon: "checkmark", bgColor: JuntoColors.primary, fgColor: .white) {
                                        let val = Double(expenseAmount.replacingOccurrences(of: ",", with: ".")) ?? 0
                                        store.addExpenseToGroup(groupId: groupId, name: expenseName, totalAmount: val, payFromPot: payFromPot)
                                        expenseName = ""
                                        expenseAmount = ""
                                        payFromPot = false
                                        showAddExpenseForm = false
                                    }
                                }
                                .padding(.top, 2)
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
                                                Text(JuntoStore.formatBRL(shareForThisItem))
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
                GroupChatScreen(groupId: resolvedId)
                    .environmentObject(store)
            }
            .alert("Excluir \"\(group.title)\"?", isPresented: $showDeleteGroupConfirm) {
                Button("Cancelar", role: .cancel) {}
                Button("Excluir grupo", role: .destructive) {
                    let targetId = resolvedId
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        store.deleteGroup(groupId: targetId)
                    }
                }
            } message: {
                Text("O grupo será excluído, mas seu histórico de pagamentos em Meus Gastos continuará salvo.")
            }
            .fullScreenCover(isPresented: $showAddMemberScreen) {
                AddGroupMemberScreen(groupId: resolvedId)
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
                            store.memberMarkQuotaAsPaid(groupId: resolvedId, participantId: pid, monthIndex: activeMonthIdx)
                        } else {
                            store.memberMarkGroupExpensesAsPaid(groupId: resolvedId, amount: request.amount)
                        }
                        pendingPaymentSheet = nil
                        // Ao enviar e confirmar, abre o grupo (chat) já com o comprovante e valor descontado se for dono
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                            showGroupChat = true
                        }
                    },
                    onSendReceipt: { imgData, fileName in
                        store.sendGroupReceipt(groupId: resolvedId, amount: request.amount, imageData: imgData, fileName: fileName)
                    }
                )
                .presentationDetents([.height(470), .large])
                .presentationCornerRadius(20)
                .presentationBackground(Color.white)
            }
            .fullScreenCover(isPresented: $showGroupSettings) {
                GroupSettingsScreen(groupId: resolvedId, onLeaveOrDelete: {
                    showGroupSettings = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        dismiss()
                    }
                })
                .environmentObject(store)
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
                    if let gIdx = store.resolvedGroupIndex(for: resolvedId),
                       let iIdx = store.groups[gIdx].comandaItems.firstIndex(where: { $0.id == itm.id }) {
                        store.groups[gIdx].comandaItems[iIdx] = updatedItem
                    }
                    selectedItemForConsumers = nil
                }
                .presentationDetents([.medium])
            }
        } else {
            Color.white
                .ignoresSafeArea()
                .onAppear { dismiss() }
        }
    }
}

// MARK: - Tela "Configurações de grupo" (Identidade própria Juntô + Agente Juntô IA e funções Pro)
struct GroupSettingsScreen: View {
    @EnvironmentObject var store: JuntoStore
    let groupId: UUID
    var onLeaveOrDelete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var showAddMemberScreen: Bool = false
    @State private var showEditGroupAlert: Bool = false
    @State private var editedTitle: String = ""
    @State private var selectedParticipantForAction: GroupParticipant? = nil
    @State private var showLeaveOrDeleteConfirm: Bool = false
    @State private var showProPaywall: Bool = false

    private var groupIndex: Int? {
        store.resolvedGroupIndex(for: groupId)
    }

    var body: some View {
        if let idx = groupIndex {
            let group = store.groups[idx]
            let resolvedId = group.id
            let isOwner = store.isCurrentUserOwner(in: group)
            let inviteText = "Entre no grupo \"\(group.title)\" no Juntô para dividir gastos e pagar no Pix: https://junto.app/baixar"
            let organizer = store.organizerPixInfo(for: group)
            let pendingMembers = group.participants.filter { !$0.hasPaid && $0.quotaAmount > 0 }
            let previewText = store.composeAIReminderMessage(
                for: group,
                pendingParticipants: pendingMembers.isEmpty ? Array(group.participants.prefix(1)) : pendingMembers,
                daysLeft: max(1, group.aiReminderDaysBefore)
            )

            VStack(alignment: .leading, spacing: 0) {
                // Topo limpo: < | Configurações de grupo
                HStack {
                    CircleNavButton(icon: "chevron.left") { dismiss() }
                    Spacer()
                    Text("Configurações de grupo")
                        .font(.inter(17, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 12)

                Divider().opacity(0.6)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Cabeçalho do grupo: ícone da categoria + nome + Editar
                        HStack(spacing: 14) {
                            GroupCategoryIconTile(category: group.category, size: 52)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.title)
                                    .font(.inter(17, weight: .bold))
                                    .foregroundColor(JuntoColors.textMain)
                                    .lineLimit(2)
                                Text("\(group.category) · \(group.participants.count) participantes")
                                    .font(.inter(12, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                            }

                            Spacer()

                            Button("Editar") {
                                editedTitle = group.title
                                showEditGroupAlert = true
                            }
                            .font(.inter(15, weight: .semibold))
                            .foregroundColor(JuntoColors.primary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)

                        Divider().opacity(0.6)

                        // Seção: Membros do grupo
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Membros do grupo")
                                .font(.inter(13, weight: .semibold))
                                .foregroundColor(JuntoColors.textMain)
                                .padding(.horizontal, 20)
                                .padding(.top, 18)
                                .padding(.bottom, 6)

                            Button {
                                showAddMemberScreen = true
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 20, weight: .regular))
                                        .foregroundColor(JuntoColors.textMain)
                                        .frame(width: 34)
                                    Text("Adicionar pessoas ao grupo")
                                        .font(.inter(16, weight: .regular))
                                        .foregroundColor(JuntoColors.textMain)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            ShareLink(item: inviteText) {
                                HStack(spacing: 16) {
                                    Image(systemName: "link")
                                        .font(.system(size: 20, weight: .regular))
                                        .foregroundColor(JuntoColors.textMain)
                                        .frame(width: 34)
                                    Text("Convidar via link")
                                        .font(.inter(16, weight: .regular))
                                        .foregroundColor(JuntoColors.textMain)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            ForEach(group.participants) { participant in
                                Button {
                                    if participant.role != .owner {
                                        selectedParticipantForAction = participant
                                    }
                                } label: {
                                    HStack(spacing: 14) {
                                        GeometricAvatarView(seed: participant.username, size: 42)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(participant.name)
                                                .font(.inter(16, weight: .medium))
                                                .foregroundColor(JuntoColors.textMain)
                                            Text(participant.username.hasPrefix("@") ? participant.username : "@\(participant.username)")
                                                .font(.inter(13, weight: .regular))
                                                .foregroundColor(JuntoColors.textMuted)
                                        }

                                        Spacer()

                                        if participant.hasPaid || participant.quotaAmount <= 0 {
                                            Text("quitado")
                                                .font(.inter(13, weight: .regular))
                                                .foregroundColor(JuntoColors.textMuted)
                                        } else {
                                            Text(JuntoStore.formatBRL(participant.quotaAmount))
                                                .font(.inter(13, weight: .semibold))
                                                .foregroundColor(JuntoColors.orangeSave)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Divider().opacity(0.6).padding(.top, 14)

                        // Seção exclusiva Juntô: Automação com IA e Controles do Grupo
                        VStack(alignment: .leading, spacing: 22) {
                            Text("Automação e controles do grupo")
                                .font(.inter(13, weight: .semibold))
                                .foregroundColor(JuntoColors.textMain)
                                .padding(.top, 20)

                            // 1. AGENTE JUNTÔ IA — Lembretes automáticos no app próximo ao vencimento (PRO)
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .center, spacing: 14) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 19, weight: .medium))
                                        .foregroundColor(JuntoColors.primary)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text("Agente Juntô IA")
                                                .font(.inter(16, weight: .semibold))
                                                .foregroundColor(JuntoColors.textMain)
                                            proBadgePill
                                        }
                                        Text("Lembretes automáticos de vencimento")
                                            .font(.inter(12, weight: .regular))
                                            .foregroundColor(JuntoColors.textMuted)
                                    }

                                    Spacer()

                                    Toggle("", isOn: Binding(
                                        get: {
                                            guard let liveIdx = store.resolvedGroupIndex(for: resolvedId) else { return false }
                                            return store.groups[liveIdx].aiReminderEnabled
                                        },
                                        set: { newVal in
                                            guard let liveIdx = store.resolvedGroupIndex(for: resolvedId) else { return }
                                            if newVal && !store.user.isPro {
                                                showProPaywall = true
                                            } else {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    store.groups[liveIdx].aiReminderEnabled = newVal
                                                }
                                                store.saveGroupProSettings(for: resolvedId)
                                                if newVal {
                                                    store.showToast("Agente Juntô IA ativado neste grupo!", icon: "sparkles")
                                                }
                                            }
                                        }
                                    ))
                                    .labelsHidden()
                                    .tint(JuntoColors.primary)
                                }

                                Text("Próximo ao vencimento, nosso agente de IA envia uma mensagem automática no próprio app para quem ainda não pagou.")
                                    .font(.inter(13, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                    .padding(.leading, 42)

                                if group.aiReminderEnabled && store.user.isPro {
                                    VStack(alignment: .leading, spacing: 12) {
                                        // Dias antes do vencimento
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Avisar antes do vencimento")
                                                .font(.inter(12, weight: .semibold))
                                                .foregroundColor(JuntoColors.textMain)
                                            HStack(spacing: 8) {
                                                ForEach([1, 2, 3, 5], id: \.self) { days in
                                                    let active = group.aiReminderDaysBefore == days
                                                    Button {
                                                        if let liveIdx = store.resolvedGroupIndex(for: resolvedId) {
                                                            store.groups[liveIdx].aiReminderDaysBefore = days
                                                            store.saveGroupProSettings(for: resolvedId)
                                                        }
                                                    } label: {
                                                        Text(days == 1 ? "1 dia" : "\(days) dias")
                                                            .font(.inter(12, weight: active ? .semibold : .regular))
                                                            .foregroundColor(active ? .white : JuntoColors.textMain)
                                                            .padding(.horizontal, 12)
                                                            .frame(height: 30)
                                                            .background(active ? JuntoColors.primary : JuntoColors.surfaceSubtle)
                                                            .clipShape(Capsule())
                                                    }
                                                }
                                            }
                                        }

                                        // Tom do Agente IA
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Estilo da mensagem")
                                                .font(.inter(12, weight: .semibold))
                                                .foregroundColor(JuntoColors.textMain)
                                            HStack(spacing: 8) {
                                                ForEach(AIReminderTone.allCases, id: \.self) { tone in
                                                    let active = group.aiReminderTone == tone
                                                    Button {
                                                        if let liveIdx = store.resolvedGroupIndex(for: resolvedId) {
                                                            store.groups[liveIdx].aiReminderTone = tone
                                                            store.saveGroupProSettings(for: resolvedId)
                                                        }
                                                    } label: {
                                                        Text(tone.rawValue)
                                                            .font(.inter(12, weight: active ? .semibold : .regular))
                                                            .foregroundColor(active ? .white : JuntoColors.textMain)
                                                            .padding(.horizontal, 12)
                                                            .frame(height: 30)
                                                            .background(active ? JuntoColors.primary : JuntoColors.surfaceSubtle)
                                                            .clipShape(Capsule())
                                                    }
                                                }
                                            }
                                        }

                                        // Prévia ao vivo da mensagem do agente
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Prévia da Juntô IA")
                                                .font(.inter(11, weight: .semibold))
                                                .foregroundColor(JuntoColors.primary)
                                            Text(previewText)
                                                .font(.inter(12.5, weight: .regular))
                                                .foregroundColor(JuntoColors.textMain)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(JuntoColors.primary.opacity(0.06))
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                        // Botão para disparar o lembrete no app imediatamente
                                        Button {
                                            store.triggerAIReminderNow(for: resolvedId)
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "paperplane.fill")
                                                    .font(.system(size: 12, weight: .semibold))
                                                Text("Enviar lembrete agora no app")
                                                    .font(.inter(13, weight: .semibold))
                                            }
                                            .foregroundColor(JuntoColors.primary)
                                            .padding(.horizontal, 14)
                                            .frame(height: 36)
                                            .background(JuntoColors.primary.opacity(0.10))
                                            .clipShape(Capsule())
                                        }
                                    }
                                    .padding(.leading, 42)
                                    .padding(.top, 4)
                                }
                            }

                            // 2. Resumo automático de fechamento pela IA (PRO)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .center, spacing: 14) {
                                    Image(systemName: "checkmark.seal")
                                        .font(.system(size: 19, weight: .regular))
                                        .foregroundColor(JuntoColors.primary)
                                        .frame(width: 28)

                                    HStack(spacing: 6) {
                                        Text("Fechamento IA")
                                            .font(.inter(16, weight: .regular))
                                            .foregroundColor(JuntoColors.textMain)
                                            .lineLimit(1)
                                        proBadgePill
                                    }

                                    Spacer()

                                    Toggle("", isOn: Binding(
                                        get: {
                                            guard let liveIdx = store.resolvedGroupIndex(for: resolvedId) else { return false }
                                            return store.groups[liveIdx].autoClosureSummaryEnabled
                                        },
                                        set: { newVal in
                                            guard let liveIdx = store.resolvedGroupIndex(for: resolvedId) else { return }
                                            if newVal && !store.user.isPro {
                                                showProPaywall = true
                                            } else {
                                                store.groups[liveIdx].autoClosureSummaryEnabled = newVal
                                                store.saveGroupProSettings(for: resolvedId)
                                            }
                                        }
                                    ))
                                    .labelsHidden()
                                    .tint(JuntoColors.primary)
                                }

                                Text("Quando o grupo bater 100% da meta, a Juntô IA publica automaticamente o resumo final de quitação no chat.")
                                    .font(.inter(13, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                    .padding(.leading, 42)
                            }

                            // 3. Pix rápido fixado no topo do grupo + chave Pix nos lembretes (PRO)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .center, spacing: 14) {
                                    PixOfficialIcon(size: 20, color: Color(hex: "#32BCAD"))
                                        .frame(width: 28)

                                    HStack(spacing: 6) {
                                        Text("Pix rápido")
                                            .font(.inter(16, weight: .regular))
                                            .foregroundColor(JuntoColors.textMain)
                                            .lineLimit(1)
                                        proBadgePill
                                    }

                                    Spacer()

                                    Toggle("", isOn: Binding(
                                        get: {
                                            guard let liveIdx = store.resolvedGroupIndex(for: resolvedId) else { return false }
                                            return store.groups[liveIdx].pixQuickPinEnabled
                                        },
                                        set: { newVal in
                                            guard let liveIdx = store.resolvedGroupIndex(for: resolvedId) else { return }
                                            if newVal && !store.user.isPro {
                                                showProPaywall = true
                                            } else {
                                                store.groups[liveIdx].pixQuickPinEnabled = newVal
                                                store.saveGroupProSettings(for: resolvedId)
                                            }
                                        }
                                    ))
                                    .labelsHidden()
                                    .tint(JuntoColors.primary)
                                }

                                Text(organizer.pixKey.isEmpty
                                     ? "Fixa no topo do grupo a chave Pix e o valor por pessoa."
                                     : "Fixa no topo do grupo a chave Pix (\(organizer.pixKey)) e o valor por pessoa.")
                                    .font(.inter(13, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                    .padding(.leading, 42)
                            }

                            // 4. Trava de despesas somente para admins (desmarcado = todos podem lançar)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .center, spacing: 14) {
                                    Image(systemName: "lock.shield")
                                        .font(.system(size: 18, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                        .frame(width: 28)

                                    Text("Somente admins lançam")
                                        .font(.inter(16, weight: .regular))
                                        .foregroundColor(JuntoColors.textMain)
                                        .lineLimit(1)

                                    Spacer()

                                    Toggle("", isOn: Binding(
                                        get: {
                                            guard let liveIdx = store.resolvedGroupIndex(for: resolvedId) else { return true }
                                            return store.groups[liveIdx].restrictExpensesToAdmins
                                        },
                                        set: { newVal in
                                            guard let liveIdx = store.resolvedGroupIndex(for: resolvedId) else { return }
                                            store.groups[liveIdx].restrictExpensesToAdmins = newVal
                                            store.saveGroupProSettings(for: resolvedId)
                                        }
                                    ))
                                    .labelsHidden()
                                    .tint(JuntoColors.primary)
                                }

                                Text("Ativado: apenas dono e admins lançam despesas. Desativado: todos os participantes podem lançar gastos.")
                                    .font(.inter(13, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                    .padding(.leading, 42)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Ação final: Sair / Excluir grupo
                        Button {
                            showLeaveOrDeleteConfirm = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 19, weight: .regular))
                                    .frame(width: 28)
                                Text(isOwner ? "Excluir grupo" : "Sair do grupo")
                                    .font(.inter(16, weight: .medium))
                                Spacer()
                            }
                            .foregroundColor(JuntoColors.danger)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 24)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 30)
                }
            }
            .background(Color.white.ignoresSafeArea())
            .fullScreenCover(isPresented: $showAddMemberScreen) {
                AddGroupMemberScreen(groupId: resolvedId)
                    .environmentObject(store)
            }
            .fullScreenCover(isPresented: $showProPaywall) {
                JuntoProSubscriptionScreen()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showEditGroupAlert) {
                EditGroupNameSheet(initialTitle: editedTitle) { newTitle in
                    if let gIdx = store.resolvedGroupIndex(for: resolvedId) {
                        store.groups[gIdx].title = newTitle
                        store.showToast("Nome do grupo atualizado.", icon: "checkmark.circle.fill")
                    }
                }
                .presentationDetents([.height(220)])
                .presentationCornerRadius(20)
                .presentationBackground(Color.white)
            }
            .alert(isOwner ? "Excluir \"\(group.title)\"?" : "Sair de \"\(group.title)\"?", isPresented: $showLeaveOrDeleteConfirm) {
                Button("Cancelar", role: .cancel) {}
                Button(isOwner ? "Excluir grupo" : "Sair do grupo", role: .destructive) {
                    let targetId = resolvedId
                    let ownerFlag = isOwner
                    // Fecha ambas as telas ANTES de remover o grupo do array para nunca dar crash de índice!
                    onLeaveOrDelete?()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        if ownerFlag {
                            store.deleteGroup(groupId: targetId)
                        } else {
                            store.leaveGroup(groupId: targetId)
                        }
                    }
                }
            } message: {
                Text(isOwner
                     ? "O grupo será excluído, mas seu histórico de pagamentos continuará salvo em Meus Gastos."
                     : "Você sairá deste grupo e seu histórico de pagamentos continuará salvo em Meus Gastos.")
            }
            .sheet(item: $selectedParticipantForAction) { participant in
                ParticipantActionSheet(
                    participant: participant,
                    onToggleAdmin: {
                        store.toggleParticipantAdmin(groupId: resolvedId, participantId: participant.id)
                        selectedParticipantForAction = nil
                    },
                    onRemove: {
                        store.removeParticipantFromGroup(groupId: resolvedId, participantId: participant.id)
                        selectedParticipantForAction = nil
                    }
                )
                .presentationDetents([.height(270)])
                .presentationCornerRadius(20)
            }
        } else {
            Color.white
                .ignoresSafeArea()
                .onAppear { dismiss() }
        }
    }

    private var proBadgePill: some View {
        Text("PRO")
            .font(.inter(10, weight: .bold))
            .foregroundColor(JuntoColors.primary)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(JuntoColors.primary.opacity(0.10))
            .clipShape(Capsule())
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
                PopupCloseButton { dismiss() }
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
                                            if !isFriend {
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

// MARK: - Sheet Flat de Edição de Nome do Grupo (Input padronizado + X / ✓)
struct EditGroupNameSheet: View {
    let initialTitle: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var titleText: String = ""

    var body: some View {
        let trimmed = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                PopupCloseButton { dismiss() }
                Spacer()
                Text("Editar nome do grupo")
                    .font(.inter(16, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                CircleNavButton(
                    icon: "checkmark",
                    bgColor: trimmed.isEmpty ? JuntoColors.surfaceSubtle : JuntoColors.primary,
                    fgColor: trimmed.isEmpty ? JuntoColors.textLight : .white
                ) {
                    guard !trimmed.isEmpty else { return }
                    onSave(trimmed)
                    dismiss()
                }
                .disabled(trimmed.isEmpty)
            }
            .padding(.top, 14)

            CleanOutlineInput(
                label: "Nome do grupo",
                placeholder: "Ex: Viagem para Pipa",
                text: $titleText
            )

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color.white.ignoresSafeArea())
        .presentationBackground(Color.white)
        .onAppear {
            titleText = initialTitle
        }
    }
}

// MARK: - Sheet de Pagamento Direto via Pix (100% Flat Limpo + Ícone Oficial BC + Comprovante)
struct OrganizerPixPaymentSheet: View {
    let title: String
    let organizerName: String
    let organizerPixKey: String
    let amount: Double
    let onMarkAsPaid: () -> Void
    var onSendReceipt: ((Data?, String?) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var copiedKey = false
    @State private var timeRemaining = 300 // 5 minutos
    @State private var timer: Timer? = nil

    // Anexo de comprovante (Foto ou Arquivo)
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showFileImporter = false
    @State private var attachedData: Data? = nil
    @State private var attachedFileName: String? = nil

    private var formattedTime: String {
        let mins = timeRemaining / 60
        let secs = timeRemaining % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func confirmPayment() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onSendReceipt?(attachedData, attachedFileName ?? (attachedData != nil ? "comprovante.jpg" : nil))
        onMarkAsPaid()
        dismiss()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Topo 100% flat branco: X | Pagar via Pix | ✓
            HStack {
                PopupCloseButton { dismiss() }
                Spacer()
                Text("Pagar via Pix")
                    .font(.inter(16, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                CircleNavButton(icon: "checkmark", bgColor: JuntoColors.primary, fgColor: .white) {
                    confirmPayment()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 14)

            Divider().opacity(0.6)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Valor centralizado limpo com ícone oficial flat do Pix (Banco Central)
                    VStack(spacing: 8) {
                        PixOfficialIcon(size: 32, color: Color(hex: "#32BCAD"))
                            .padding(.top, 20)

                        Text(JuntoStore.formatBRL(amount))
                            .font(.inter(32, weight: .bold))
                            .foregroundColor(JuntoColors.textMain)

                        Text("\(title) · \(organizerName)")
                            .font(.inter(13, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                            .lineLimit(1)

                        Text(timeRemaining > 0 ? "Válido por \(formattedTime)" : "Chave expirada")
                            .font(.inter(11, weight: .medium))
                            .foregroundColor(timeRemaining < 60 ? JuntoColors.danger : JuntoColors.textLight)
                            .monospacedDigit()
                            .padding(.bottom, 18)
                    }
                    .frame(maxWidth: .infinity)

                    Divider().opacity(0.6)

                    // Linha flat da Chave Pix + botão copiar
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Chave Pix")
                                .font(.inter(12, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                            Text(organizerPixKey.isEmpty ? "Chave não cadastrada" : organizerPixKey)
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundColor(JuntoColors.textMain)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .textSelection(.enabled)
                        }

                        Spacer(minLength: 8)

                        if !organizerPixKey.isEmpty {
                            Button {
                                UIPasteboard.general.string = organizerPixKey
                                copiedKey = true
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedKey = false }
                            } label: {
                                Image(systemName: copiedKey ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(copiedKey ? .white : JuntoColors.primary)
                                    .frame(width: 38, height: 38)
                                    .background(copiedKey ? Color(hex: "#32BCAD") : JuntoColors.surfaceSubtle)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(JuntoTapBounceStyle(scaleAmount: 0.94))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    Divider().opacity(0.6)

                    // Linha flat de Comprovante (sem caixa verde, sem texto poluído)
                    VStack(spacing: 10) {
                        HStack(spacing: 12) {
                            Image(systemName: attachedFileName != nil ? "checkmark.circle" : "paperclip")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(attachedFileName != nil ? JuntoColors.primary : JuntoColors.textMuted)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(attachedFileName ?? "Anexar comprovante")
                                    .font(.inter(14, weight: attachedFileName != nil ? .medium : .regular))
                                    .foregroundColor(JuntoColors.textMain)
                                    .lineLimit(1)
                                if attachedFileName == nil {
                                    Text("Opcional · foto ou arquivo")
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                }
                            }

                            Spacer()

                            if attachedFileName != nil {
                                Button {
                                    attachedData = nil
                                    attachedFileName = nil
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(JuntoColors.textMuted)
                                        .frame(width: 34, height: 34)
                                }
                            } else {
                                HStack(spacing: 8) {
                                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                        Image(systemName: "photo")
                                            .font(.system(size: 15, weight: .regular))
                                            .foregroundColor(JuntoColors.primary)
                                            .frame(width: 36, height: 36)
                                            .background(JuntoColors.surfaceSubtle)
                                            .clipShape(Circle())
                                    }

                                    Button {
                                        showFileImporter = true
                                    } label: {
                                        Image(systemName: "doc")
                                            .font(.system(size: 15, weight: .regular))
                                            .foregroundColor(JuntoColors.primary)
                                            .frame(width: 36, height: 36)
                                            .background(JuntoColors.surfaceSubtle)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }

                        if let data = attachedData, let uiImg = UIImage(data: data) {
                            Image(uiImage: uiImg)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 110)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    Divider().opacity(0.6)

                    // Botão único limpo para Enviar e Confirmar
                    Button {
                        confirmPayment()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                            Text(attachedData != nil || attachedFileName != nil ? "Enviar e confirmar" : "Confirmar pagamento")
                                .font(.inter(15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(JuntoColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(JuntoTapBounceStyle(scaleAmount: 0.98))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 22)
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
        .presentationBackground(Color.white)
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
                PopupCloseButton { dismiss() }
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
                PopupCloseButton { dismiss() }
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

                            HStack(spacing: 14) {
                                Spacer()
                                CircleNavButton(icon: "xmark", bgColor: JuntoColors.surfaceSubtle, fgColor: JuntoColors.textMain) {
                                    showDepositForm = false
                                }
                                CircleNavButton(icon: "checkmark", bgColor: JuntoColors.primary, fgColor: .white) {
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
        VStack(spacing: 0) {
            // Topo 100% flat branco com X e ✓ (sem glass)
            HStack {
                PopupCloseButton { dismiss() }
                Spacer()
                Text("Quem consumiu?")
                    .font(.inter(16, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                CircleNavButton(icon: "checkmark", bgColor: JuntoColors.primary, fgColor: .white) {
                    var updated = item
                    updated.assignedUsernames = currentAssigned
                    onSave(updated)
                    dismiss()
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider().opacity(0.6)

            VStack(spacing: 14) {
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
            }
        }
        .background(Color.white.ignoresSafeArea())
        .presentationBackground(Color.white)
        .onAppear {
            currentAssigned = item.assignedUsernames
        }
    }
}
