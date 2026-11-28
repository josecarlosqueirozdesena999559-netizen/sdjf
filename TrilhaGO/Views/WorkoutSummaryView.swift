import SwiftUI
import MapKit

struct WorkoutSummaryView: View {
    let summary: WorkoutSummary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Trajeto desenhado no mapa (polyline)
                Map {
                    if summary.route.count >= 2 {
                        MapPolyline(coordinates: summary.route)
                            .stroke(TrilhaColors.emerald, lineWidth: 5)
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // Métricas (Outfit)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    metricBox(title: "DISTÂNCIA", value: String(format: "%.2f km", summary.distanceMeters / 1000.0))
                    metricBox(title: "TEMPO", value: "\(max(1, summary.durationSeconds / 60)) min")
                    metricBox(title: "CALORIAS", value: "\(summary.calories) kcal")
                    metricBox(title: "TERRITÓRIOS", value: "+\(summary.territoriesConquered)")
                }

                HStack {
                    Image("icon_key_flat").resizable().scaledToFit().frame(width: 24, height: 24)
                    Text("Bônus Esporte (1,5x): +\(summary.keysEarned) Chaves e +\(summary.xpEarned) XP")
                        .font(TrilhaFont.body(13, weight: .semibold))
                        .foregroundStyle(TrilhaColors.emeraldDark)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(TrilhaColors.emeraldSoft)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Spacer()

                ShareLink(
                    item: "Completei \(String(format: "%.2f km", summary.distanceMeters / 1000.0)) no TrilhaGO (\(summary.mode.title)) e conquistei \(summary.territoriesConquered) territórios!"
                ) {
                    Text("COMPARTILHAR")
                        .font(TrilhaFont.title(15))
                        .foregroundStyle(TrilhaColors.pureWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(TrilhaColors.emerald)
                        .clipShape(Capsule())
                }
            }
            .padding(20)
            .background(TrilhaColors.surfaceGray.ignoresSafeArea())
            .navigationTitle("Resumo do Percurso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Concluir") { dismiss() }
                }
            }
        }
    }

    private func metricBox(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(TrilhaFont.metric(22))
                .foregroundStyle(TrilhaColors.darkText)
            Text(title)
                .font(TrilhaFont.body(11, weight: .semibold))
                .foregroundStyle(TrilhaColors.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(TrilhaColors.pureWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
