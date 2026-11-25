import SwiftUI

struct ActivitiesView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var searchText = ""
    @State private var selectedActivity: ActivityEvent? = nil

    private var filteredActivities: [ActivityEvent] {
        let monetaryOnly = store.activities.filter { JuntoStore.isMonetaryActivity($0) }
        if searchText.isEmpty { return monetaryOnly }
        return monetaryOnly.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Topo limpo: "Lançamentos" + botão "Meus gastos" ao lado (sem botão de adicionar e sem filtros)
            HStack(spacing: 10) {
                Text("Lançamentos")
                    .font(.inter(26, weight: .bold))
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
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(JuntoColors.primary.opacity(0.08))
                            .frame(width: 68, height: 68)
                        Image(systemName: searchText.isEmpty ? "banknote" : "magnifyingglass")
                            .font(.system(size: 26, weight: .regular))
                            .foregroundColor(JuntoColors.primary)
                    }

                    Text(searchText.isEmpty ? "Nenhum pagamento ainda" : "Nenhum lançamento encontrado")
                        .font(.inter(17, weight: .bold))
                        .foregroundColor(JuntoColors.textMain)

                    if searchText.isEmpty {
                        Text("Somente seus pagamentos e valores dos grupos aparecem aqui para calcular seus gastos mensais.")
                            .font(.inter(14, weight: .regular))
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
                holderName: store.user.fullName,
                onOpenExpensesAnalytics: {
                    selectedActivity = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        store.showMyExpensesScreen = true
                    }
                }
            )
            .presentationDetents([.height(500), .large])
            .presentationCornerRadius(24)
            .presentationBackground(Color.white)
        }
    }

    private func activityRow(_ item: ActivityEvent) -> some View {
        let accent = iconAccentColor(for: item.icon)
        return HStack(spacing: 14) {
            Image(systemName: item.icon)
                .font(.system(size: 20, weight: .light))
                .foregroundColor(accent)
                .frame(width: 28, alignment: .center)

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

// MARK: - Extrato Detalhado do Lançamento (100% Flat Branco — Estilo Comprovante/Extrato Bancário)
private struct ActivityDetailSheet: View {
    let activity: ActivityEvent
    let holderName: String
    var onOpenExpensesAnalytics: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var copiedAuth = false

    private var authCode: String {
        "JNT-" + String(activity.id.uuidString.replacingOccurrences(of: "-", with: "").prefix(10)).uppercased()
    }

    private var groupOriginName: String {
        let parts = activity.subtitle.components(separatedBy: "•")
        return parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? activity.subtitle
    }

    private var extraNote: String? {
        let parts = activity.subtitle.components(separatedBy: "•")
        guard parts.count > 1 else { return nil }
        return parts.dropFirst().joined(separator: " · ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Topo flat limpo com X
            HStack {
                PopupCloseButton { dismiss() }
                Spacer()
                Text("Extrato do lançamento")
                    .font(.inter(16, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider().opacity(0.6)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Cabeçalho de valor estilo extrato bancário
                    VStack(spacing: 6) {
                        PixOfficialIcon(size: 26, color: Color(hex: "#32BCAD"))
                            .padding(.top, 18)

                        Text(activity.amountText ?? "R$ 0,00")
                            .font(.inter(30, weight: .bold))
                            .foregroundColor(JuntoColors.textMain)

                        Text(activity.isPositive ? "Pagamento confirmado" : "Lançamento registrado")
                            .font(.inter(12, weight: .semibold))
                            .foregroundColor(activity.isPositive ? JuntoColors.pixGreen : JuntoColors.orangeSave)

                        Text(activity.displayDateText)
                            .font(.inter(12, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                            .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity)

                    Divider().opacity(0.6)

                    // Linhas detalhadas do extrato
                    VStack(spacing: 0) {
                        statementRow(label: "Descrição", value: activity.title)
                        Divider().opacity(0.5)

                        statementRow(label: "Grupo / Origem", value: groupOriginName)
                        Divider().opacity(0.5)

                        if let note = extraNote, !note.isEmpty {
                            statementRow(label: "Detalhe", value: note)
                            Divider().opacity(0.5)
                        }

                        statementRow(label: "Forma de pagamento", value: "Pix")
                        Divider().opacity(0.5)

                        statementRow(label: "Data e horário", value: activity.displayDateText)
                        Divider().opacity(0.5)

                        statementRow(label: "Titular da conta", value: holderName)
                        Divider().opacity(0.5)

                        HStack(alignment: .center, spacing: 12) {
                            Text("Código do registro")
                                .font(.inter(13, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)
                            Spacer()
                            Button {
                                UIPasteboard.general.string = authCode
                                copiedAuth = true
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedAuth = false }
                            } label: {
                                HStack(spacing: 5) {
                                    Text(authCode)
                                        .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                                        .foregroundColor(JuntoColors.textMain)
                                    Image(systemName: copiedAuth ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(copiedAuth ? JuntoColors.pixGreen : JuntoColors.primary)
                                }
                            }
                        }
                        .padding(.vertical, 13)
                    }
                    .padding(.horizontal, 20)

                    Divider().opacity(0.6)

                    Button(action: onOpenExpensesAnalytics) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.pie.fill")
                                .font(.system(size: 14))
                            Text("Ver resumo em Meus gastos")
                                .font(.inter(14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(JuntoColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(JuntoTapBounceStyle(scaleAmount: 0.98))
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
        .presentationBackground(Color.white)
    }

    private func statementRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.inter(13, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
            Spacer()
            Text(value)
                .font(.inter(13.5, weight: .medium))
                .foregroundColor(JuntoColors.textMain)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 13)
    }
}
