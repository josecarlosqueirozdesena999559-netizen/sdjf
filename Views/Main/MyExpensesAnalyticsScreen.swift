import SwiftUI

/// Tela "Gastos pessoais": gráficos por categoria (Churrasco, Viagens, Casa, etc.), quanto você já pagou e detalhamento ao tocar em cada categoria ou gasto
struct MyExpensesAnalyticsScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPeriod: String = JuntoStore.currentMonthKey()
    @State private var selectedExpenseForDetail: PersonalExpenseRecord? = nil
    @State private var selectedCategoryForDetail: CategorySlice? = nil
    @State private var showInfoAlert: Bool = false

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

    private struct MonthlyBarPoint: Identifiable {
        let id: String
        let shortLabel: String
        let fullPeriod: String
        let total: Double
        let paid: Double
    }

    private var allExpenses: [PersonalExpenseRecord] {
        store.allTrackedPersonalExpenses
    }

    private var availableMonths: [String] {
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
        return months
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

    private var chartBars: [MonthlyBarPoint] {
        if selectedPeriod == "Geral" {
            return availableMonths.prefix(6).reversed().map { month in
                let items = allExpenses.filter { $0.monthKey == month }
                return MonthlyBarPoint(
                    id: month,
                    shortLabel: Self.shortMonthCode(from: month),
                    fullPeriod: month,
                    total: items.reduce(0) { $0 + $1.amount },
                    paid: items.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
                )
            }
        } else {
            return [
                MonthlyBarPoint(
                    id: selectedPeriod,
                    shortLabel: Self.shortMonthCode(from: selectedPeriod),
                    fullPeriod: selectedPeriod,
                    total: totalAmount,
                    paid: paidAmount
                )
            ]
        }
    }

    private var currentMonthIndex: Int {
        availableMonths.firstIndex(of: selectedPeriod) ?? 0
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        // Título e subtítulo limpos fiéis ao modelo
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Meus gastos")
                                .font(.inter(26, weight: .bold))
                                .foregroundColor(JuntoColors.textMain)

                            Text(selectedPeriod == "Geral"
                                 ? "Gastos nos grupos em todos os períodos"
                                 : "Gastos nos grupos em \(selectedPeriod.lowercased())")
                                .font(.inter(15, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                        }

                        // Gráfico minimalista com linhas horizontais pontilhadas (sem caixa)
                        minimalistBarChart

                        // Métricas grandes com barra vertical colorida à esquerda (fiel ao modelo)
                        VStack(alignment: .leading, spacing: 24) {
                            metricBlock(
                                title: "Total gasto",
                                amount: totalAmount,
                                color: JuntoColors.primary,
                                subtitle: nil
                            )

                            metricBlock(
                                title: "Já pago",
                                amount: paidAmount,
                                color: JuntoColors.pixGreen,
                                subtitle: totalAmount > 0
                                    ? "\(paidPercent)% do gasto total nos grupos"
                                    : "--% do gasto total nos grupos"
                            )

                            if pendingAmount > 0 {
                                metricBlock(
                                    title: "Falta pagar",
                                    amount: pendingAmount,
                                    color: JuntoColors.orangeSave,
                                    subtitle: nil,
                                    compact: true
                                )
                            }
                        }

                        // Categorias limpas sem caixas (toque abre detalhamento completo)
                        if !categorySlices.isEmpty {
                            Divider().opacity(0.6)

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Por categoria")
                                    .font(.inter(14, weight: .semibold))
                                    .foregroundColor(JuntoColors.textMain)

                                VStack(spacing: 0) {
                                    ForEach(categorySlices) { slice in
                                        Button {
                                            selectedCategoryForDetail = slice
                                        } label: {
                                            HStack(spacing: 12) {
                                                Image(systemName: slice.icon)
                                                    .font(.system(size: 18, weight: .regular))
                                                    .foregroundColor(slice.color)
                                                    .frame(width: 26)

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(slice.category)
                                                        .font(.inter(15, weight: .medium))
                                                        .foregroundColor(JuntoColors.textMain)
                                                    Text("\(slice.count) gasto(s) · Pago \(JuntoStore.formatBRL(slice.paidAmount))")
                                                        .font(.inter(12, weight: .regular))
                                                        .foregroundColor(JuntoColors.textMuted)
                                                }

                                                Spacer()

                                                VStack(alignment: .trailing, spacing: 2) {
                                                    Text(JuntoStore.formatBRL(slice.amount))
                                                        .font(.inter(15, weight: .semibold))
                                                        .foregroundColor(JuntoColors.textMain)
                                                    Text("\(Int(round(slice.percentage)))%")
                                                        .font(.inter(11, weight: .medium))
                                                        .foregroundColor(slice.color)
                                                }

                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(JuntoColors.textLight)
                                            }
                                            .padding(.vertical, 12)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)

                                        if slice.id != categorySlices.last?.id {
                                            Divider().opacity(0.5)
                                        }
                                    }
                                }
                            }
                        }

                        if !periodExpenses.isEmpty {
                            Divider().opacity(0.6)

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Pagamentos e dívidas")
                                    .font(.inter(14, weight: .semibold))
                                    .foregroundColor(JuntoColors.textMain)

                                VStack(spacing: 0) {
                                    ForEach(periodExpenses) { item in
                                        expenseItemRow(item)
                                        if item.id != periodExpenses.last?.id {
                                            Divider().opacity(0.5)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 8)
                    .padding(.bottom, 108)
                }
            }

            // Cápsula flutuante inferior de período (fiel ao modelo)
            floatingPeriodCapsule
                .padding(.horizontal, 18)
                .padding(.bottom, 16)
        }
        .alert("Como calculamos seus gastos", isPresented: $showInfoAlert) {
            Button("Entendi", role: .cancel) {}
        } message: {
            Text("Os valores exibidos aqui são calculados automaticamente a partir das cotas, pagamentos e dívidas dos seus grupos no Juntô.")
        }
        .sheet(item: $selectedExpenseForDetail) { expense in
            PersonalExpenseDetailSheet(
                expense: expense,
                categoryTotal: categorySlices.first(where: { $0.category == expense.category })?.amount ?? expense.amount,
                periodTotal: totalAmount
            )
            .presentationDetents([.height(380), .medium])
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
    }

    // MARK: - Topo limpo fiel ao modelo: X | ?
    private var headerBar: some View {
        HStack {
            PopupCloseButton { dismiss() }
            Spacer()
            Button {
                showInfoAlert = true
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 19, weight: .regular))
                    .foregroundColor(JuntoColors.textMain)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    // MARK: - Gráfico minimalista com linhas pontilhadas e barras Juntô
    private var minimalistBarChart: some View {
        let maxVal = max(chartBars.map(\.total).max() ?? 0, 1)

        return VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                // 4 linhas horizontais pontilhadas sutis
                VStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { idx in
                        DashedHorizontalLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                            .foregroundColor(JuntoColors.border.opacity(0.8))
                            .frame(height: 1)
                        if idx < 3 {
                            Spacer()
                        }
                    }
                }
                .frame(height: 132)

                // Barras verticais limpas
                HStack(alignment: .bottom, spacing: 20) {
                    ForEach(chartBars) { point in
                        let totalH: CGFloat = point.total > 0 ? max(10, CGFloat(point.total / maxVal) * 124) : 3
                        let paidH: CGFloat = point.paid > 0 ? max(6, CGFloat(point.paid / maxVal) * 124) : 0

                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(JuntoColors.primary.opacity(point.total > 0 ? 0.28 : 0.65))
                                .frame(width: chartBars.count == 1 ? 36 : 24, height: totalH)

                            if paidH > 0 {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(JuntoColors.primary)
                                    .frame(width: chartBars.count == 1 ? 36 : 24, height: min(paidH, totalH))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
            }

            // Rótulos dos meses abaixo (ex: NOV.)
            HStack(spacing: 20) {
                ForEach(chartBars) { point in
                    Text(point.shortLabel)
                        .font(.inter(12, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Bloco de métrica fiel ao modelo (barra vertical + valor grande)
    private func metricBlock(title: String, amount: Double, color: Color, subtitle: String?, compact: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Text(title)
                    .font(.inter(13, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
            }

            HStack(alignment: .center, spacing: 10) {
                Capsule()
                    .fill(color)
                    .frame(width: 5, height: compact ? 18 : 24)

                Text(JuntoStore.formatBRL(amount))
                    .font(.inter(compact ? 24 : 34, weight: .semibold))
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            if let subtitle {
                Text(subtitle)
                    .font(.inter(13, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
                    .padding(.leading, 15)
            }
        }
    }

    // MARK: - Cápsula flutuante inferior de período (Todos | < mês >)
    private var floatingPeriodCapsule: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.16)) {
                    selectedPeriod = selectedPeriod == "Geral"
                        ? (availableMonths.first ?? JuntoStore.currentMonthKey())
                        : "Geral"
                }
            } label: {
                Text("Todos")
                    .font(.inter(13, weight: selectedPeriod == "Geral" ? .bold : .medium))
                    .foregroundColor(selectedPeriod == "Geral" ? JuntoColors.primary : JuntoColors.textMain)
                    .padding(.horizontal, 12)
                    .frame(height: 36)
            }

            HStack(spacing: 6) {
                Button {
                    stepPeriod(older: true)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(canStepOlder ? JuntoColors.textMain : JuntoColors.textLight)
                        .frame(width: 28, height: 28)
                }
                .disabled(!canStepOlder)

                Text(selectedPeriod == "Geral" ? "Todos os períodos" : selectedPeriod.lowercased())
                    .font(.inter(14, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)

                Button {
                    stepPeriod(older: false)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(canStepNewer ? JuntoColors.textMain : JuntoColors.textLight)
                        .frame(width: 28, height: 28)
                }
                .disabled(!canStepNewer)
            }
            .padding(.horizontal, 10)
            .frame(height: 38)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(JuntoColors.surfaceSubtle)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private var canStepOlder: Bool {
        guard !availableMonths.isEmpty else { return false }
        if selectedPeriod == "Geral" { return true }
        return currentMonthIndex < availableMonths.count - 1
    }

    private var canStepNewer: Bool {
        guard !availableMonths.isEmpty else { return false }
        if selectedPeriod == "Geral" { return true }
        return currentMonthIndex > 0
    }

    private func stepPeriod(older: Bool) {
        guard !availableMonths.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.16)) {
            if selectedPeriod == "Geral" {
                selectedPeriod = availableMonths[0]
                return
            }
            let nextIdx = older ? currentMonthIndex + 1 : currentMonthIndex - 1
            if availableMonths.indices.contains(nextIdx) {
                selectedPeriod = availableMonths[nextIdx]
            }
        }
    }

    private func expenseItemRow(_ item: PersonalExpenseRecord) -> some View {
        let catColor = Color(hex: Self.colorHexForCategory(item.category))
        return Button {
            selectedExpenseForDetail = item
        } label: {
            HStack(spacing: 12) {
                Image(systemName: Self.iconForCategory(item.category))
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(catColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.inter(14, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                        .lineLimit(1)
                    Text("\(item.groupName) · \(item.dateText)")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(JuntoStore.formatBRL(item.amount))
                        .font(.inter(14, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)

                    Text(item.isPaid ? "Pago" : "Pendente")
                        .font(.inter(11, weight: .medium))
                        .foregroundColor(item.isPaid ? JuntoColors.pixGreen : JuntoColors.orangeSave)
                }
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private static func shortMonthCode(from period: String) -> String {
        let prefix = period.trimmingCharacters(in: .whitespacesAndNewlines).prefix(3).uppercased()
        return prefix.isEmpty ? "MÊS" : "\(prefix)."
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
        case "Dívidas": return "#DC2626"
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
        case "Dívidas": return "arrow.left.arrow.right"
        default: return "tag"
        }
    }
}

private struct DashedHorizontalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
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

                PopupCloseButton { dismiss() }
            }
            .padding(.top, 20)

            // Resumo limpo da categoria: Total, Pago, Falta pagar (sem retângulos cinzas)
            Divider().opacity(0.6)
            HStack(spacing: 0) {
                miniStat(label: "Total", value: JuntoStore.formatBRL(slice.amount), color: JuntoColors.primary)
                miniStat(label: "Já pago", value: JuntoStore.formatBRL(slice.paidAmount), color: JuntoColors.pixGreen)
                miniStat(label: "Falta", value: JuntoStore.formatBRL(slice.pendingAmount), color: slice.pendingAmount > 0 ? JuntoColors.orangeSave : JuntoColors.textMuted)
            }
            .padding(.vertical, 6)

            Divider().opacity(0.6)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Média na categoria")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                    Text(JuntoStore.formatBRL(avgAmount))
                        .font(.inter(15, weight: .bold))
                        .foregroundColor(JuntoColors.textMain)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Maior gasto")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                    Text(highestExpense.map { JuntoStore.formatBRL($0.amount) } ?? "—")
                        .font(.inter(15, weight: .bold))
                        .foregroundColor(JuntoColors.textMain)
                }
            }
            .padding(.vertical, 4)

            Divider().opacity(0.6)

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
                .font(.inter(12, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
            Text(value)
                .font(.inter(16, weight: .bold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Detalhes Completos de um Pagamento ou Dívida de Grupo
private struct PersonalExpenseDetailSheet: View {
    let expense: PersonalExpenseRecord
    let categoryTotal: Double
    let periodTotal: Double
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

                PopupCloseButton { dismiss() }
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

            Divider().opacity(0.6)

            VStack(spacing: 0) {
                infoRow(label: "Grupo / Origem", value: expense.groupName)
                Divider().opacity(0.5)
                infoRow(label: "Período", value: "\(expense.dateText) · \(expense.monthKey)")
                Divider().opacity(0.5)
                infoRow(label: "Peso em \(expense.category)", value: String(format: "%.1f%%", pctOfCategory))
                Divider().opacity(0.5)
                infoRow(label: "Peso no total geral", value: String(format: "%.1f%%", pctOfPeriod))
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
                .font(.inter(13, weight: .semibold))
                .foregroundColor(JuntoColors.textMain)
        }
        .padding(.vertical, 12)
    }
}
