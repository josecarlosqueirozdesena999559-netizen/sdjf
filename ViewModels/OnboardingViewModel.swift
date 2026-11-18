import Foundation
import SwiftUI
import PhotosUI

enum OnboardingStep: Int, CaseIterable {
    case fullName = 1
    case email = 2
    case username = 3
    case password = 4
    case ageConfirmation = 5
    case termsOfUse = 6
    case profilePhotos = 7
    case interests = 8
    case aboutYou = 9
    case permissions = 10
    case completion = 11

    static let visibleStepsCount = 10
}

enum UsernameAvailabilityState: Equatable {
    case idle
    case checking
    case available
    case unavailable
    case invalid(String)
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .fullName

    // MARK: - Step 1: Create Account
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var username: String = "" {
        didSet {
            handleUsernameChange()
        }
    }
    @Published var password: String = ""
    @Published var usernameState: UsernameAvailabilityState = .idle

    // MARK: - Step 2: Age Confirmation
    @Published var selectedDay: Int = 15
    @Published var selectedMonth: Int = 6
    @Published var selectedYear: Int = 2000
    @Published var ageErrorMessage: String?

    // MARK: - Step 3: Terms of Use
    @Published var acceptedTerms: Bool = false
    @Published var legalAcceptance: LegalAcceptance?

    // MARK: - Step 4: Profile Photos
    @Published var photos: [ProfilePhoto] = []
    @Published var selectedPickerItems: [PhotosPickerItem] = []

    // MARK: - Step 5: Interests & Preferences
    @Published var selectedInterests: [Interest] = []
    @Published var selectedGenderPreferences: [String] = ["todos"]

    // MARK: - Step 6: About You
    @Published var bio: String = "" {
        didSet {
            if bio.count > 300 {
                bio = String(bio.prefix(300))
            }
        }
    }

    // MARK: - Step 7: Permissions & Finalization
    @Published var permissions = PermissionPreferences()
    @Published var isSubmitting: Bool = false
    @Published var submissionError: String?

    private let services: ServiceContainer
    private let permissionService: PermissionService
    private var usernameCheckTask: Task<Void, Never>?

    init(services: ServiceContainer, permissionService: PermissionService) {
        self.services = services
        self.permissionService = permissionService
    }

    // MARK: - Step 1 Computed Validation
    var isFullNameValid: Bool {
        Validators.isValidFullName(fullName)
    }

    var isEmailValid: Bool {
        Validators.isValidEmail(email)
    }

    var passwordStrength: PasswordStrength {
        Validators.passwordStrength(password)
    }

    var isPasswordValid: Bool {
        Validators.isValidPassword(password)
    }

    var canAdvanceFromAccount: Bool {
        isFullNameValid && isEmailValid && usernameState == .available && isPasswordValid
    }

