import SwiftUI

struct ResultsScreen: View {
    private enum FilterSheet: String, Identifiable { case office, state, municipality; var id: String { rawValue } }
    @StateObject private var store = ResultStore()
    @State private var round: ElectionRound = .first
    @State private var office: Office = .presidente
    @State private var state = ""
    @State private var municipality = ""
    @State private var activeSheet: FilterSheet?
    private var queryKey: String { "\(round.rawValue)|\(office.rawValue)|\(state)|\(municipality)" }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    filters
                    if office != .presidente && state.isEmpty {
                        ContentUnavailableView("Selecione um estado", systemImage: "map", description: Text("Este cargo possui resultados por unidade da Federação."))
                    } else if store.loading || store.errorMessage != nil {
                        LoadingOrError(loading: store.loading, message: store.errorMessage) { Task { await reload() } }
                    }
                    if let result = store.result { resultContent(result) }
                }.padding(.vertical)
            }
            .background(AppTheme.background)
            .navigationTitle("Resultados")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: queryKey) {
                while !Task.isCancelled {
                    await reload()
                    try? await Task.sleep(nanoseconds: 30_000_000_000)
                }
            }
            .refreshable { await reload() }
            .sheet(item: $activeSheet) { sheet in selectionSheet(sheet) }
            .onChange(of: round) { _, nextRound in
                if !nextRound.availableOffices.contains(office) { office = .presidente }
                municipality = ""
                store.result = nil
            }
        }
    }

    private var filters: some View {
        VStack(spacing: 10) {
            Picker("Turno", selection: $round) {
                ForEach(ElectionRound.allCases) { item in Text(item.title).tag(item) }
            }
            .pickerStyle(.segmented)
            SelectionField(title: "Cargo", value: office.title) { activeSheet = .office }
            SelectionField(title: "Estado", value: state.isEmpty ? "Brasil" : state) { activeSheet = .state }
            if !state.isEmpty {
                SelectionField(title: "Município", value: municipality.isEmpty ? "Todo o estado de \(state)" : municipality) { activeSheet = .municipality }
            }
        }.padding().background(.background, in: RoundedRectangle(cornerRadius: 16)).padding(.horizontal)
    }

    @ViewBuilder private func selectionSheet(_ sheet: FilterSheet) -> some View {
        switch sheet {
        case .office:
            SelectionSheet(title: "Selecione o cargo", options: round.availableOffices.map { .init(id: $0.rawValue, title: $0.title) }, selectedID: office.rawValue, showSearch: false) { id in
                if let selected = Office(rawValue: id) { office = selected }
            }
        case .state:
            SelectionSheet(title: "Selecione a abrangência", options: [.init(id: "", title: "Brasil")] + brazilStates.map { .init(id: $0, title: $0) }, selectedID: state) { id in
                state = id; municipality = ""
                Task { await store.loadMunicipalities(state: id) }
            }
        case .municipality:
            SelectionSheet(title: "Selecione o município", options: [.init(id: "", title: "Todo o estado de \(state)")] + store.municipalities.map { .init(id: $0.nome, title: $0.nome) }, selectedID: municipality) { municipality = $0 }
        }
    }

    @ViewBuilder private func resultContent(_ result: ElectionResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text("Apuração geral"); Spacer(); Text((result.progress * 100).percentBR).font(.title3.bold()).foregroundStyle(AppTheme.purple) }
            ProgressView(value: result.progress).tint(AppTheme.purple)
            Text("\(result.secoesTotalizadas.ptBR) de \(result.secoesTotal.ptBR) seções totalizadas").font(.caption).foregroundStyle(.secondary)
            Text("Última atualização: \(result.atualizadoEmFormatado)")
                .font(.caption).foregroundStyle(.secondary)
            if let message = result.mensagem { Text(message).font(.footnote).foregroundStyle(.secondary) }
        }.padding().background(.background, in: RoundedRectangle(cornerRadius: 16)).padding(.horizontal)

        HStack {
            Text("\(result.cargoNome) · \(result.abrangencia.nome) · \(round.title)").font(.headline)
            Spacer()
            Text("Válidos: \(result.votosValidos.ptBR)").font(.caption).foregroundStyle(.secondary)
        }.padding(.horizontal)
        ForEach(result.orderedCandidates) { CandidateRow(candidate: $0, round: round) }
    }

    private func reload() async {
        guard office == .presidente || !state.isEmpty else { store.result = nil; return }
        await store.load(office: office, state: state, municipality: municipality, round: round)
    }
}

struct CandidateRow: View {
    let candidate: Candidate
    let round: ElectionRound
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: APIClient.imageURL(candidate.foto)) { phase in
                if let image = phase.image { image.resizable().scaledToFill() }
                else { Image(systemName: "person.crop.square").resizable().scaledToFit().padding(10).foregroundStyle(AppTheme.purple) }
            }
            .frame(width: 58, height: 70)
            .background(AppTheme.palePurple)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(candidate.nomeUrna).font(.subheadline.bold())
                if let vice = candidate.vice { Text("Vice: \(vice)").font(.caption).foregroundStyle(.secondary) }
                Text("\(candidate.numero) · \(candidate.partido)").font(.caption).foregroundStyle(AppTheme.purple)
                if let status = candidate.displayedSituation(for: round) { Text(status).font(.caption2).foregroundStyle(.secondary) }
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 5) {
                CandidateProgressRing(percent: candidate.percentual)
                Text("\(candidate.votos.ptBR) votos").font(.caption2).foregroundStyle(.secondary)
            }
        }.padding().background(.background, in: RoundedRectangle(cornerRadius: 16)).padding(.horizontal)
    }
}

private struct CandidateProgressRing: View {
    let percent: Double
    private var progress: Double { min(max(percent / 100, 0), 1) }
    var body: some View {
        ZStack {
            Circle().stroke(AppTheme.palePurple, lineWidth: 5)
            Circle().trim(from: 0, to: progress).stroke(AppTheme.purple, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90))
            Text(percent.formatted(.number.locale(Locale(identifier: "pt_BR")).precision(.fractionLength(1))) + "%")
                .font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.purple).minimumScaleFactor(0.7).lineLimit(1)
        }
        .frame(width: 54, height: 54)
        .accessibilityElement(children: .ignore).accessibilityLabel("Percentual de votos").accessibilityValue(percent.percentBR)
    }
}
