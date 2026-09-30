import SwiftUI

struct CandidatesScreen: View {
    @StateObject private var store = ResultStore()
    @State private var office: Office = .governador
    @State private var state = ""
    private var availableOffices: [Office] { [.governador, .senador, .deputadoFederal, .deputadoEstadual] }
    private var queryKey: String { "\(office.rawValue)|\(state)" }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    BrandHeader()
                    Picker("Estado", selection: $state) {
                        Text("Selecione uma UF").tag("")
                        ForEach(brazilStates, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Cargo", selection: $office) { ForEach(availableOffices) { Text($0.title).tag($0) } }
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
            .task(id: queryKey) { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        guard !state.isEmpty else { store.result = nil; return }
        await store.load(office: office, state: state)
    }
}