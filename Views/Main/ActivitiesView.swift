import SwiftUI

struct ActivitiesView: View {
    @EnvironmentObject var store: JuntoStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Atividades Recentes")
                        .font(.inter(16, weight: .heavy))
                        .foregroundColor(JuntoColors.textMain)
                    Spacer()
                    Text("Tempo real")
                        .font(.inter(11, weight: .bold))
                        .foregroundColor(JuntoColors.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(JuntoColors.secondaryLight)
                        .cornerRadius(6)
                }

                VStack(spacing: 10) {
                    ForEach(store.activities) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.icon)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(item.isPositive ? JuntoColors.primary : JuntoColors.accent)
                                .frame(width: 40, height: 40)
                                .background(item.isPositive ? JuntoColors.primaryLight : JuntoColors.accentLight)
                                .cornerRadius(10)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title)
                                    .font(.inter(13, weight: .bold))
                                    .foregroundColor(JuntoColors.textMain)
                                Text("\(item.subtitle) • \(item.timeAgo)")
                                    .font(.inter(11))
                                    .foregroundColor(JuntoColors.textMuted)
                            }

                            Spacer()

                            if let amt = item.amountText {
                                Text(amt)
                                    .font(.inter(12, weight: .heavy))
                                    .foregroundColor(item.isPositive ? JuntoColors.secondary : JuntoColors.textMain)
                            }
                        }
                        .padding(14)
                        .background(JuntoColors.surface)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(JuntoColors.border, lineWidth: 1))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(16)
        }
    }
}
