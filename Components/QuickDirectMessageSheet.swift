import SwiftUI

struct QuickDirectMessageSheet: View {
    let profile: UserProfile
    let onSent: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var messageText: String = ""
    @State private var isSending: Bool = false
    @State private var errorMessage: String?

    private struct DirectMessageBody: Encodable {
        let targetUserId: String
        let content: String
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    if let url = profile.photos.first?.bestURL {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().scaledToFill()
                            } else {
                                Circle().fill(AppTheme.Colors.chipUnselected)
                            }
                        }
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(profile.firstName), \(profile.age)")
                            .font(AppTheme.Typography.headline())
                            .foregroundStyle(AppTheme.Colors.darkGray)
                        if !profile.approximateLocation.isEmpty {
                            Text(profile.approximateLocation)
                                .font(AppTheme.Typography.caption())
                                .foregroundStyle(AppTheme.Colors.textGray)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))

                TextField("Escreva uma mensagem para \(profile.firstName)...", text: $messageText, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(14)
                    .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                            .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                    )

                if let errorMessage {
                    Text(errorMessage)
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.primaryRed)
                }

                PrimaryButton(
                    title: "Enviar mensagem",
                    isEnabled: !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    isLoading: isSending
                ) {
                    Task { await send() }
                }

                Spacer()
            }
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.Colors.background)
            .navigationTitle("Mensagem direta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                        .foregroundStyle(AppTheme.Colors.primaryRed)
                }
            }
        }
    }

    private func send() async {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSending = true
        errorMessage = nil
        do {
            try await APIClient.shared.requestVoid(
                path: "/likes/message",
                method: "POST",
                body: DirectMessageBody(
                    targetUserId: profile.id.uuidString.lowercased(),
                    content: trimmed
                )
            )
            onSent()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSending = false
    }
}
