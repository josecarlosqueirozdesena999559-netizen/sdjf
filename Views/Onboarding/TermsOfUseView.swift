import SwiftUI

struct TermsOfUseView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var activeDocument: LegalDocument?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Quase lá!")
                    .font(AppTheme.Typography.largeTitle())
                    .foregroundStyle(AppTheme.Colors.darkGray)

                Text("Revise nossos termos e diretrizes antes de continuar.")
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(AppTheme.Colors.textGray)
            }
            .padding(.top, 12)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(LegalContent.documents) { document in
                        Button {
                            activeDocument = document
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: document.iconName)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(AppTheme.Colors.primaryRed)
                                    .frame(width: 40, height: 40)
                                    .background(AppTheme.Colors.primaryRed.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(document.title)
                                        .font(AppTheme.Typography.headline())
                                        .foregroundStyle(AppTheme.Colors.darkGray)
                                    Text(document.subtitle)
                                        .font(AppTheme.Typography.caption())
                                        .foregroundStyle(AppTheme.Colors.textGray)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AppTheme.Colors.textGray)
                            }
                            .padding(14)
                            .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                                    .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                viewModel.acceptedTerms.toggle()
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: viewModel.acceptedTerms ? "checkmark.square.fill" : "square")
                        .font(.system(size: 22))
                        .foregroundStyle(viewModel.acceptedTerms ? AppTheme.Colors.primaryRed : AppTheme.Colors.textGray)

                    Text("Li e concordo com os Termos de Uso e a Política de Privacidade.")
                        .font(AppTheme.Typography.subheadline())
                        .foregroundStyle(AppTheme.Colors.darkGray)
                        .multilineTextAlignment(.leading)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(cornerRadius: AppTheme.Radius.medium)
            }
            .buttonStyle(.plain)

            PrimaryButton(
                title: "Aceitar e continuar",
                isEnabled: viewModel.acceptedTerms
            ) {
                viewModel.acceptTermsAndAdvance()
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .sheet(item: $activeDocument) { doc in
            LegalDocumentSheet(document: doc)
        }
    }
}

struct LegalDocumentSheet: View {
    let document: LegalDocument
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(document.content)
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(AppTheme.Colors.darkGray)
                    .padding(AppTheme.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.Colors.primaryRed)
                }
            }
        }
    }
}
