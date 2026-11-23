import SwiftUI

/// Tela "Minhas despesas": gráfico redondo por categorias com porcentagens, filtro por mês e análises detalhadas
struct MyExpensesAnalyticsScreen: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss

    private let availableMonths = ["Outubro 2026", "Novembro 2026"]
    @State private var selectedMonthIndex: Int = 1 // Novembro 2026
    @State private var selectedCategoryFilter: String? = nil

    private var currentMonth: String { availableMonths[selectedMonthIndex] }

    private var monthExpenses: [PersonalExpenseRecord] {
        store.personalExpenses.filter { $0.monthKey == currentMonth }
    }

    private var previousMonthTotal: Double {
        guard selectedMonthIndex > 0 else { return 0 }
        let prev = availableMonths[selectedMonthIndex - 1]
        return store.personalExpenses.filter { $0.monthKey == prev }.reduce(0) { $0 + $1.amount }
    }

    private var totalAmount: Double {
        monthExpenses.reduce(0) { $0 + $1.amount }
    }

    private var averagePerExpense: Double {
        monthExpenses.isEmpty ? 0 : totalAmount / Double(monthExpenses.count)
    }

    struct CategorySlice: Identifiable {
        let id: String
        let category: String
        let amount: Double
        let percentage: Double
        let count: Int
        let color: Color
        let icon: String
    }

    private var categorySlices: [CategorySlice] {
        let grouped = Dictionary(grouping: monthExpenses, by: { $0.category })
        let total = max(totalAmount, 0.01)

        return grouped.map { cat, items in
            let sum = items.reduce(0) { $0 + $1.amount }
            return CategorySlice(
                id: cat,
                category: cat,
                amount: sum,
                percentage: (sum / total) * 100.0,
                count: items.count,
                color: colorForCategory(cat),
                icon: iconForCategory(cat)
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    private var filteredList: [PersonalExpenseRecord] {
        guard let cat = selectedCategoryFilter else { return monthExpenses }
        return monthExpenses.filter { $0.category == cat }
    }

    private var monthDeltaPercent: Int? {
        guard previousMonthTotal > 0 else { return nil }
        return Int(((totalAmount - previousMonthTotal) / previousMonthTotal) * 100)
    }

    var body: some View {
        ZStack {
            JuntoColors.warmBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Topo limpo sem botão "+" (botão "+" fica somente na tela inicial)
                HStack {
                    CircleNavButton(icon: "chevron.left") { dismiss() }
                    Spacer()
                    Text("Minhas despesas")
                        .font(.inter(17, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                    Spacer()
                    Spacer().frame(width: 44)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 12)

                // Seletor de Mês
                HStack {
                    Button {
                        if selectedMonthIndex > 0 {
                            withAnimation {
                                selectedMonthIndex -= 1
                                selectedCategoryFilter = nil
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedMonthIndex > 0 ? JuntoColors.textMain : JuntoColors.textLight)
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(selectedMonthIndex == 0)

                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(JuntoColors.primary)
                        Text(currentMonth)
                            .font(.inter(15, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                    }

                    Spacer()

                    Button {
                        if selectedMonthIndex < availableMonths.count - 1 {
                            withAnimation {
                                selectedMonthIndex += 1
                                selectedCategoryFilter = nil
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedMonthIndex < availableMonths.count - 1 ? JuntoColors.textMain : JuntoColors.textLight)
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(selectedMonthIndex == availableMonths.count - 1)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Cartão com Gráfico Redondo (Donut Chart) + Total no Centro
                        VStack(spacing: 18) {
                            ZStack {
                                DonutChartView(slices: categorySlices, selectedCategory: selectedCategoryFilter)
                                    .frame(width: 196, height: 196)

                                VStack(spacing: 3) {
                                    Text(selectedCategoryFilter ?? "Total no mês")
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                    let displayVal = selectedCategoryFilter == nil
                                        ? totalAmount
                                        : (categorySlices.first(where: { $0.category == selectedCategoryFilter })?.amount ?? 0)
                                    Text(JuntoStore.formatBRL(displayVal))
                                        .font(.inter(20, weight: .medium))
                                        .foregroundColor(JuntoColors.textMain)
                                    Text("\(filteredList.count) lançamento(s)")
                                        .font(.inter(11, weight: .regular))
                                        .foregroundColor(JuntoColors.textLight)
                                }
                            }
                            .padding(.top, 6)

                            // Chips clicáveis com porcentagens
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
                                                .frame(width: 10, height: 10)
                                            Text(slice.category)
                                                .font(.inter(13, weight: .regular))
                                                .foregroundColor(JuntoColors.textMain)
                                                .lineLimit(1)
                                            Spacer()
                                            Text("\(Int(round(slice.percentage)))%")
                                                .font(.inter(13, weight: .medium))
                                                .foregroundColor(JuntoColors.textMain)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? slice.color.opacity(0.14) : JuntoColors.surfaceSubtle)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(isSelected ? slice.color : Color.clear, lineWidth: 1.2)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Análises Detalhadas (KPIs do Mês)
                        HStack(spacing: 12) {
                            kpiCard(
                                icon: "chart.bar",
                                title: "Média / gasto",
                                value: JuntoStore.formatBRL(averagePerExpense),
                                accent: JuntoColors.primary
                            )

                            if let delta = monthDeltaPercent {
                                kpiCard(
                                    icon: delta <= 0 ? "arrow.down.right" : "arrow.up.right",
                                    title: "vs. mês anterior",
                                    value: "\(delta > 0 ? "+" : "")\(delta)%",
                                    accent: delta <= 0 ? JuntoColors.pixGreen : JuntoColors.orangeSave
                                )
                            } else {
                                kpiCard(
                                    icon: "star",
                                    title: "Maior categoria",
                                    value: categorySlices.first?.category ?? "—",
                                    accent: JuntoColors.accent
                                )
                            }
                        }

                        // Detalhamento por Categoria
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Análise por categoria")
                                .font(.inter(15, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)

                            ForEach(categorySlices) { slice in
                                VStack(spacing: 6) {
                                    HStack(spacing: 10) {
                                        Image(systemName: slice.icon)
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(slice.color)
                                            .frame(width: 32, height: 32)
                                            .background(slice.color.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))

                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(slice.category)
                                                .font(.inter(14, weight: .medium))
                                                .foregroundColor(JuntoColors.textMain)
                                            Text("\(slice.count) despesa(s)")
                                                .font(.inter(12, weight: .regular))
                                                .foregroundColor(JuntoColors.textMuted)
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 1) {
                                            Text(JuntoStore.formatBRL(slice.amount))
                                                .font(.inter(14, weight: .medium))
                                                .foregroundColor(JuntoColors.textMain)
                                            Text(String(format: "%.1f%%", slice.percentage))
                                                .font(.inter(12, weight: .regular))
                                                .foregroundColor(slice.color)
                                        }
                                    }

                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4).fill(JuntoColors.surfaceSubtle)
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(slice.color)
                                                .frame(width: geo.size.width * CGFloat(slice.percentage / 100.0))
                                        }
                                    }
                                    .frame(height: 6)
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Lista de Lançamentos do Mês
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(selectedCategoryFilter == nil ? "Lançamentos do mês" : "Despesas de \(selectedCategoryFilter!)")
                                    .font(.inter(15, weight: .medium))
                                    .foregroundColor(JuntoColors.textMain)
                                Spacer()
                                if selectedCategoryFilter != nil {
                                    Button("Ver todos") {
                                        withAnimation { selectedCategoryFilter = nil }
                                    }
                                    .font(.inter(13, weight: .medium))
                                    .foregroundColor(JuntoColors.primary)
                                }
                            }

                            VStack(spacing: 0) {
                                ForEach(filteredList) { item in
                                    let catColor = colorForCategory(item.category)
                                    HStack(spacing: 12) {
                                        Image(systemName: iconForCategory(item.category))
                                            .font(.system(size: 14))
                                            .foregroundColor(catColor)
                                            .frame(width: 34, height: 34)
                                            .background(catColor.opacity(0.12))
                                            .clipShape(Circle())

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.title)
                                                .font(.inter(14, weight: .regular))
                                                .foregroundColor(JuntoColors.textMain)
                                            Text("\(item.groupName) · \(item.dateText)")
                                                .font(.inter(12, weight: .regular))
                                                .foregroundColor(JuntoColors.textMuted)
                                        }

                                        Spacer()

                                        Text(JuntoStore.formatBRL(item.amount))
                                            .font(.inter(14, weight: .medium))
                                            .foregroundColor(JuntoColors.textMain)
                                    }
                                    .padding(.vertical, 11)
                                    Divider()
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(JuntoColors.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            }
        }
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
                .font(.inter(16, weight: .medium))
                .foregroundColor(JuntoColors.textMain)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(JuntoColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Viagem": return JuntoColors.primary
        case "Churrasco": return JuntoColors.accent
        case "Casa": return JuntoColors.pixGreen
        case "Bar & Drinks": return JuntoColors.orangeSave
        default: return JuntoColors.linkBlue
        }
    }

    private func iconForCategory(_ category: String) -> String {
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

// MARK: - Gráfico de Rosca (Donut Chart) em SwiftUI Nativo
private struct DonutChartView: View {
    let slices: [MyExpensesAnalyticsScreen.CategorySlice]
    let selectedCategory: String?

    var body: some View {
        ZStack {
            if slices.isEmpty {
                Circle()
                    .stroke(JuntoColors.border, lineWidth: 26)
            } else {
                ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                    let start = startFraction(for: index)
                    let end = start + (slice.percentage / 100.0)
                    let isDimmed = selectedCategory != nil && selectedCategory != slice.category

                    Circle()
                        .trim(from: CGFloat(start) + 0.004, to: max(CGFloat(end) - 0.004, CGFloat(start) + 0.005))
                        .stroke(
                            slice.color.opacity(isDimmed ? 0.25 : 1.0),
                            style: StrokeStyle(lineWidth: selectedCategory == slice.category ? 30 : 24, lineCap: .butt)
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
