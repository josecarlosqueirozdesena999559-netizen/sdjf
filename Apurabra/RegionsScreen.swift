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
    private var activeQueryKey: String?

    func load(office: Office, round: ElectionRound) async {
        let queryKey = "\(office.rawValue)|\(round.rawValue)"
        if activeQueryKey != queryKey {
            activeQueryKey = queryKey
            regionResults = [:]
            loading = true
            if let cached = await APIClient.shared.cachedMapSummary(office: office, round: round) {
                guard activeQueryKey == queryKey else { return }
                regionResults = reportedResults(cached.resultados ?? [:], round: round)
            }
        }
        loading = regionResults.isEmpty
        errorMessage = nil
        do {
            let summary = try await APIClient.shared.mapSummary(office: office, round: round)
            guard activeQueryKey == queryKey else { return }
            regionResults = reportedResults(summary.resultados ?? [:], round: round)
            if regionResults.isEmpty {
                errorMessage = "Ainda não há resultados apurados para o \(round.title). As regiões continuam disponíveis, sem exibir votos zerados como se fossem dados reais."
            }
        } catch {
            guard activeQueryKey == queryKey else { return }
            if regionResults.isEmpty { errorMessage = "Não foi possível carregar as regiões. Tente novamente." }
        }
        loading = false
    }

    private func reportedResults(_ results: [String: ElectionResult], round: ElectionRound) -> [String: ElectionResult] {
        results.filter { _, result in
            (result.turno == nil || result.turno == round.rawValue) && result.hasReportedResults
        }
    }

    // Agrega candidatos de vários estados somando votos
    func aggregated(for region: BrazilRegion, state selectedState: String? = nil) -> [AggregatedCandidate] {
        var totals: [String: AggregatedCandidate] = [:]
        var totalVotes = 0

        let states = selectedState.map { [$0] } ?? region.states
        for uf in states {
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
    @AppStorage("selectedElectionRound") private var selectedRoundRawValue = 1
    @State private var selectedState: String?
    private var round: ElectionRound { ElectionRound(rawValue: selectedRoundRawValue) ?? .first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Text("Presidente · \(round.title)")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    Text("Toque numa UF para filtrar; toque novamente ou em Todos para ver a região completa.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    if let error = store.errorMessage {
                        Label(error, systemImage: "info.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(AppTheme.palePurple, in: RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                    }

                    ForEach(BrazilRegion.all) { region in
                        let filteredState = selectedState.flatMap { region.states.contains($0) ? $0 : nil }
                        if selectedState == nil || filteredState != nil {
                            RegionCard(
                                region: region,
                                candidates: store.aggregated(for: region, state: filteredState),
                                loadedStates: filteredState.map { store.regionResults[$0] == nil ? 0 : 1 }
                                    ?? store.loadedStates(for: region),
                                selectedState: filteredState,
                                loading: store.loading,
                                onSelectState: { state in
                                    selectedState = selectedState == state ? nil : state
                                }
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
    let selectedState: String?
    let loading: Bool
    let onSelectState: (String?) -> Void

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
                    Text(selectedState.map { "UF \($0) selecionada" } ?? "\(loadedStates)/\(region.states.count) estados carregados")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Estados em pill
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    if selectedState != nil {
                        Button("Todos") { onSelectState(nil) }
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(AppTheme.palePurple, in: Capsule())
                            .foregroundStyle(AppTheme.purple)
                    }
                    ForEach(region.states, id: \.self) { uf in
                        Button { onSelectState(uf) } label: {
                            Text(uf)
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 7).padding(.vertical, 4)
                                .background(selectedState == uf ? AppTheme.purple : AppTheme.palePurple, in: Capsule())
                                .foregroundStyle(selectedState == uf ? Color.white : AppTheme.purple)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            if candidates.isEmpty {
                if loadedStates == 0 {
                    Text(loading ? "Carregando resultados desta região…" : "Ainda não há resultados apurados para esta região.")
                        .font(.caption).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    Text("Ainda não há votos apurados nesta região.")
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
