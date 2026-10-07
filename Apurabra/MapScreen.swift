import SwiftUI
import WebKit

struct MapScreen: View {
    private static let colorStorageKey = "apurabra.map.colors.v1"
    @StateObject private var store = ResultStore()
    @State private var office: Office = .presidente
    @AppStorage("selectedElectionRound") private var selectedRoundRawValue = 1
    @State private var selectedState = ""
    @State private var colorsByMode: [String: [String: String]] = Self.loadSavedColors()
    @State private var hasResultsByMode: [String: Bool] = [:]

    private var round: ElectionRound { ElectionRound(rawValue: selectedRoundRawValue) ?? .first }
    private var modeKey: String { "\(office.rawValue)|\(round.rawValue)" }
    private var refreshKey: String { "\(modeKey)|\(selectedState)" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Turno", selection: $selectedRoundRawValue) {
                        ForEach(ElectionRound.allCases) { item in Text(item.title).tag(item.rawValue) }
                    }
                    .pickerStyle(.segmented)

                    Picker("Cargo", selection: $office) {
                        Text("Presidente").tag(Office.presidente)
                        Text("Governador").tag(Office.governador)
                    }
                    .pickerStyle(.segmented)

                    BrazilMapView(selectedState: .constant(""), colors: colorsByMode[modeKey] ?? [:]) { state in
                        select(state)
                    }
                    .frame(height: 430)
                    .background(.background, in: RoundedRectangle(cornerRadius: 18))

                    if hasResultsByMode[modeKey] == false {
                        Label("Ainda não há resultados apurados para o \(round.title). O mapa não exibirá votos ou cores simulados.", systemImage: "info.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(AppTheme.palePurple, in: RoundedRectangle(cornerRadius: 12))
                    } else {
                        ContentUnavailableView(
                            "Selecione um estado",
                            systemImage: "hand.tap",
                            description: Text("Toque no mapa para consultar a apuração.")
                        )
                    }
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Mapa da apuração")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: Binding(
                get: { !selectedState.isEmpty },
                set: { if !$0 { closeDetails() } }
            )) {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 12) {
                            if store.loading || store.errorMessage != nil {
                                LoadingOrError(loading: store.loading, message: store.errorMessage) {
                                    Task { await refreshSelectedState() }
                                }
                            } else if let result = store.result, result.hasReportedResults {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("\(office.title) · \(selectedState)").font(.headline)
                                        Spacer()
                                        Text((result.progress * 100).percentBR)
                                            .font(.headline)
                                            .foregroundStyle(AppTheme.purple)
                                    }
                                    ProgressView(value: result.progress).tint(AppTheme.purple)
                                    Text("Votos válidos: \(result.votosValidos.ptBR)")
                                        .font(.caption).foregroundStyle(.secondary)
                                    Text("Última atualização: \(result.atualizadoEmFormatado)")
                                        .font(.caption).foregroundStyle(.secondary)
                                    if let leader = result.orderedCandidates.first, leader.votos > 0 {
                                        HStack(spacing: 7) {
                                            Circle()
                                                .fill(Color(hex: result.leaderCannotBeOvertaken ? leader.mapDarkColorHex : leader.mapLightColorHex))
                                                .frame(width: 10, height: 10)
                                            Text(result.leaderCannotBeOvertaken
                                                 ? "Vitória assegurada no estado: \(leader.nomeUrna)"
                                                 : "Liderando no estado: \(leader.nomeUrna)")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding()
                                .background(.background, in: RoundedRectangle(cornerRadius: 16))

                                ForEach(result.orderedCandidates) { CandidateRow(candidate: $0, round: round) }
                            } else {
                                ContentUnavailableView(
                                    "Aguardando apuração",
                                    systemImage: "clock",
                                    description: Text("Ainda não há votos apurados para o \(round.title) em \(selectedState).")
                                )
                            }
                        }
                        .padding()
                    }
                    .background(AppTheme.background)
                    .navigationTitle(selectedState)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: closeDetails) {
                                Image(systemName: "xmark")
                            }
                            .accessibilityLabel("Fechar")
                        }
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .task(id: refreshKey) {
                guard !selectedState.isEmpty else { return }
                while !Task.isCancelled {
                    await refreshSelectedState()
                    try? await Task.sleep(nanoseconds: 30_000_000_000)
                }
            }
            .task(id: modeKey) {
                while !Task.isCancelled {
                    await refreshMapSummary()
                    try? await Task.sleep(nanoseconds: 20_000_000_000)
                }
            }
            .onChange(of: office) { _, _ in closeDetails() }
            .onChange(of: round) { _, _ in closeDetails() }
        }
    }

    private func select(_ state: String) {
        selectedState = state
    }

    private func refreshMapSummary() async {
        let currentOffice = office
        let currentRound = round
        let currentModeKey = modeKey
        if colorsByMode[currentModeKey]?.isEmpty != false,
           let cached = await APIClient.shared.cachedMapSummary(office: currentOffice, round: currentRound) {
            hasResultsByMode[currentModeKey] = cached.resultados?.values.contains(where: \.hasReportedResults) ?? !cached.cores.isEmpty
            saveColors(cached.cores, for: currentModeKey)
        }
        if let summary = try? await APIClient.shared.mapSummary(office: currentOffice, round: currentRound) {
            guard office == currentOffice, round == currentRound else { return }
            hasResultsByMode[currentModeKey] = summary.resultados?.values.contains(where: \.hasReportedResults) ?? !summary.cores.isEmpty
            saveColors(summary.cores, for: currentModeKey)
        }
    }

    private func closeDetails() {
        selectedState = ""
        store.result = nil
    }

    private func refreshSelectedState() async {
        guard !selectedState.isEmpty else { return }
        let state = selectedState
        let currentOffice = office
        let currentRound = round
        await store.load(office: currentOffice, state: state, round: currentRound)
        guard selectedState == state, office == currentOffice, round == currentRound else { return }
        if let result = store.result, let leader = result.orderedCandidates.first, leader.votos > 0 {
            var colors = colorsByMode[modeKey] ?? [:]
            colors[state] = result.leaderCannotBeOvertaken
                ? leader.mapDarkColorHex
                : leader.mapLightColorHex
            saveColors(colors, for: modeKey)
        }
    }

    private static func loadSavedColors() -> [String: [String: String]] {
        guard let data = UserDefaults.standard.data(forKey: colorStorageKey) else { return [:] }
        return (try? JSONDecoder().decode([String: [String: String]].self, from: data)) ?? [:]
    }

    private func saveColors(_ colors: [String: String], for mode: String) {
        guard colorsByMode[mode] != colors else { return }
        var saved = colorsByMode
        saved[mode] = colors
        colorsByMode = saved
        guard let data = try? JSONEncoder().encode(saved) else { return }
        UserDefaults.standard.set(data, forKey: Self.colorStorageKey)
    }
}

