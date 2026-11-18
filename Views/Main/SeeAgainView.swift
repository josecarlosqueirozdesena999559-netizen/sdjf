import SwiftUI

struct SeeAgainView: View {
    @EnvironmentObject private var appState: AppState
    let onMatch: (UserProfile) -> Void
    let onMessageSent: () -> Void

    @State private var candidates: [UserProfile] = []
    @State private var isLoading = true
    @State private var selectedProfileForDetail: UserProfile?
    @State private var directMessageTarget: UserProfile?

    private struct SkippedResponse: Decodable {
        let items: [BackendCandidateDTO]
    }

    private struct LikeBody: Encodable {
        let targetUserId: String
        let type: String
    }

    private struct LikeResp: Decodable {
        let matched: Bool?
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(AppTheme.Colors.primaryRed)
                } else if candidates.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(AppTheme.Colors.primaryRed)

                        Text("Nenhum perfil pulado por enquanto")
                            .font(AppTheme.Typography.headline())
                            .foregroundStyle(AppTheme.Colors.darkGray)

                        Button {
                            Task { await loadSkipped() }
                        } label: {
                            Text("Atualizar")
                                .font(AppTheme.Typography.subheadline())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(AppTheme.Colors.primaryRed, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .glassCard(cornerRadius: AppTheme.Radius.card)
                } else if let top = candidates.first {
                    SwipeableProfileCard(
                        profile: top,
                        isTopCard: true,
                        programmaticSwipe: nil,
                        onDecision: { decision in
                            Task { await decide(decision, for: top) }
                        },
                        onInfoTap: {
                            selectedProfileForDetail = top
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 18)

            HStack(spacing: 24) {
                Button {
                    if let top = candidates.first {
                        Task { await decide(.pass, for: top) }
                    }
                } label: {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 58, height: 58)
                        .shadow(color: Color.black.opacity(0.09), radius: 10, x: 0, y: 5)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color(hex: "3D4048"))
                        )
                }
                .buttonStyle(.plain)
                .disabled(candidates.isEmpty)

                Button {
                    if let top = candidates.first {
                        Task { await decide(.like, for: top) }
                    }
                } label: {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.secondaryRed, AppTheme.Colors.primaryRed],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(color: AppTheme.Colors.primaryRed.opacity(0.32), radius: 14, x: 0, y: 6)
                        .overlay(
                            Image(systemName: "heart.fill")
                                .font(.system(size: 27, weight: .bold))
                                .foregroundStyle(.white)
                        )
                }
                .buttonStyle(.plain)
                .disabled(candidates.isEmpty)

                Button {
                    if let top = candidates.first {
                        directMessageTarget = top
                    }
                } label: {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 58, height: 58)
                        .shadow(color: Color.black.opacity(0.09), radius: 10, x: 0, y: 5)
                        .overlay(
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.primaryRed)
                        )
                }
                .buttonStyle(.plain)
                .disabled(candidates.isEmpty)
            }
            .padding(.bottom, 6)
            .opacity(candidates.isEmpty ? 0.45 : 1.0)
        }
        .task {
            await loadSkipped()
        }
        .sheet(item: $selectedProfileForDetail) { profile in
            ProfileDetailSheet(profile: profile) { target in
                selectedProfileForDetail = nil
                directMessageTarget = target
            }
        }
        .sheet(item: $directMessageTarget) { target in
            QuickDirectMessageSheet(profile: target) {
                candidates.removeAll { $0.id == target.id }
                onMessageSent()
            }
        }
    }

    private func loadSkipped() async {
        isLoading = true
        if let res: SkippedResponse = try? await APIClient.shared.request(path: "/discovery/skipped", method: "GET") {
            candidates = res.items.map { $0.toDomain() }.shuffled()
        }
        isLoading = false
    }

    private func decide(_ decision: SwipeDecision, for profile: UserProfile) async {
        candidates.removeAll { $0.id == profile.id }
        let type = decision == .like ? "LIKE" : "PASS"
        if let res: LikeResp = try? await APIClient.shared.request(
            path: "/likes",
            method: "POST",
            body: LikeBody(targetUserId: profile.id.uuidString.lowercased(), type: type)
        ), res.matched == true {
            onMatch(profile)
        }
    }
}
