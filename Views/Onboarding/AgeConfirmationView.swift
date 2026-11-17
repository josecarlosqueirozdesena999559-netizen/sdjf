import SwiftUI

struct AgeConfirmationView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let monthNames = [
        (1, "Jan"), (2, "Fev"), (3, "Mar"), (4, "Abr"),
        (5, "Mai"), (6, "Jun"), (7, "Jul"), (8, "Ago"),
        (9, "Set"), (10, "Out"), (11, "Nov"), (12, "Dez")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Antes de continuar...")
                    .font(AppTheme.Typography.largeTitle())
                    .foregroundStyle(AppTheme.Colors.darkGray)

                Text("Precisamos confirmar que você tem 18 anos ou mais.")
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(AppTheme.Colors.textGray)
            }
            .padding(.top, 12)

            VStack(spacing: 14) {
                HStack {
                    Text("Dia")
                        .frame(maxWidth: .infinity)
                    Text("Mês")
                        .frame(maxWidth: .infinity)
                    Text("Ano")
                        .frame(maxWidth: .infinity)
                }
                .font(AppTheme.Typography.caption())
                .foregroundStyle(AppTheme.Colors.textGray)

                HStack(spacing: 0) {
                    Picker("Dia", selection: $viewModel.selectedDay) {
                        ForEach(1...viewModel.maxDayForSelectedMonthYear, id: \.self) { day in
                            Text(String(format: "%02d", day)).tag(day)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Picker("Mês", selection: $viewModel.selectedMonth) {
                        ForEach(monthNames, id: \.0) { month in
                            Text(month.1).tag(month.0)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Picker("Ano", selection: $viewModel.selectedYear) {
                        ForEach(viewModel.availableYears, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 190)
                .onChange(of: viewModel.selectedMonth) { _, _ in
                    viewModel.clampDayIfNeeded()
                }
                .onChange(of: viewModel.selectedYear) { _, _ in
                    viewModel.clampDayIfNeeded()
                }
                .onChange(of: viewModel.selectedDay) { _, _ in
                    viewModel.ageErrorMessage = nil
                }
            }
            .padding(16)
            .background(AppTheme.Colors.white, in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
            )

            if let errorMessage = viewModel.ageErrorMessage {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.Colors.primaryRed)
                    Text(errorMessage)
                        .font(AppTheme.Typography.subheadline())
                        .foregroundStyle(AppTheme.Colors.darkGray)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                        .fill(AppTheme.Colors.primaryRed.opacity(0.08))
                )
            }

            Spacer()

            PrimaryButton(title: "Confirmar idade") {
                viewModel.confirmAgeAndAdvance()
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
}
