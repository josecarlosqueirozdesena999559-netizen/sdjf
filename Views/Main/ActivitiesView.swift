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
                            HStack(spacing: 14) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(JuntoColors.primary)
                                    .frame(width: 38, height: 38)
                                    .background(JuntoColors.primaryLight)
                                    .cornerRadius(10)

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
                                        .foregroundColor(JuntoColors.primary)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)

                            Divider().padding(.leading, 72)
                        }
                    }
                    .padding(.bottom, 140)
                }
            }
        }
        .background(Color.white)
    }
}
