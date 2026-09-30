import SwiftUI

enum AppTheme {
    static let purple = Color(red: 0.33, green: 0.16, blue: 0.51)
    static let palePurple = Color(red: 0.95, green: 0.93, blue: 0.97)
    static let background = Color(uiColor: .systemGroupedBackground)
}

struct BrandHeader: View {
    var body: some View {
        HStack(spacing: 10) {
            Image("ApurabraLogo").resizable().scaledToFit().frame(width: 36, height: 36).clipShape(RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 1) {
                Text("Apurabra").font(.headline.bold())
                Text("Eleições Gerais 2026").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

struct LoadingOrError: View {
    let loading: Bool
    let message: String?
    var retry: () -> Void
    var body: some View {
        if loading { ProgressView("Carregando…").frame(maxWidth: .infinity).padding(40) }
        else if let message {
            ContentUnavailableView("Dados indisponíveis", systemImage: "wifi.exclamationmark", description: Text(message))
            Button("Tentar novamente", action: retry).buttonStyle(.borderedProminent)
        }
    }
}

extension Int { var ptBR: String { formatted(.number.locale(Locale(identifier: "pt_BR"))) } }
extension Double { var percentBR: String { formatted(.number.locale(Locale(identifier: "pt_BR")).precision(.fractionLength(2))) + "%" } }