struct BrazilMapView: UIViewRepresentable {
    @Binding var selectedState: String
    let colors: [String: String]
    let onSelect: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "stateSelected")
        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.isScrollEnabled = false
        web.navigationDelegate = context.coordinator
        if let url = Bundle.main.url(forResource: "mapa-brasil", withExtension: "svg"),
           let svg = try? String(contentsOf: url, encoding: .utf8) {
            web.loadHTMLString(html(svg), baseURL: nil)
        }
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.paint(in: web)
    }

    private func html(_ svg: String) -> String { """
    <!doctype html><html><head><meta name='viewport' content='width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no'>
    <style>*{box-sizing:border-box;-webkit-tap-highlight-color:transparent}html,body{margin:0;width:100%;height:100%;background:transparent;overflow:hidden;user-select:none;-webkit-user-select:none}body{display:grid;place-items:center;padding:8px}svg{width:100%;height:100%;max-height:420px;outline:none}.state{fill:#ddd7e4;stroke:#fff;stroke-width:1;cursor:pointer;outline:none}.state:focus,.state:active{outline:none}.label{font:800 8px -apple-system;fill:#25152f;stroke:#fff;stroke-width:1.6px;paint-order:stroke;pointer-events:none;text-anchor:middle;dominant-baseline:central}</style></head><body>\(svg)
    <script>
    const states=['AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'];
    states.forEach(uf=>{const n=document.getElementById(uf);if(!n)return;n.setAttribute('tabindex','-1');n.onclick=()=>window.webkit.messageHandlers.stateSelected.postMessage(uf);const b=n.getBBox(),t=document.createElementNS('http://www.w3.org/2000/svg','text');t.setAttribute('x',b.x+b.width/2);t.setAttribute('y',b.y+b.height/2);t.setAttribute('class','label');t.textContent=uf;n.ownerSVGElement.appendChild(t)});
    function paint(colors){states.forEach(uf=>{const n=document.getElementById(uf);if(!n)return;n.style.fill=colors[uf]||'#ddd7e4';n.style.stroke='#fff';n.style.strokeWidth='1'})}
    </script></body></html>
    """ }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var parent: BrazilMapView
        init(_ parent: BrazilMapView) { self.parent = parent }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            paint(in: webView)
        }

        func paint(in webView: WKWebView) {
            let data = (try? JSONSerialization.data(withJSONObject: parent.colors)) ?? Data("{}".utf8)
            let json = String(data: data, encoding: .utf8) ?? "{}"
            webView.evaluateJavaScript("paint(\(json))")
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if let state = message.body as? String { parent.onSelect(state) }
        }
    }
}
