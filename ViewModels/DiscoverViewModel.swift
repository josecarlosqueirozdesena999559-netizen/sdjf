import Foundation
import SwiftUI

@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published var candidates: [UserProfile] = []
    @Published var filter = DiscoveryFilter()
    @Published var isLoading: Bool = false
    @Published var matchedProfile: UserProfile?
    @Published var selectedProfileForDetail: UserProfile?

    private let discoveryService: DiscoveryServiceProtocol

    init(discoveryService: DiscoveryServiceProtocol) {
        self.discoveryService = discoveryService
    }

    func loadCandidates() async {
        isLoading = true
        do {
            candidates = try await discoveryService.fetchCandidates(filter: filter)
        } catch {
            candidates = []
        }
        isLoading = false
    }

    func handleDecision(_ decision: SwipeDecision, for profile: UserProfile, appState: AppState) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
            candidates.removeAll { $0.id == profile.id }
        }

        Task {
            let isMatch = (try? await discoveryService.submitDecision(decision, targetUserId: profile.id)) ?? false
            if isMatch {
                appState.registerMatch(with: profile, isHighlighted: decision == .highlight)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    matchedProfile = profile
                }
            }
        }
    }

    func actOnTopCard(_ decision: SwipeDecision, appState: AppState) {
        guard let top = candidates.first else { return }
        handleDecision(decision, for: top, appState: appState)
    }

    func applyFilter(_ newFilter: DiscoveryFilter) {
        filter = newFilter
        Task {
            await loadCandidates()
        }
    }
}
