import SwiftUI

struct ActivitiesView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var searchText = ""
    @State private var selectedActivity: ActivityEvent? = nil

    private var filteredActivities: [ActivityEvent] {
        if searchText.isEmpty { return store.activities }
        return store.activities.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Topo limpo: "Lançamentos" + botão "Meus gastos" ao lado (sem botão de adicionar e sem filtros)
            HStack(spacing: 10) {
                Text("Lançamentos")
                    .font(.inter(24, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    store.showMyExpensesScreen = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 13, weight: .medium))
                        Text("Meus gastos")
                            .font(.inter(13, weight: .semibold))
                    }
                    .foregroundColor(JuntoColors.primary)
                    .padding(.horizontal, 13)
                    .frame(height: 36)
                    .background(JuntoColors.primary.opacity(0.10))
                    .clipShape(Capsule())
                }
                .buttonStyle(JuntoTapBounceStyle(scaleAmount: 0.94))
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 12)

            // Barra de pesquisa limpa (sem animação)
            AnimatedSearchBar(
                text: $searchText,
                placeholders: ["Pesquisar lançamentos"]
            )
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
                        Text("Os pagamentos e movimentações dos seus grupos aparecem aqui automaticamente.")
                            .font(.inter(13, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 36)
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
                onOpenExpensesAnalytics: {
                    selectedActivity = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        store.showMyExpensesScreen = true
                    }
                }
            )
            .presentationDetents([.height(350), .medium])
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

                        Text(item.isPositive ? "Confirmado" : "Registrado")
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
    var onOpenExpensesAnalytics: () -> Void
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
                detailLine(label: "Grupo / Origem", value: activity.subtitle)
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

            Button(action: onOpenExpensesAnalytics) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 14))
                    Text("Ver resumo em Meus gastos")
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
