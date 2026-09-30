import SwiftUI

struct ResultsScreen: View {
    @StateObject private var store = ResultStore()
    @State private var office: Office = .presidente
    @State private var state = ""
    @State private var municipality = ""
    private var queryKey: String { "\(office.rawValue)|\(state)|\(municipality)" }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    BrandHeader().padding(.horizontal)
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
            .task(id: queryKey) { await reload() }
            .refreshable { await reload() }
        }
    }

    private var filters: some View {
        VStack(spacing: 12) {
            Picker("Cargo", selection: $office) { ForEach(Office.allCases) { Text($0.title).tag($0) } }
                .pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: office) { _, next in if next == .presidente { state = ""; municipality = "" } }
            Divider()
            Picker("Abrangência", selection: $state) {
                Text(office == .presidente ? "Brasil" : "Selecione um estado").tag("")
                ForEach(brazilStates, id: \.self) { Text($0).tag($0) }
            }.pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: state) { _, next in municipality = ""; Task { await store.loadMunicipalities(state: next) } }
            if !state.isEmpty {
                Divider()
                Picker("Município", selection: $municipality) {
                    Text("Todo o estado de \(state)").tag("")
                    ForEach(store.municipalities) { Text($0.nome).tag($0.nome) }
                }.pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
            }
        }.padding().background(.background, in: RoundedRectangle(cornerRadius: 16)).padding(.horizontal)
    }

    @ViewBuilder private func resultContent(_ result: ElectionResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text("Apuração geral"); Spacer(); Text((result.progress * 100).percentBR).font(.title3.bold()).foregroundStyle(AppTheme.purple) }
            ProgressView(value: result.progress).tint(AppTheme.purple)
            Text("\(result.secoesTotalizadas.ptBR) de \(result.secoesTotal.ptBR) seções totalizadas").font(.caption).foregroundStyle(.secondary)
            if let message = result.mensagem { Text(message).font(.footnote).foregroundStyle(.secondary) }
        }.padding().background(.background, in: RoundedRectangle(cornerRadius: 16)).padding(.horizontal)

        HStack {
            Text("\(result.cargoNome) · \(result.abrangencia.nome)").font(.headline)
            Spacer()
            Text("Válidos: \(result.votosValidos.ptBR)").font(.caption).foregroundStyle(.secondary)
        }.padding(.horizontal)
        ForEach(result.orderedCandidates) { CandidateRow(candidate: $0) }
    }

    private func reload() async {
        guard office == .presidente || !state.isEmpty else { store.result = nil; return }
        await store.load(office: office, state: state, municipality: municipality)
    }
}

struct CandidateRow: View {
    let candidate: Candidate
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: APIClient.imageURL(candidate.foto)) { phase in
                if let image = phase.image { image.resizable().scaledToFill() }
                else { Image(systemName: "person.crop.square").resizable().scaledToFit().padding(10).foregroundStyle(AppTheme.purple) }
            }.frame(width: 58, height: 70).background(AppTheme.palePurple).clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(candidate.nomeUrna).font(.subheadline.bold())
                if let vice = candidate.vice { Text("Vice: \(vice)").font(.caption).foregroundStyle(.secondary) }
                Text("\(candidate.numero) · \(candidate.partido)").font(.caption).foregroundStyle(AppTheme.purple)
                if let status = candidate.situacao { Text(status).font(.caption2).foregroundStyle(.secondary) }
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 4) {
                Gauge(value: candidate.percentual, in: 0...100) { EmptyView() }.gaugeStyle(.accessoryCircularCapacity).tint(AppTheme.purple).frame(width: 42, height: 42)
                Text(candidate.percentual.percentBR).font(.caption.bold()).foregroundStyle(AppTheme.purple)
                Text("\(candidate.votos.ptBR) votos").font(.caption2).foregroundStyle(.secondary)
            }
        }.padding().background(.background, in: RoundedRectangle(cornerRadius: 16)).padding(.horizontal)
    }
}