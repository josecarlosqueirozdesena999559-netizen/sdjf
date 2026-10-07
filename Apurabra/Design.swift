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
        if loading { CandidateListSkeleton() }
        else if let message {
            ContentUnavailableView("Dados indisponíveis", systemImage: "wifi.exclamationmark", description: Text(message))
            Button("Tentar novamente", action: retry).buttonStyle(.borderedProminent)
        }
    }
}

struct CandidateListSkeleton: View {
    var rows: Int = 4
    var showsSummary = false

    var body: some View {
        VStack(spacing: 14) {
            if showsSummary {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        SkeletonBlock(width: 112, height: 16)
                        Spacer()
                        SkeletonBlock(width: 54, height: 18)
                    }
                    SkeletonBlock(height: 8)
                    SkeletonBlock(width: 205, height: 11)
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 16))
            }

            ForEach(0..<max(rows, 0), id: \.self) { index in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 58, height: 68)

                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonBlock(width: index.isMultiple(of: 2) ? 138 : 112, height: 13)
                        SkeletonBlock(width: 82, height: 10)
                        SkeletonBlock(width: 104, height: 9)
                    }

                    Spacer(minLength: 6)
                    Circle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 48, height: 48)
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("A carregar resultados")
    }
}

private struct SkeletonBlock: View {
    var width: CGFloat? = nil
    var height: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.primary.opacity(0.08))
            .frame(width: width, height: height)
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
    var showSearch: Bool = true
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var filtered: [SelectionOption] {
        (!showSearch || search.isEmpty) ? options : options.filter { $0.title.localizedCaseInsensitiveContains(search) }
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
            .modify { view in
                if showSearch {
                    view.searchable(text: $search, prompt: "Buscar")
                } else {
                    view
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Fechar") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.white)
    }
}

extension View {
    func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
        modifier(self)
    }
}

extension Color {
    init(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var rgb: UInt64 = 0
        Scanner(string: value).scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
