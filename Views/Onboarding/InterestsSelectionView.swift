import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxWidth, height: currentY + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(size)
            )
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct InterestsSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Interesses")
                .font(AppTheme.Typography.largeTitle())
                .foregroundStyle(AppTheme.Colors.darkGray)
                .padding(.top, 12)

            HStack {
                Text("Selecionados: \(viewModel.selectedInterests.count)/10")
                    .font(AppTheme.Typography.subheadline())
                    .foregroundStyle(viewModel.canAdvanceFromInterests ? AppTheme.Colors.primaryRed : AppTheme.Colors.textGray)

                Spacer()

                Text("Mínimo 3")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.textGray)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quem você gostaria de conhecer?")
                            .font(AppTheme.Typography.headline())
                            .foregroundStyle(AppTheme.Colors.darkGray)

                        FlowLayout(spacing: 10) {
                            ForEach(GenderInterestOption.all) { option in
                                let isSelected = viewModel.selectedGenderPreferences.contains(option.id)
                                Button {
                                    viewModel.toggleGenderPreference(option.id)
                                } label: {
                                    HStack(spacing: 7) {
                                        Image(systemName: option.sfSymbol)
                                            .font(.system(size: 13, weight: .semibold))
                                        Text(option.title)
                                            .font(AppTheme.Typography.subheadline())
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .foregroundStyle(isSelected ? AppTheme.Colors.white : AppTheme.Colors.darkGray)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.Radius.pill, style: .continuous)
                                            .fill(isSelected ? AppTheme.Colors.primaryRed : AppTheme.Colors.chipUnselected)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.Radius.pill, style: .continuous)
                                            .strokeBorder(
                                                isSelected ? AppTheme.Colors.primaryRed : AppTheme.Colors.borderSubtle,
                                                lineWidth: 1
                                            )
                                    )
                                    .animation(.easeInOut(duration: 0.18), value: isSelected)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Hobbies e afinidades")
                            .font(AppTheme.Typography.headline())
                            .foregroundStyle(AppTheme.Colors.darkGray)

                        FlowLayout(spacing: 10) {
                            ForEach(Interest.all) { interest in
                                let isSelected = viewModel.selectedInterests.contains(interest)
                                InterestChip(interest: interest, isSelected: isSelected) {
                                    viewModel.toggleInterest(interest)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }

            PrimaryButton(
                title: "Continuar",
                isEnabled: viewModel.canAdvanceFromInterests
            ) {
                viewModel.goToNextStep()
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
}
