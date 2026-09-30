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
struct SelectionOption: Identifiable {
    let id: String
    let title: String
}

struct SelectionField: View {
    let title: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.caption).foregroundStyle(.secondary)
                    Text(value).font(.body.weight(.semibold)).foregroundStyle(.primary).lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down").font(.caption.bold()).foregroundStyle(AppTheme.purple)
            }
            .padding(.horizontal, 14).frame(minHeight: 58)
            .background(AppTheme.palePurple.opacity(0.65), in: RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
    }
}

struct SelectionSheet: View {
    let title: String
    let options: [SelectionOption]
    let selectedID: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var filtered: [SelectionOption] {
        search.isEmpty ? options : options.filter { $0.title.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { option in
                Button {
                    onSelect(option.id)
                    dismiss()
                } label: {
                    HStack {
                        Text(option.title).foregroundStyle(.primary)
                        Spacer()
                        if option.id == selectedID {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.purple)
                        }
                    }.contentShape(Rectangle()).padding(.vertical, 5)
                }.buttonStyle(.plain)
            }
            .searchable(text: $search, prompt: "Buscar")
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Fechar") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
