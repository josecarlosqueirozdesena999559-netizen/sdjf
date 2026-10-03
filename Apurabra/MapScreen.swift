import SwiftUI
import WebKit

struct MapScreen: View {
    @StateObject private var store = ResultStore()
    @State private var office: Office = .presidente
    @State private var selectedState = ""
    @State private var colorsByOffice: [Office: [String: String]] = [:]

    private var refreshKey: String { "\(office.rawValue)|\(selectedState)" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Cargo", selection: $office) {
                        Text("Presidente").tag(Office.presidente)
                        Text("Governador").tag(Office.governador)
                    }.pickerStyle(.segmented)
                    BrazilMapView(selectedState: $selectedState, colors: colorsByOffice[office] ?? [:]) { state in Task { await select(state) } }
                        .frame(height: 430).background(.background, in: RoundedRectangle(cornerRadius: 18))
                    if selectedState.isEmpty {
                        ContentUnavailableView("Selecione um estado", systemImage: "hand.tap", description: Text("Toque no mapa para consultar a apuração."))
                    } else if store.loading || store.errorMessage != nil {
                        LoadingOrError(loading: store.loading, message: store.errorMessage) { Task { await refreshSelectedState() } }
                    } else if let result = store.result {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack { Text("\(office.title) · \(selectedState)").font(.headline); Spacer(); Text((result.progress * 100).percentBR).font(.headline).foregroundStyle(AppTheme.purple) }
                            ProgressView(value: result.progress).tint(AppTheme.purple)
                            Text("Votos válidos: \(result.votosValidos.ptBR)").font(.caption).foregroundStyle(.secondary)
                            Text("Última atualização: \(result.atualizadoEmFormatado)").font(.caption).foregroundStyle(.secondary)
                            if let leader = result.orderedCandidates.first, leader.votos > 0 {
                                HStack(spacing: 7) {
                                    Circle().fill(Color(hex: result.isFinalized ? leader.mapDarkColorHex : leader.mapLightColorHex)).frame(width: 10, height: 10)
                                    Text(result.isFinalized ? "Vencedor no estado: \(leader.nomeUrna)" : "Liderando no estado: \(leader.nomeUrna)")
                                        .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                                }
                            }
                        }.padding().background(.background, in: RoundedRectangle(cornerRadius: 16))
                        ForEach(result.orderedCandidates) { CandidateRow(candidate: $0) }
                    }
                }.padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Mapa da apuração")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: refreshKey) {
                guard !selectedState.isEmpty else { return }
                while !Task.isCancelled {
                    await refreshSelectedState()
                    try? await Task.sleep(nanoseconds: 30_000_000_000)
                }
            }
        }
    }

    private func select(_ state: String) async {
        if state == selectedState {
            selectedState = ""
            store.result = nil
            return
        }
        selectedState = state
    }

    private func refreshSelectedState() async {
        guard !selectedState.isEmpty else { return }
        let state = selectedState
        await store.load(office: office, state: state)
        if let result = store.result, let leader = result.orderedCandidates.first, leader.votos > 0 {
            colorsByOffice[office, default: [:]][state] = result.isFinalized ? leader.mapDarkColorHex : leader.mapLightColorHex
        }
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
        web.isOpaque = false; web.backgroundColor = .clear; web.scrollView.isScrollEnabled = false
        if let url = Bundle.main.url(forResource: "mapa-brasil", withExtension: "svg"), let svg = try? String(contentsOf: url, encoding: .utf8) {
            web.loadHTMLString(html(svg), baseURL: nil)
        }
        return web
    }
    func updateUIView(_ web: WKWebView, context: Context) {
        let data = (try? JSONSerialization.data(withJSONObject: colors)) ?? Data("{}".utf8)
        let json = String(data: data, encoding: .utf8) ?? "{}"
        web.evaluateJavaScript("paint(\(json), '\(selectedState)')")
    }

    private func html(_ svg: String) -> String { """
    <!doctype html><html><head><meta name='viewport' content='width=device-width,initial-scale=1,maximum-scale=1'>
    <style>*{box-sizing:border-box}html,body{margin:0;width:100%;height:100%;background:transparent;overflow:hidden}body{display:grid;place-items:center;padding:8px}svg{width:100%;height:100%;max-height:420px}.state{fill:#ddd7e4;stroke:#fff;stroke-width:1;cursor:pointer}.label{font:800 8px -apple-system;fill:#25152f;stroke:#fff;stroke-width:1.6px;paint-order:stroke;pointer-events:none;text-anchor:middle;dominant-baseline:central}</style></head><body>\(svg)
    <script>
    const states=['AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'];
    states.forEach(uf=>{const n=document.getElementById(uf);if(!n)return;n.onclick=()=>window.webkit.messageHandlers.stateSelected.postMessage(uf);const b=n.getBBox(),t=document.createElementNS('http://www.w3.org/2000/svg','text');t.setAttribute('x',b.x+b.width/2);t.setAttribute('y',b.y+b.height/2);t.setAttribute('class','label');t.textContent=uf;n.ownerSVGElement.appendChild(t)});
    function paint(colors,selected){states.forEach(uf=>{const n=document.getElementById(uf);if(!n)return;n.style.fill=colors[uf]||'#ddd7e4';n.style.stroke=uf===selected?'#2d123f':'#fff';n.style.strokeWidth=uf===selected?'2.5':'1'})}
    </script></body></html>
    """ }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: BrazilMapView
        init(_ parent: BrazilMapView) { self.parent = parent }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if let state = message.body as? String { parent.onSelect(state) }
        }
    }
}