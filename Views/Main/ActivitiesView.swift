import SwiftUI

struct ActivitiesView: View {
    @EnvironmentObject var store: JuntoStore
    @State private var searchText = ""

    private var filteredActivities: [ActivityEvent] {
        if searchText.isEmpty { return store.activities }
        return store.activities.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Atividade recente")
                .font(.inter(24, weight: .medium))
                .foregroundColor(JuntoColors.textMain)
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 12)

            AnimatedSearchBar(
                text: $searchText,
                placeholders: [
                    "Pesquisando alguma atividade?",
                    "Buscar Pix ou despesa...",
                    "Procurando um pagamento?"
                ]
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            Divider().opacity(0.6)

            if filteredActivities.isEmpty {
                // Caixa cinza clara exata da referência
                Text("Você ainda não tem atividades.")
                    .font(.inter(15, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(JuntoColors.surfaceSubtle)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)

                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(filteredActivities) { item in
                            let accent = iconAccentColor(for: item.icon)
                            HStack(spacing: 14) {
                                // Ícone nativo limpo sem fundo colorido pesado
                                Image(systemName: item.icon)
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundColor(accent)
                                    .frame(width: 30, alignment: .center)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(.inter(14, weight: .regular))
                                        .foregroundColor(JuntoColors.textMain)
                                        .lineLimit(2)
                                    Text("\(item.subtitle) • \(item.timeAgo)")
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                        .lineLimit(1)
                                }

                                Spacer(minLength: 8)

                                if let amt = item.amountText {
                                    Text(amt)
                                        .font(.inter(14, weight: .medium))
                                        .foregroundColor(item.isPositive ? JuntoColors.pixGreen : JuntoColors.orangeSave)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)

                            Divider().padding(.leading, 64)
                        }
                    }
                    .padding(.bottom, 140)
                }
            }
        }
        .background(Color.white)
    }

    private func iconAccentColor(for icon: String) -> Color {
        switch icon {
        case "checkmark.circle", "checkmark.circle.fill": return JuntoColors.pixGreen
        case "dollarsign.circle": return JuntoColors.accent
        case "house": return JuntoColors.orangeSave
        default: return JuntoColors.primary
        }
    }
}
