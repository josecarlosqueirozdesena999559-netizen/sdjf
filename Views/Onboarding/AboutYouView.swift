import SwiftUI

struct AboutYouView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isBioFocused: Bool

    private let placeholder = "Sou uma pessoa que gosta de conhecer lugares novos, ouvir música e aproveitar bons momentos..."

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Conte um pouco sobre você.")
                    .font(AppTheme.Typography.largeTitle())
                    .foregroundStyle(AppTheme.Colors.darkGray)

                Text("Uma pequena descrição pode fazer toda a diferença.")
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(AppTheme.Colors.textGray)
            }
            .padding(.top, 12)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.bio)
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(AppTheme.Colors.darkGray)
                    .scrollContentBackground(.hidden)
                    .focused($isBioFocused)
                    .padding(12)

                if viewModel.bio.isEmpty {
                    Text(placeholder)
                        .font(AppTheme.Typography.body())
                        .foregroundStyle(AppTheme.Colors.textGray.opacity(0.75))
                        .padding(.horizontal, 17)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 190)
            .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .strokeBorder(isBioFocused ? AppTheme.Colors.primaryRed.opacity(0.5) : AppTheme.Colors.borderSubtle, lineWidth: 1)
            )

            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.Colors.primaryRed)
                    Text(viewModel.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                         ? "Opcional, mas perfis com descrição recebem mais atenção."
                         : "Ótima descrição!")
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.textGray)
                }

                Spacer()

                Text("\(viewModel.bio.count)/300")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(viewModel.bio.count >= 280 ? AppTheme.Colors.primaryRed : AppTheme.Colors.textGray)
            }

            Spacer()

            PrimaryButton(title: viewModel.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Pular por enquanto" : "Continuar") {
                isBioFocused = false
                viewModel.goToNextStep()
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
}
