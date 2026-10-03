import SwiftUI

struct CandidatesScreen: View {
    private enum FilterSheet: String, Identifiable { case office, state; var id: String { rawValue } }
    @StateObject private var store = ResultStore()
    @State private var office: Office = .governador
    @State private var state = ""
    @State private var activeSheet: FilterSheet?
    private var availableOffices: [Office] { [.governador, .senador, .deputadoFederal, .deputadoEstadual] }
    private var queryKey: String { "\(office.rawValue)|\(state)" }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SelectionField(title: "Estado", value: state.isEmpty ? "Selecione uma UF" : state) { activeSheet = .state }
                    SelectionField(title: "Cargo", value: office.title) { activeSheet = .office }
                }
                if state.isEmpty {
                    ContentUnavailableView("Selecione um estado", systemImage: "map", description: Text("As candidaturas estaduais serão exibidas aqui."))
                } else if store.loading || store.errorMessage != nil {
                    LoadingOrError(loading: store.loading, message: store.errorMessage) { Task { await load() } }
                } else if let result = store.result {
                    Section("\(result.cargoNome) · \(state) — \(result.candidatos.count) candidaturas") {
                        ForEach(result.orderedCandidates) { candidate in
                            HStack(spacing: 12) {
                                AsyncImage(url: APIClient.imageURL(candidate.foto)) { phase in
                                    if let image = phase.image { image.resizable().scaledToFill() }
                                    else { Image(systemName: "person.crop.square").resizable().scaledToFit().padding(8).foregroundStyle(AppTheme.purple) }
                                }.frame(width: 52, height: 64).background(AppTheme.palePurple).clipShape(RoundedRectangle(cornerRadius: 7))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(candidate.nomeUrna).font(.subheadline.bold())
                                    Text("\(candidate.numero) · \(candidate.partido)").font(.caption).foregroundStyle(AppTheme.purple)
                                    Text(candidate.nome).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                                }
                            }.padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Candidatos")
            .task(id: queryKey) {
                while !Task.isCancelled {
                    await load()
                    try? await Task.sleep(nanoseconds: 30_000_000_000)
                }
            }
            .refreshable { await load() }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .state:
                    SelectionSheet(title: "Selecione o estado", options: brazilStates.map { .init(id: $0, title: $0) }, selectedID: state) { state = $0 }
                case .office:
                    SelectionSheet(title: "Selecione o cargo", options: availableOffices.map { .init(id: $0.rawValue, title: $0.title) }, selectedID: office.rawValue, showSearch: false) { id in
                        if let selected = Office(rawValue: id) { office = selected }
                    }
                }
            }
        }
    }

    private func load() async {
        guard !state.isEmpty else { store.result = nil; return }
        await store.load(office: office, state: state)
    }
}