import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: OnboardingViewModel

    init(services: ServiceContainer, permissionService: PermissionService) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(
            services: services,
            permissionService: permissionService
        ))
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.currentStep != .completion {
                    OnboardingProgressHeader(
                        currentStep: viewModel.currentStep.rawValue,
                        totalSteps: OnboardingStep.visibleStepsCount,
                        canGoBack: viewModel.currentStep != .createAccount,
                        onBack: { viewModel.goToPreviousStep() }
                    )
                }

                Group {
                    switch viewModel.currentStep {
                    case .createAccount:
                        CreateAccountView(viewModel: viewModel)
                    case .ageConfirmation:
                        AgeConfirmationView(viewModel: viewModel)
                    case .termsOfUse:
                        TermsOfUseView(viewModel: viewModel)
                    case .profilePhotos:
                        ProfilePhotosView(viewModel: viewModel)
                    case .interests:
                        InterestsSelectionView(viewModel: viewModel)
                    case .aboutYou:
                        AboutYouView(viewModel: viewModel)
                    case .permissions:
                        PermissionsView(viewModel: viewModel)
                    case .completion:
                        OnboardingCompletionView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
    }
}
