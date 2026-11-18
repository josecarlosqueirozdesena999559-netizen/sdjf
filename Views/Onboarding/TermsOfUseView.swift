import SwiftUI

struct TermsOfUseView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showFullTermsPopup: Bool = false
    @State private var didAutoOpen: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Termos de uso")
                .font(AppTheme.Typography.largeTitle())
                .foregroundStyle(AppTheme.Colors.darkGray)
                .padding(.top, 12)

            Spacer()

            Button {
                showFullTermsPopup = true
            } label: {
                Label("Ler termos novamente", systemImage: "doc.text")
                    .font(AppTheme.Typography.subheadline())
                    .foregroundStyle(AppTheme.Colors.primaryRed)
            }
            .buttonStyle(.plain)

            Button {
                viewModel.acceptedTerms.toggle()
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: viewModel.acceptedTerms ? "checkmark.square.fill" : "square")
                        .font(.system(size: 24))
                        .foregroundStyle(viewModel.acceptedTerms ? AppTheme.Colors.primaryRed : AppTheme.Colors.textGray)

                    Text("Li e concordo com os Termos de Uso e a Política de Privacidade.")
                        .font(AppTheme.Typography.subheadline())
                        .foregroundStyle(AppTheme.Colors.darkGray)
                        .multilineTextAlignment(.leading)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                        .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                )
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
        .onAppear {
            if !didAutoOpen {
                didAutoOpen = true
                showFullTermsPopup = true
            }
        }
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
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.Colors.darkGray)
                            .frame(width: 30, height: 30)
                            .background(AppTheme.Colors.chipUnselected, in: Circle())
                    }
                    .accessibilityLabel("Fechar")
                }
            }
        }
    }
}
