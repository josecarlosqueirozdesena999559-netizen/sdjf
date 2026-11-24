import SwiftUI

struct ActivitiesView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var searchText = ""
    @State private var selectedFilter: ActivityFilter = .all
    @State private var selectedActivity: ActivityEvent? = nil

    enum ActivityFilter: String, CaseIterable {
        case all = "Todos"
        case paid = "Pagos"
        case pending = "Pendentes"
    }

    private var filteredActivities: [ActivityEvent] {
        store.activities.filter { item in
            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                matchesSearch = item.title.localizedCaseInsensitiveContains(searchText) ||
                    item.subtitle.localizedCaseInsensitiveContains(searchText)
            }

            let matchesFilter: Bool
            switch selectedFilter {
            case .all:
                matchesFilter = true
            case .paid:
                matchesFilter = item.isPositive
            case .pending:
                matchesFilter = !item.isPositive
            }

            return matchesSearch && matchesFilter
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Topo: Título "Lançamentos" + Botão "+" para novo lançamento
            HStack(spacing: 10) {
                Text("Lançamentos")
                    .font(.inter(24, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    store.showAddExpenseSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(JuntoColors.primary)
                        .clipShape(Circle())
                }
                .buttonStyle(JuntoTapBounceStyle(scaleAmount: 0.92))
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 12)

            // Botão / Card em destaque para ver Gastos Pessoais detalhados (gráficos, categorias, quanto já pagou)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                store.showMyExpensesScreen = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(JuntoColors.primary.opacity(0.10))
                            .frame(width: 46, height: 46)
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(JuntoColors.primary)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Meus gastos pessoais")
                            .font(.inter(15, weight: .semibold))
                            .foregroundColor(JuntoColors.textMain)

                        Text("Gráficos, viagens, churrasco e quanto já pagou")
                            .font(.inter(12, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                            .lineLimit(1)

                        HStack(spacing: 10) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(JuntoColors.pixGreen)
                                    .frame(width: 6, height: 6)
                                Text("Pago: \(JuntoStore.formatBRL(store.totalPersonalPaidAmount))")
                                    .font(.inter(11, weight: .medium))
                                    .foregroundColor(JuntoColors.pixGreen)
                            }

                            if store.totalPersonalPendingAmount > 0 {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(JuntoColors.orangeSave)
                                        .frame(width: 6, height: 6)
                                    Text("Falta: \(JuntoStore.formatBRL(store.totalPersonalPendingAmount))")
                                        .font(.inter(11, weight: .medium))
                                        .foregroundColor(JuntoColors.orangeSave)
                                }
                            }
                        }
                        .padding(.top, 2)
                    }

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(JuntoColors.textLight)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(JuntoColors.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(JuntoTapBounceStyle(scaleAmount: 0.98))
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // Barra de pesquisa limpa (sem animação de digitação)
            AnimatedSearchBar(
                text: $searchText,
                placeholders: ["Pesquisar lançamentos"]
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            // Filtros rápidos
            HStack(spacing: 8) {
                ForEach(ActivityFilter.allCases, id: \.self) { filter in
                    let active = selectedFilter == filter
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.inter(13, weight: active ? .medium : .regular))
                            .foregroundColor(active ? .white : JuntoColors.textMuted)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(active ? JuntoColors.primary : JuntoColors.surfaceSubtle)
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            Divider().opacity(0.6)

            if filteredActivities.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle.portrait")
                        .font(.system(size: 32, weight: .thin))
                        .foregroundColor(JuntoColors.textLight)

                    Text(searchText.isEmpty ? "Nenhum lançamento ainda" : "Nenhum lançamento encontrado")
                        .font(.inter(16, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)

                    if searchText.isEmpty {
                        Text("Seus pagamentos, despesas e movimentações aparecem aqui.")
                            .font(.inter(13, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 36)

                        Button {
                            store.showAddExpenseSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Adicionar lançamento")
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
                }
                .frame(maxWidth: .infinity)
                Spacer()
                Spacer().frame(height: 110)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredActivities) { item in
                            Button {
                                selectedActivity = item
                            } label: {
                                activityRow(item)
                            }
                            .buttonStyle(.plain)

                            Divider().padding(.leading, 66)
                        }
                    }
                    .padding(.bottom, 140)
                }
            }
        }
        .background(Color.white)
        .sheet(item: $selectedActivity) { item in
            ActivityDetailSheet(
                activity: item,
                accentColor: iconAccentColor(for: item.icon),
                onOpenPersonalAnalytics: {
                    selectedActivity = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        store.showMyExpensesScreen = true
                    }
                }
            )
            .presentationDetents([.height(360), .medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
    }

    private func activityRow(_ item: ActivityEvent) -> some View {
        let accent = iconAccentColor(for: item.icon)
        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.10))
                    .frame(width: 40, height: 40)
                Image(systemName: item.icon)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.inter(14, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("\(item.subtitle) · \(item.timeAgo)")
                    .font(.inter(12, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                if let amt = item.amountText {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(amt)
                            .font(.inter(14, weight: .semibold))
                            .foregroundColor(item.isPositive ? JuntoColors.pixGreen : JuntoColors.textMain)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Text(item.isPositive ? "Confirmado" : "Lançado")
                            .font(.inter(10, weight: .regular))
                            .foregroundColor(item.isPositive ? JuntoColors.pixGreen : JuntoColors.textLight)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(JuntoColors.textLight)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }

    private func iconAccentColor(for icon: String) -> Color {
        switch icon {
        case "checkmark.circle", "checkmark.circle.fill", "clock.badge.checkmark":
            return JuntoColors.pixGreen
        case "dollarsign.circle":
            return JuntoColors.accent
        case "house":
            return JuntoColors.orangeSave
        default:
            return JuntoColors.primary
        }
    }
}

// MARK: - Detalhes completos de um Lançamento
private struct ActivityDetailSheet: View {
    let activity: ActivityEvent
    let accentColor: Color
    var onOpenPersonalAnalytics: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: activity.icon)
                        .font(.system(size: 19, weight: .regular))
                        .foregroundColor(accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Detalhes do lançamento")
                        .font(.inter(17, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)
                    Text(activity.timeAgo)
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

            VStack(spacing: 0) {
                detailLine(label: "Descrição", value: activity.title)
                Divider().padding(.leading, 14)
                detailLine(label: "Origem / Grupo", value: activity.subtitle)
                Divider().padding(.leading, 14)
                detailLine(label: "Status", value: activity.isPositive ? "Pago / Confirmado" : "Registrado")
                if let amt = activity.amountText {
                    Divider().padding(.leading, 14)
                    HStack {
                        Text("Valor")
                            .font(.inter(13, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                        Spacer()
                        Text(amt)
                            .font(.inter(17, weight: .semibold))
                            .foregroundColor(activity.isPositive ? JuntoColors.pixGreen : JuntoColors.textMain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
            }
            .background(JuntoColors.surfaceSubtle.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button(action: onOpenPersonalAnalytics) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 14))
                    Text("Ver análise completa de gastos pessoais")
                        .font(.inter(14, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(JuntoColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(JuntoTapBounceStyle(scaleAmount: 0.97))

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color.white.ignoresSafeArea())
    }

    private func detailLine(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.inter(13, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
            Spacer()
            Text(value)
                .font(.inter(13, weight: .medium))
                .foregroundColor(JuntoColors.textMain)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