    private func handleUsernameChange() {
        usernameCheckTask?.cancel()
        let cleaned = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch Validators.validateUsernameFormat(cleaned) {
        case .empty:
            usernameState = .idle
            return
        case .invalid(let message):
            usernameState = .invalid(message)
            return
        case .valid:
            usernameState = .checking
        }

        usernameCheckTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            do {
                let isAvailable = try await services.authService.checkUsernameAvailability(cleaned)
                guard !Task.isCancelled else { return }
                usernameState = isAvailable ? .available : .unavailable
            } catch {
                guard !Task.isCancelled else { return }
                usernameState = .invalid("Não foi possível verificar agora.")
            }
        }
    }

    // MARK: - Step 2 Helpers & Validation
    var availableYears: [Int] {
        let currentYear = Calendar(identifier: .gregorian).component(.year, from: Date())
        return Array((1935...currentYear).reversed())
    }

    var maxDayForSelectedMonthYear: Int {
        DateAgeUtility.daysInMonth(selectedMonth, year: selectedYear)
    }

    func clampDayIfNeeded() {
        let maxDay = maxDayForSelectedMonthYear
        if selectedDay > maxDay {
            selectedDay = maxDay
        }
        ageErrorMessage = nil
    }

    func confirmAgeAndAdvance() {
        let check = DateAgeUtility.isAdult(day: selectedDay, month: selectedMonth, year: selectedYear)
        if !check.isValidDate {
            ageErrorMessage = "Selecione uma data de nascimento válida."
            return
        }
        if check.isFuture {
            ageErrorMessage = "A data de nascimento não pode estar no futuro."
            return
        }
        guard check.isAdult else {
            ageErrorMessage = "Este aplicativo é exclusivo para maiores de 18 anos. Você poderá retornar quando completar a maioridade."
            return
        }
        ageErrorMessage = nil
        goToNextStep()
    }

    // MARK: - Step 3
    func acceptTermsAndAdvance() {
        guard acceptedTerms else { return }
        legalAcceptance = LegalAcceptance(
            termsVersion: LegalContent.currentVersion,
            acceptedAt: Date()
        )
        goToNextStep()
    }

    // MARK: - Step 4: Photos
    var canAdvanceFromPhotos: Bool {
        !photos.isEmpty && photos.count <= 6
    }

    func loadPickedPhotos(_ items: [PhotosPickerItem]) async {
        let remainingSlots = max(0, 6 - photos.count)
        guard remainingSlots > 0 else {
            selectedPickerItems = []
            return
        }

        for item in items.prefix(remainingSlots) {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let photo = ProfilePhoto(imageData: data)
                photos.append(photo)
            }
        }
        selectedPickerItems = []
    }

    func removePhoto(at index: Int) {
        guard photos.indices.contains(index) else { return }
        photos.remove(at: index)
    }

    func setAsMainPhoto(at index: Int) {
        guard photos.indices.contains(index), index > 0 else { return }
        let item = photos.remove(at: index)
        photos.insert(item, at: 0)
    }

    func movePhotoLeft(at index: Int) {
        guard index > 0, photos.indices.contains(index) else { return }
        photos.swapAt(index, index - 1)
    }

    func movePhotoRight(at index: Int) {
        guard index < photos.count - 1, photos.indices.contains(index) else { return }
        photos.swapAt(index, index + 1)
    }

    // MARK: - Step 5: Interests
    var canAdvanceFromInterests: Bool {
        selectedInterests.count >= 3 && selectedInterests.count <= 10 && !selectedGenderPreferences.isEmpty
    }

    func toggleGenderPreference(_ optionId: String) {
        if optionId == "todos" {
            selectedGenderPreferences = ["todos"]
            return
        }
        selectedGenderPreferences.removeAll { $0 == "todos" }
        if let idx = selectedGenderPreferences.firstIndex(of: optionId) {
            selectedGenderPreferences.remove(at: idx)
        } else {
            selectedGenderPreferences.append(optionId)
        }
        if selectedGenderPreferences.isEmpty {
            selectedGenderPreferences = ["todos"]
        }
    }

    func toggleInterest(_ interest: Interest) {
        if let idx = selectedInterests.firstIndex(of: interest) {
            selectedInterests.remove(at: idx)
        } else if selectedInterests.count < 10 {
            selectedInterests.append(interest)
        }
    }

    // MARK: - Step 7: Permissions & Finish
    func requestLocationPermission() async {
        let granted = await permissionService.requestLocationWhenInUse()
        permissions.locationAuthorized = granted
        permissions.locationUpdatedAt = Date()
    }

    func requestNotificationsPermission() async {
        let granted = await permissionService.requestNotifications()
        permissions.notificationsAuthorized = granted
        permissions.notificationsUpdatedAt = Date()
    }

    func finishOnboarding(appState: AppState) async {
        isSubmitting = true
        submissionError = nil

        let birthDate = DateAgeUtility.makeDate(day: selectedDay, month: selectedMonth, year: selectedYear) ?? Date()
        let age = DateAgeUtility.calculateAge(from: birthDate) ?? 18
        let acceptance = legalAcceptance ?? LegalAcceptance(termsVersion: LegalContent.currentVersion, acceptedAt: Date())

        do {
            let userId = try await services.authService.registerAccount(
                fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                username: username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                password: password,
                birthDate: birthDate,
                legalAcceptance: acceptance
            )

            let uploadedPhotos = try await services.storageService.uploadProfilePhotos(photos, userId: userId)

            let profile = UserProfile(
                id: userId,
                fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                username: username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                birthDate: birthDate,
                age: age,
                photos: uploadedPhotos,
                interests: selectedInterests,
                lookingFor: selectedGenderPreferences,
                bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
                isVerified: false,
                isOnline: true,
                distanceKm: 0,
                city: "São Paulo",
                legalAcceptance: acceptance,
                permissions: permissions
            )

            try await services.userRepository.saveProfile(profile)
            if let coord = permissionService.lastCoordinate {
                struct LocationPayload: Encodable {
                    let latitude: Double
                    let longitude: Double
                }
                try? await APIClient.shared.requestVoid(
                    path: "/location",
                    method: "PUT",
                    body: LocationPayload(latitude: coord.latitude, longitude: coord.longitude)
                )
            }
            isSubmitting = false
            withAnimation(.easeInOut(duration: 0.25)) {
                currentStep = .completion
            }

            try? await Task.sleep(for: .seconds(1.8))
            await appState.completeOnboarding(with: profile)
        } catch {
            isSubmitting = false
            submissionError = "Não foi possível concluir o cadastro. Tente novamente."
        }
    }

    // MARK: - Navigation
    func goToNextStep() {
        guard let nextRaw = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentStep = nextRaw
        }
    }

    func goToPreviousStep() {
        guard let prevRaw = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentStep = prevRaw
        }
    }
}
