import SwiftUI

/// Tela "Gastos pessoais": gráficos por categoria (Churrasco, Viagens, Casa, etc.), quanto você já pagou e detalhamento ao tocar em cada categoria ou gasto
struct MyExpensesAnalyticsScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPeriod: String = "Geral"
    @State private var selectedCategoryFilter: String? = nil
    @State private var selectedStatusFilter: ExpenseStatusFilter = .all
    @State private var selectedExpenseForDetail: PersonalExpenseRecord? = nil
    @State private var selectedCategoryForDetail: CategorySlice? = nil
    @State private var showAddExpenseSheet = false

    enum ExpenseStatusFilter: String, CaseIterable {
        case all = "Todos"
        case paid = "Pagos"
        case pending = "Pendentes"
    }

    struct CategorySlice: Identifiable, Hashable {
        let id: String
        let category: String
        let amount: Double
        let paidAmount: Double
        let pendingAmount: Double
        let percentage: Double
        let count: Int
        let colorHex: String
        let icon: String

        var color: Color { Color(hex: colorHex) }
        var paidRatio: Double { amount > 0 ? min(1.0, paidAmount / amount) : 0 }
    }

    private var allExpenses: [PersonalExpenseRecord] {
        store.allTrackedPersonalExpenses
    }

    private var availablePeriods: [String] {
        var months: [String] = []
        for item in allExpenses {
            if !months.contains(item.monthKey) {
                months.append(item.monthKey)
            }
        }
        let current = JuntoStore.currentMonthKey()
        if !months.contains(current) {
            months.insert(current, at: 0)
        }
        return ["Geral"] + months
    }

    private var periodExpenses: [PersonalExpenseRecord] {
        if selectedPeriod == "Geral" {
            return allExpenses
        }
        return allExpenses.filter { $0.monthKey == selectedPeriod }
    }

    private var totalAmount: Double {
        periodExpenses.reduce(0) { $0 + $1.amount }
    }

    private var paidAmount: Double {
        periodExpenses.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
    }

    private var pendingAmount: Double {
        periodExpenses.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }

    private var paidPercent: Int {
        guard totalAmount > 0 else { return 0 }
        return Int(round((paidAmount / totalAmount) * 100))
    }

    private var paidCount: Int {
        periodExpenses.filter { $0.isPaid }.count
    }

    private var pendingCount: Int {
        periodExpenses.filter { !$0.isPaid }.count
    }

    private var averagePerExpense: Double {
        periodExpenses.isEmpty ? 0 : totalAmount / Double(periodExpenses.count)
    }

    private var categorySlices: [CategorySlice] {
        let grouped = Dictionary(grouping: periodExpenses, by: { $0.category })
        let total = max(totalAmount, 0.01)

        return grouped.map { cat, items in
            let sum = items.reduce(0) { $0 + $1.amount }
            let paid = items.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
            let pending = max(0, sum - paid)
            return CategorySlice(
                id: cat,
                category: cat,
                amount: sum,
                paidAmount: paid,
                pendingAmount: pending,
                percentage: (sum / total) * 100.0,
                count: items.count,
                colorHex: Self.colorHexForCategory(cat),
                icon: Self.iconForCategory(cat)
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    private var filteredList: [PersonalExpenseRecord] {
        periodExpenses.filter { item in
            let matchesCategory = selectedCategoryFilter == nil || item.category == selectedCategoryFilter
            let matchesStatus: Bool
            switch selectedStatusFilter {
            case .all: matchesStatus = true
            case .paid: matchesStatus = item.isPaid
            case .pending: matchesStatus = !item.isPaid
            }
            return matchesCategory && matchesStatus
        }
    }

    var body: some View {
        ZStack {
            JuntoColors.warmBg.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                periodSelectorBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        paymentProgressCard

                        if periodExpenses.isEmpty {
                            emptyExpensesCard
                        } else {
                            donutChartCard

                            kpiSummaryRow

                            categoryBreakdownCard

                            expensesListCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(item: $selectedExpenseForDetail) { expense in
            PersonalExpenseDetailSheet(
                expense: expense,
                categoryTotal: categorySlices.first(where: { $0.category == expense.category })?.amount ?? expense.amount,
                periodTotal: totalAmount,
                canToggleDirectly: store.isManualPersonalExpense(id: expense.id),
                onTogglePaid: {
                    store.togglePersonalExpensePaid(id: expense.id)
                    selectedExpenseForDetail = nil
                }
            )
            .presentationDetents([.height(430), .medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .sheet(item: $selectedCategoryForDetail) { slice in
            CategoryBreakdownSheet(
                slice: slice,
                items: periodExpenses.filter { $0.category == slice.category },
                onSelectExpense: { exp in
                    selectedCategoryForDetail = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                        selectedExpenseForDetail = exp
                    }
                }
            )
            .presentationDetents([.fraction(0.75), .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showAddExpenseSheet) {
            AddExpenseSheetView()
                .environmentObject(store)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Topo
    private var headerBar: some View {
        HStack {
            CircleNavButton(icon: "chevron.left") { dismiss() }
            Spacer()
            Text("Gastos pessoais")
                .font(.inter(17, weight: .semibold))
                .foregroundColor(JuntoColors.textMain)
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showAddExpenseSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(JuntoColors.primary)
                    .clipShape(Circle())
            }
            .buttonStyle(JuntoTapBounceStyle(scaleAmount: 0.92))
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    // MARK: - Seletor de Período
    private var periodSelectorBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availablePeriods, id: \.self) { period in
                    let active = selectedPeriod == period
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            selectedPeriod = period
                            selectedCategoryFilter = nil
                        }
                    } label: {
                        Text(period)
                            .font(.inter(13, weight: active ? .medium : .regular))
                            .foregroundColor(active ? .white : JuntoColors.textMuted)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(active ? JuntoColors.primary : Color.white)
                            .overlay(
                                Capsule()
                                    .stroke(active ? Color.clear : JuntoColors.border, lineWidth: 1)
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
        .padding(.bottom, 12)
    }

    // MARK: - Card "Quanto você já pagou"
    private var paymentProgressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quanto você já pagou")
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)

                    Text(JuntoStore.formatBRL(paidAmount))
                        .font(.inter(28, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)
                }

                Spacer()

                Text("\(paidPercent)% pago")
                    .font(.inter(12, weight: .semibold))
                    .foregroundColor(JuntoColors.pixGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(JuntoColors.pixGreenLight)
                    .clipShape(Capsule())
            }

            // Barra de progresso Pago vs Total
            GeometryReader { geo in
                let ratio = totalAmount > 0 ? min(1.0, paidAmount / totalAmount) : 0
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(JuntoColors.surfaceSubtle)
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(JuntoColors.pixGreen)
                        .frame(width: max(ratio > 0 ? 8 : 0, geo.size.width * CGFloat(ratio)))
                }
            }
            .frame(height: 8)

            Divider().opacity(0.6)

            HStack(spacing: 0) {
                summaryMetricColumn(
                    title: "Total",
                    value: JuntoStore.formatBRL(totalAmount),
                    subtitle: "\(periodExpenses.count) itens",
                    valueColor: JuntoColors.textMain
                )

                Divider().frame(height: 34)

                summaryMetricColumn(
                    title: "Já pago",
                    value: JuntoStore.formatBRL(paidAmount),
                    subtitle: "\(paidCount) pagos",
                    valueColor: JuntoColors.pixGreen
                )

                Divider().frame(height: 34)

                summaryMetricColumn(
                    title: "Falta pagar",
                    value: JuntoStore.formatBRL(pendingAmount),
                    subtitle: "\(pendingCount) abertos",
                    valueColor: pendingAmount > 0 ? JuntoColors.orangeSave : JuntoColors.textMuted
                )
            }
        }
        .padding(18)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(JuntoColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func summaryMetricColumn(title: String, value: String, subtitle: String, valueColor: Color) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(title)
                .font(.inter(11, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
            Text(value)
                .font(.inter(14, weight: .semibold))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(subtitle)
                .font(.inter(10, weight: .regular))
                .foregroundColor(JuntoColors.textLight)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Estado Vazio
    private var emptyExpensesCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 34, weight: .thin))
                .foregroundColor(JuntoColors.textLight)

            Text("Nenhum gasto registrado")
                .font(.inter(16, weight: .medium))
                .foregroundColor(JuntoColors.textMain)

            Text("Seus pagamentos de viagens, churrascos e despesas pessoais aparecem aqui com gráficos detalhados.")
                .font(.inter(13, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
                .multilineTextAlignment(.center)

            Button {
                showAddExpenseSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Registrar gasto")
                        .font(.inter(14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(JuntoColors.primary)
                .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(JuntoColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Card Gráfico de Rosca
    private var donutChartCard: some View {
        let activeSlice = categorySlices.first(where: { $0.category == selectedCategoryFilter })
        let centerValue = activeSlice?.amount ?? totalAmount
        let centerCount = activeSlice?.count ?? periodExpenses.count

        return VStack(spacing: 18) {
            HStack {
                Text("Distribuição por categoria")
                    .font(.inter(15, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                if selectedCategoryFilter != nil {
                    Button("Limpar filtro") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategoryFilter = nil
                        }
                    }
                    .font(.inter(12, weight: .medium))
                    .foregroundColor(JuntoColors.primary)
                }
            }

            ZStack {
                DonutChartView(slices: categorySlices, selectedCategory: selectedCategoryFilter)
                    .frame(width: 188, height: 188)

                VStack(spacing: 3) {
                    Text(selectedCategoryFilter ?? "Total")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                    Text(JuntoStore.formatBRL(centerValue))
                        .font(.inter(20, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)
                    Text("\(centerCount) gasto(s)")
                        .font(.inter(11, weight: .regular))
                        .foregroundColor(JuntoColors.textLight)
                }
            }
            .padding(.top, 2)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(categorySlices) { slice in
                    let isSelected = selectedCategoryFilter == slice.category
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategoryFilter = isSelected ? nil : slice.category
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(slice.color)
                                .frame(width: 9, height: 9)
                            Text(slice.category)
                                .font(.inter(13, weight: .regular))
                                .foregroundColor(JuntoColors.textMain)
                                .lineLimit(1)
                            Spacer()
                            Text("\(Int(round(slice.percentage)))%")
                                .font(.inter(13, weight: .semibold))
                                .foregroundColor(JuntoColors.textMain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(isSelected ? slice.color.opacity(0.14) : JuntoColors.surfaceSubtle)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(isSelected ? slice.color : Color.clear, lineWidth: 1.2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    }
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(JuntoColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - KPIs Rápidos
    private var kpiSummaryRow: some View {
        HStack(spacing: 12) {
            kpiCard(
                icon: "chart.bar",
                title: "Média por gasto",
                value: JuntoStore.formatBRL(averagePerExpense),
                accent: JuntoColors.primary
            )

            kpiCard(
                icon: categorySlices.first?.icon ?? "star",
                title: "Maior categoria",
                value: categorySlices.first?.category ?? "—",
                accent: categorySlices.first?.color ?? JuntoColors.accent
            )
        }
    }

    // MARK: - Análise Detalhada por Categoria (clicável para abrir detalhamento)
    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Análise por categoria")
                    .font(.inter(15, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Text("Toque para detalhar")
                    .font(.inter(11, weight: .regular))
                    .foregroundColor(JuntoColors.textLight)
            }

            ForEach(categorySlices) { slice in
                Button {
                    selectedCategoryForDetail = slice
                } label: {
                    VStack(spacing: 8) {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(slice.color.opacity(0.12))
                                    .frame(width: 34, height: 34)
                                Image(systemName: slice.icon)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(slice.color)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(slice.category)
                                    .font(.inter(14, weight: .semibold))
                                    .foregroundColor(JuntoColors.textMain)
                                Text("\(slice.count) gasto(s) · Pago: \(JuntoStore.formatBRL(slice.paidAmount))")
                                    .font(.inter(12, weight: .regular))
                                    .foregroundColor(JuntoColors.textMuted)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 6)

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(JuntoStore.formatBRL(slice.amount))
                                    .font(.inter(14, weight: .semibold))
                                    .foregroundColor(JuntoColors.textMain)
                                Text(String(format: "%.1f%%", slice.percentage))
                                    .font(.inter(11, weight: .medium))
                                    .foregroundColor(slice.color)
                            }

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(JuntoColors.textLight)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4).fill(JuntoColors.surfaceSubtle)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(slice.color)
                                    .frame(width: max(6, geo.size.width * CGFloat(slice.percentage / 100.0)))
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if slice.id != categorySlices.last?.id {
                    Divider().opacity(0.6)
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(JuntoColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Lista de Gastos Detalhada
    private var expensesListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedCategoryFilter == nil ? "Todos os gastos" : "Gastos de \(selectedCategoryFilter!)")
                    .font(.inter(15, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Text("\(filteredList.count)")
                    .font(.inter(12, weight: .medium))
                    .foregroundColor(JuntoColors.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(JuntoColors.surfaceSubtle)
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                ForEach(ExpenseStatusFilter.allCases, id: \.self) { status in
                    let active = selectedStatusFilter == status
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            selectedStatusFilter = status
                        }
                    } label: {
                        Text(status.rawValue)
                            .font(.inter(12, weight: active ? .medium : .regular))
                            .foregroundColor(active ? .white : JuntoColors.textMuted)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(active ? JuntoColors.primary : JuntoColors.surfaceSubtle)
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }

            if filteredList.isEmpty {
                Text("Nenhum gasto com este filtro.")
                    .font(.inter(13, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(filteredList) { item in
                        expenseItemRow(item)
                        if item.id != filteredList.last?.id {
                            Divider().opacity(0.6)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(JuntoColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func expenseItemRow(_ item: PersonalExpenseRecord) -> some View {
        let catColor = Color(hex: Self.colorHexForCategory(item.category))
        return Button {
            selectedExpenseForDetail = item
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(catColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: Self.iconForCategory(item.category))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(catColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.inter(14, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                        .lineLimit(1)
                    Text("\(item.groupName) · \(item.category) · \(item.dateText)")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(JuntoStore.formatBRL(item.amount))
                        .font(.inter(14, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)

                    Text(item.isPaid ? "Pago" : "Pendente")
                        .font(.inter(10, weight: .medium))
                        .foregroundColor(item.isPaid ? JuntoColors.pixGreen : JuntoColors.orangeSave)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(item.isPaid ? JuntoColors.pixGreenLight : JuntoColors.orangeSave.opacity(0.12))
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(JuntoColors.textLight)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func kpiCard(icon: String, title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(accent)
                .frame(width: 30, height: 30)
                .background(accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(title)
                .font(.inter(12, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)

            Text(value)
                .font(.inter(16, weight: .semibold))
                .foregroundColor(JuntoColors.textMain)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(JuntoColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    static func colorHexForCategory(_ category: String) -> String {
        switch category {
        case "Viagem": return "#14213D"
        case "Churrasco": return "#FCA311"
        case "Casa": return "#16A34A"
        case "Bar & Drinks": return "#E2711D"
        case "Festa": return "#7C3AED"
        case "Esporte": return "#0284C7"
        case "Presente": return "#DB2777"
        default: return "#2563EB"
        }
    }

    static func iconForCategory(_ category: String) -> String {
        switch category {
        case "Viagem": return "airplane.departure"
        case "Churrasco": return "fork.knife"
        case "Casa": return "house"
        case "Bar & Drinks": return "mug"
        case "Festa": return "sparkles"
        case "Esporte": return "sportscourt"
        case "Presente": return "gift"
        case "Trabalho": return "briefcase"
        default: return "tag"
        }
    }
}

// MARK: - Detalhamento Completo de uma Categoria (Churrasco, Viagem, etc.)
private struct CategoryBreakdownSheet: View {
    let slice: MyExpensesAnalyticsScreen.CategorySlice
    let items: [PersonalExpenseRecord]
    var onSelectExpense: (PersonalExpenseRecord) -> Void
    @Environment(\.dismiss) private var dismiss

    private var highestExpense: PersonalExpenseRecord? {
        items.max(by: { $0.amount < $1.amount })
    }

    private var avgAmount: Double {
        items.isEmpty ? 0 : slice.amount / Double(items.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(slice.color.opacity(0.14))
                        .frame(width: 44, height: 44)
                    Image(systemName: slice.icon)
                        .font(.system(size: 19, weight: .regular))
                        .foregroundColor(slice.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(slice.category)
                        .font(.inter(18, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)
                    Text("\(slice.count) gasto(s) · \(String(format: "%.1f%%", slice.percentage)) do total")
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
            .padding(.top, 20)

            // Resumo da categoria: Total, Pago, Falta pagar
            HStack(spacing: 10) {
                miniStat(label: "Total", value: JuntoStore.formatBRL(slice.amount), color: JuntoColors.textMain)
                miniStat(label: "Já pago", value: JuntoStore.formatBRL(slice.paidAmount), color: JuntoColors.pixGreen)
                miniStat(label: "Falta", value: JuntoStore.formatBRL(slice.pendingAmount), color: slice.pendingAmount > 0 ? JuntoColors.orangeSave : JuntoColors.textMuted)
            }

            // Média e maior gasto
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Média nesta categoria")
                        .font(.inter(11, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                    Text(JuntoStore.formatBRL(avgAmount))
                        .font(.inter(14, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(JuntoColors.surfaceSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Maior gasto")
                        .font(.inter(11, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                    Text(highestExpense.map { JuntoStore.formatBRL($0.amount) } ?? "—")
                        .font(.inter(14, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(JuntoColors.surfaceSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Text("Lançamentos de \(slice.category)")
                .font(.inter(14, weight: .semibold))
                .foregroundColor(JuntoColors.textMain)
                .padding(.top, 4)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        Button {
                            onSelectExpense(item)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.inter(14, weight: .medium))
                                        .foregroundColor(JuntoColors.textMain)
                                    Text("\(item.groupName) · \(item.dateText)")
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(JuntoStore.formatBRL(item.amount))
                                        .font(.inter(14, weight: .semibold))
                                        .foregroundColor(JuntoColors.textMain)
                                    Text(item.isPaid ? "Pago" : "Pendente")
                                        .font(.inter(11, weight: .medium))
                                        .foregroundColor(item.isPaid ? JuntoColors.pixGreen : JuntoColors.orangeSave)
                                }
                            }
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if item.id != items.last?.id {
                            Divider().opacity(0.6)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .background(Color.white.ignoresSafeArea())
    }

    private func miniStat(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.inter(11, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
            Text(value)
                .font(.inter(14, weight: .semibold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(JuntoColors.surfaceSubtle)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Detalhes Completos de um Gasto Pessoal
private struct PersonalExpenseDetailSheet: View {
    let expense: PersonalExpenseRecord
    let categoryTotal: Double
    let periodTotal: Double
    let canToggleDirectly: Bool
    var onTogglePaid: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var catColor: Color {
        Color(hex: MyExpensesAnalyticsScreen.colorHexForCategory(expense.category))
    }

    private var pctOfCategory: Double {
        categoryTotal > 0 ? (expense.amount / categoryTotal) * 100 : 0
    }

    private var pctOfPeriod: Double {
        periodTotal > 0 ? (expense.amount / periodTotal) * 100 : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(catColor.opacity(0.14))
                        .frame(width: 44, height: 44)
                    Image(systemName: MyExpensesAnalyticsScreen.iconForCategory(expense.category))
                        .font(.system(size: 19, weight: .regular))
                        .foregroundColor(catColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(expense.title)
                        .font(.inter(17, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)
                        .lineLimit(1)
                    Text(expense.category)
                        .font(.inter(12, weight: .medium))
                        .foregroundColor(catColor)
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
            .padding(.top, 20)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Valor do gasto")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                    Text(JuntoStore.formatBRL(expense.amount))
                        .font(.inter(26, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)
                }

                Spacer()

                Text(expense.isPaid ? "Pago" : "Pendente")
                    .font(.inter(13, weight: .semibold))
                    .foregroundColor(expense.isPaid ? JuntoColors.pixGreen : JuntoColors.orangeSave)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(expense.isPaid ? JuntoColors.pixGreenLight : JuntoColors.orangeSave.opacity(0.14))
                    .clipShape(Capsule())
            }

            VStack(spacing: 0) {
                infoRow(label: "Origem / Grupo", value: expense.groupName)
                Divider().padding(.leading, 14)
                infoRow(label: "Período", value: "\(expense.dateText) · \(expense.monthKey)")
                Divider().padding(.leading, 14)
                infoRow(label: "Peso em \(expense.category)", value: String(format: "%.1f%%", pctOfCategory))
                Divider().padding(.leading, 14)
                infoRow(label: "Peso no total geral", value: String(format: "%.1f%%", pctOfPeriod))
            }
            .background(JuntoColors.surfaceSubtle.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if canToggleDirectly {
                Button(action: onTogglePaid) {
                    HStack(spacing: 8) {
                        Image(systemName: expense.isPaid ? "arrow.uturn.backward.circle" : "checkmark.circle.fill")
                            .font(.system(size: 15))
                        Text(expense.isPaid ? "Marcar como pendente" : "Marcar como pago")
                            .font(.inter(14, weight: .semibold))
                    }
                    .foregroundColor(expense.isPaid ? JuntoColors.textMain : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(expense.isPaid ? JuntoColors.surfaceSubtle : JuntoColors.pixGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(JuntoTapBounceStyle(scaleAmount: 0.97))
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color.white.ignoresSafeArea())
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.inter(13, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
            Spacer()
            Text(value)
                .font(.inter(13, weight: .medium))
                .foregroundColor(JuntoColors.textMain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}

// MARK: - Gráfico de Rosca (Donut Chart) em SwiftUI Nativo
private struct DonutChartView: View {
    let slices: [MyExpensesAnalyticsScreen.CategorySlice]
    let selectedCategory: String?

    var body: some View {
        ZStack {
            if slices.isEmpty {
                Circle()
                    .stroke(JuntoColors.border, lineWidth: 24)
            } else {
                ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                    let start = startFraction(for: index)
                    let end = start + (slice.percentage / 100.0)
                    let isDimmed = selectedCategory != nil && selectedCategory != slice.category

                    Circle()
                        .trim(from: CGFloat(start) + 0.004, to: max(CGFloat(end) - 0.004, CGFloat(start) + 0.005))
                        .stroke(
                            slice.color.opacity(isDimmed ? 0.25 : 1.0),
                            style: StrokeStyle(lineWidth: selectedCategory == slice.category ? 28 : 22, lineCap: .butt)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.25), value: selectedCategory)
                }
            }
        }
    }

    private func startFraction(for index: Int) -> Double {
        slices.prefix(index).reduce(0) { $0 + ($1.percentage / 100.0) }
    }
}
