import SwiftUI

struct TermsOfUseView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showFullTermsPopup: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Termos de uso")
                .font(AppTheme.Typography.largeTitle())
                .foregroundStyle(AppTheme.Colors.darkGray)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.primaryRed)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.Colors.primaryRed.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Termos, Privacidade e Segurança")
                            .font(AppTheme.Typography.headline())
                            .foregroundStyle(AppTheme.Colors.darkGray)
                        Text("Versão \(LegalContent.currentVersion) • Documento completo")
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(AppTheme.Colors.textGray)
                    }
                }

                Text("Antes de concluir seu cadastro, leia os Termos de Uso, a Política de Privacidade (LGPD/ANPD), as Regras de Convivência e as Diretrizes de Segurança.")
                    .font(AppTheme.Typography.subheadline())
                    .foregroundStyle(AppTheme.Colors.textGray)

                SecondaryOutlineButton(title: "Ler documento completo", icon: "doc.plaintext") {
                    showFullTermsPopup = true
                }
            }
            .padding(16)
            .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
            )

            Spacer()

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
        .sheet(isPresented: $showFullTermsPopup) {
            CombinedLegalDocumentSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        }
    }
}

struct CombinedLegalDocumentSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(LegalContent.documents) { doc in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: doc.iconName)
                                    .foregroundStyle(AppTheme.Colors.primaryRed)
                                Text(doc.title)
                                    .font(AppTheme.Typography.title())
                                    .foregroundStyle(AppTheme.Colors.darkGray)
                            }

                            Text(doc.content)
                                .font(AppTheme.Typography.body())
                                .foregroundStyle(AppTheme.Colors.darkGray)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("Termos e Privacidade")
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
