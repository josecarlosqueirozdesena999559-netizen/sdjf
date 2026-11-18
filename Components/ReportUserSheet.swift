import SwiftUI

struct ReportUserSheet: View {
    let targetUserId: String
    let targetName: String
    let onBlocked: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    private let reasons = [
        "Assédio ou mensagens ofensivas",
        "Perfil falso ou golpe",
        "Spam ou links suspeitos",
        "Conteúdo impróprio",
        "Outro motivo"
    ]

    @State private var selectedReason: String = "Assédio ou mensagens ofensivas"
    @State private var details: String = ""
    @State private var isSubmitting = false
    @State private var resultMessage: String?
    @State private var errorMessage: String?
    @State private var didSubmit = false

    private struct ReportBody: Encodable {
        let reason: String
        let details: String?
    }

    private struct ReportResponse: Decodable {
        struct Analysis: Decodable {
            let evidenceScore: Int
            let evidenceSummary: String
            let distinctReporterIps: Int
            let accountAction: String
        }
        let analysis: Analysis?
    }

    var body: some View {
        NavigationStack {
            List {
                if didSubmit {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Denúncia analisada e registrada", systemImage: "checkmark.shield.fill")
                                .font(AppTheme.Typography.headline())
                                .foregroundStyle(AppTheme.Colors.successGreen)

                            if let resultMessage {
                                Text(resultMessage)
                                    .font(AppTheme.Typography.body())
                                    .foregroundStyle(AppTheme.Colors.darkGray)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(AppTheme.Colors.white)

                    Section {
                        Button(role: .destructive) {
                            Task { await blockNow() }
                        } label: {
                            Label("Bloquear \(targetName)", systemImage: "hand.raised.fill")
                                .foregroundStyle(AppTheme.Colors.primaryRed)
                        }

                        Button("Concluir") {
                            dismiss()
                        }
                        .foregroundStyle(AppTheme.Colors.darkGray)
                    }
                    .listRowBackground(AppTheme.Colors.white)
                } else {
                    Section("Motivo da denúncia") {
                        ForEach(reasons, id: \.self) { reason in
                            Button {
                                selectedReason = reason
                            } label: {
                                HStack {
                                    Text(reason)
                                        .font(AppTheme.Typography.body())
                                        .foregroundStyle(AppTheme.Colors.darkGray)
                                    Spacer()
                                    if selectedReason == reason {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AppTheme.Colors.primaryRed)
                                    }
                                }
                            }
                        }
                    }
                    .listRowBackground(AppTheme.Colors.white)

                    Section("Detalhes (opcional)") {
                        TextField("Descreva o que aconteceu...", text: $details, axis: .vertical)
                            .lineLimit(3...6)
                            .font(AppTheme.Typography.body())
                    }
                    .listRowBackground(AppTheme.Colors.white)

                    if let errorMessage {
                        Section {
                            Text(errorMessage)
                                .font(AppTheme.Typography.caption())
                                .foregroundStyle(AppTheme.Colors.primaryRed)
                        }
                        .listRowBackground(AppTheme.Colors.white)
                    }

                    Section {
                        Button {
                            Task { await submit() }
                        } label: {
                            HStack {
                                Spacer()
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Enviar denúncia")
                                        .font(AppTheme.Typography.headline())
                                        .foregroundStyle(.white)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                        .listRowBackground(AppTheme.Colors.primaryRed)
                        .disabled(isSubmitting)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.background)
            .navigationTitle("Denunciar \(targetName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                        .foregroundStyle(AppTheme.Colors.primaryRed)
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        do {
            let trimmed = details.trimmingCharacters(in: .whitespacesAndNewlines)
            let res: ReportResponse = try await APIClient.shared.request(
                path: "/users/\(targetUserId)/report",
                method: "POST",
                body: ReportBody(reason: selectedReason, details: trimmed.isEmpty ? nil : trimmed)
            )
            if let analysis = res.analysis {
                switch analysis.accountAction {
                case "DELETED_PERMANENTLY":
                    resultMessage = "Conta excluída automaticamente após 5 denúncias de IPs distintos. Evidências: \(analysis.evidenceSummary)."
                case "SUSPENDED_30_DAYS":
                    resultMessage = "Conta suspensa por 30 dias após 3 denúncias de IPs distintos. Evidências: \(analysis.evidenceSummary)."
                default:
                    resultMessage = "O sistema analisou o histórico de mensagens e comportamento (\(analysis.evidenceSummary))."
                }
            } else {
                resultMessage = "Sua denúncia foi registrada e analisada."
            }
            didSubmit = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    private func blockNow() async {
        try? await APIClient.shared.requestVoid(path: "/users/\(targetUserId)/block", method: "POST")
        onBlocked?()
        dismiss()
    }
}
