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
                                Image(systemName: item.icon)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(accent)
                                    .frame(width: 40, height: 40)
                                    .background(accent.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(.inter(14, weight: .regular))
                                        .foregroundColor(JuntoColors.textMain)
                                    Text("\(item.subtitle) • \(item.timeAgo)")
                                        .font(.inter(12, weight: .regular))
                                        .foregroundColor(JuntoColors.textMuted)
                                }

                                Spacer()

                                if let amt = item.amountText {
                                    Text(amt)
                                        .font(.inter(14, weight: .medium))
                                        .foregroundColor(item.isPositive ? JuntoColors.pixGreen : JuntoColors.orangeSave)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)

                            Divider().padding(.leading, 74)
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
        case "checkmark.seal.fill", "arrow.uturn.left": return JuntoColors.pixGreen
        case "banknote.fill", "flame.fill": return JuntoColors.accent
        case "house.fill": return JuntoColors.orangeSave
        default: return JuntoColors.primary
        }
    }
}
