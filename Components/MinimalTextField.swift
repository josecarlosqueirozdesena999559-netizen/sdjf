import SwiftUI

struct MinimalTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false
    @State private var revealPassword: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AppTheme.Typography.caption())
                .foregroundStyle(AppTheme.Colors.textGray)

            HStack(spacing: 10) {
                Group {
                    if isSecure && !revealPassword {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(AppTheme.Typography.body())
                .foregroundStyle(AppTheme.Colors.darkGray)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(isSecure || keyboardType == .emailAddress || autocapitalization == .never)

                if isSecure {
                    Button {
                        revealPassword.toggle()
                    } label: {
                        Image(systemName: revealPassword ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(AppTheme.Colors.textGray)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(revealPassword ? "Ocultar senha" : "Visualizar senha")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                    .fill(AppTheme.Colors.inputBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                    .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
            )
        }
    }
}

struct OnboardingProgressHeader: View {
    let currentStep: Int
    let totalSteps: Int
    var canGoBack: Bool = true
    var onBack: () -> Void

    private var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStep) / Double(totalSteps)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                if canGoBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.darkGray)
                            .frame(width: 38, height: 38)
                            .background(AppTheme.Colors.white, in: Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Voltar")
                } else {
                    Color.clear.frame(width: 38, height: 38)
                }

                Spacer()

                Text("Etapa \(currentStep) de \(totalSteps)")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.textGray)

                Spacer()

                Color.clear.frame(width: 38, height: 38)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.Colors.chipUnselected)
                        .frame(height: 5)

                    Capsule()
                        .fill(AppTheme.Colors.primaryRed)
                        .frame(width: max(12, geo.size.width * progress), height: 5)
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: progress)
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.top, 8)
    }
}
