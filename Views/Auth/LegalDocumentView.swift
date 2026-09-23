import SwiftUI

struct LegalDocumentView: View {
    let title: String
    let content: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(content)
                    .typographyBody()
                    .foregroundColor(Theme.textPrimary)
                    .padding()
                    // Fix alignment for legal texts
                    .multilineTextAlignment(.leading)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primary)
                }
            }
            .background(Theme.background)
        }
    }
}
