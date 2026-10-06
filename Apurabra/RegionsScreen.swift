import SwiftUI

// MARK: - Modelo de Região
private struct BrazilRegion: Identifiable {
    let id: String
    let name: String
    let states: [String]

    static let all: [BrazilRegion] = [
        .init(id: "norte",        name: "Norte",        states: ["AC","AP","AM","PA","RO","RR","TO"]),
        .init(id: "nordeste",     name: "Nordeste",     states: ["AL","BA","CE","MA","PB","PE","PI","RN","SE"]),
        .init(id: "centro-oeste", name: "Centro-Oeste", states: ["DF","GO","MT","MS"]),
        .init(id: "sudeste",      name: "Sudeste",      states: ["ES","MG","RJ","SP"]),
        .init(id: "sul",          name: "Sul",          states: ["PR","RS","SC"]),
    ]
}

// MARK: - Store de Regiões
@MainActor
private final class RegionsStore: ObservableObject {
    @Published var regionResults: [String: ElectionResult] = [:]
    @Published var loading = false
    @Published var errorMessage: String?

    func load(office: Office, round: ElectionRound) async {
        loading = true
        errorMessage = nil
        regionResults = [:]

        await withTaskGroup(of: (String, ElectionResult?).self) { group in
            for region in BrazilRegion.all {
                for uf in region.states {
                    group.addTask {
                        let result = try? await APIClient.shared.result(office: office, state: uf, round: round)
                        return (uf, result)
                    }
                }
            }
            for await (uf, result) in group {
                if let r = result { regionResults[uf] = r }
            }
        }
        loading = false
    }

    // Agrega candidatos de vários estados somando votos
    func aggregated(for region: BrazilRegion) -> [AggregatedCandidate] {
        var totals: [String: AggregatedCandidate] = [:]
        var totalVotes = 0

        for uf in region.states {
            guard let result = regionResults[uf] else { continue }
            totalVotes += result.votosValidos
            for c in result.candidatos {
                if var agg = totals[c.id] {
                    agg.votos += c.votos
                    totals[c.id] = agg
                } else {
                    totals[c.id] = AggregatedCandidate(
                        id: c.id,
                        nomeUrna: c.nomeUrna,
                        partido: c.partido,
                        numero: c.numero,
                        foto: c.foto,
                        cor: c.cor,
                        votos: c.votos,
                        mapDarkColor: c.mapDarkColorHex
                    )
                }
            }
        }

        return totals.values
            .sorted { $0.votos > $1.votos }
            .map { var a = $0; a.totalRegionVotes = totalVotes; return a }
    }

    func loadedStates(for region: BrazilRegion) -> Int {
        region.states.filter { regionResults[$0] != nil }.count
    }
}

struct AggregatedCandidate: Identifiable {
    let id: String
    let nomeUrna: String
    let partido: String
    let numero: Int
    let foto: String?
    let cor: String
    var votos: Int
    let mapDarkColor: String
    var totalRegionVotes: Int = 0

    var percentual: Double {
        guard totalRegionVotes > 0 else { return 0 }
        return Double(votos) / Double(totalRegionVotes) * 100
    }
}

// MARK: - Tela Principal
struct RegionsScreen: View {
    @StateObject private var store = RegionsStore()
    @State private var round: ElectionRound = .first

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Picker("Turno", selection: $round) {
                        ForEach(ElectionRound.allCases) { item in Text(item.title).tag(item) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    Text("Presidente · \(round.title)")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    if store.loading {
                        ProgressView("Carregando regiões…")
                            .frame(maxWidth: .infinity)
                            .padding(40)
                    } else if let error = store.errorMessage {
                        ContentUnavailableView("Erro ao carregar", systemImage: "wifi.exclamationmark",
                                              description: Text(error))
                    } else {
                        ForEach(BrazilRegion.all) { region in
                            RegionCard(
                                region: region,
                                candidates: store.aggregated(for: region),
                                loadedStates: store.loadedStates(for: region)
                            )
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(AppTheme.background)
            .navigationTitle("Regiões")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: round.rawValue) { await store.load(office: .presidente, round: round) }
            .refreshable { await store.load(office: .presidente, round: round) }
        }
    }
}

// MARK: - Card de Região
private struct RegionCard: View {
    let region: BrazilRegion
    let candidates: [AggregatedCandidate]
    let loadedStates: Int

    private var topCandidates: [AggregatedCandidate] {
        Array(candidates.prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cabeçalho
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(region.name)
                        .font(.headline.bold())
                    Text("\(loadedStates)/\(region.states.count) estados carregados")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                // Estados em pill
                HStack(spacing: 4) {
                    ForEach(region.states.prefix(4), id: \.self) { uf in
                        Text(uf)
                            .font(.system(size: 9, weight: .semibold))
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(AppTheme.palePurple, in: Capsule())
                            .foregroundStyle(AppTheme.purple)
                    }
                    if region.states.count > 4 {
                        Text("+\(region.states.count - 4)")
                            .font(.system(size: 9, weight: .semibold))
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(AppTheme.palePurple, in: Capsule())
                            .foregroundStyle(AppTheme.purple)
                    }
                }
            }

            Divider()

            if candidates.isEmpty {
                if loadedStates == 0 {
                    HStack { Spacer(); ProgressView(); Spacer() }.padding()
                } else {
                    Text("Nenhum dado disponível.")
                        .font(.caption).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            } else {
                // Barras por candidato
                VStack(spacing: 10) {
                    ForEach(topCandidates) { candidate in
                        CandidateBarRow(candidate: candidate)
                    }
                }
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
}

// MARK: - Linha de Barra de Candidato
private struct CandidateBarRow: View {
    let candidate: AggregatedCandidate

    private var barColor: Color {
        Color(hex: candidate.mapDarkColor)
    }

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 8) {
                // Foto
                AsyncImage(url: APIClient.imageURL(candidate.foto)) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFill()
                    } else {
                        Image(systemName: "person.fill")
                            .resizable().scaledToFit()
                            .padding(6)
                            .foregroundStyle(AppTheme.purple)
                    }
                }
                .frame(width: 32, height: 32)
                .background(AppTheme.palePurple)
                .clipShape(Circle())

                // Nome e partido
                VStack(alignment: .leading, spacing: 1) {
                    Text(candidate.nomeUrna)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text("\(candidate.numero) • \(candidate.partido)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Percentual
                Text(String(format: "%.1f%%", candidate.percentual))
                    .font(.subheadline.bold())
                    .foregroundStyle(barColor)
                    .monospacedDigit()

                // Votos
                Text(candidate.votos.ptBR)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            // Barra de progresso
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(candidate.percentual / 100), height: 8)
                        .animation(.spring(duration: 0.6), value: candidate.percentual)
                }
            }
            .frame(height: 8)
        }
    }
}
