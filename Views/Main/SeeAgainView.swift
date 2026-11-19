import SwiftUI

struct SeeAgainView: View {
    @EnvironmentObject private var appState: AppState
    let onMatch: (UserProfile) -> Void
    let onMessageSent: () -> Void

    @State private var candidates: [UserProfile] = []
    @State private var isLoading = true
    @State private var selectedProfileForDetail: UserProfile?
    @State private var directMessageTarget: UserProfile?

    private struct SkippedPhotoDTO: Decodable {
        let id: String
        let url: String
        let thumbnailUrl: String?
    }

    private struct SkippedInterestDTO: Decodable {
        let id: String
        let name: String
        let icon: String?
    }

    private struct SkippedCandidateDTO: Decodable {
        let id: String
        let fullName: String
        let username: String
        let age: Int
        let bio: String
        let approximateLocation: String
        let distanceKm: Int
        let isOnline: Bool
        let isVerified: Bool
        let photos: [SkippedPhotoDTO]
        let interests: [SkippedInterestDTO]

        func toDomain() -> UserProfile {
            UserProfile(
                id: UUID(uuidString: id) ?? UUID(),
                fullName: fullName,
                username: username,
                age: age,
                photos: photos.map {
                    ProfilePhoto(
                        id: UUID(uuidString: $0.id) ?? UUID(),
                        remoteURL: $0.url
                    )
                },
                interests: interests.map {
                    Interest(
                        id: $0.id,
                        name: $0.name,
                        icon: $0.icon ?? "sparkles"
                    )
                },
                bio: bio,
                isVerified: isVerified,
                isOnline: isOnline,
                distanceKm: distanceKm,
                city: approximateLocation
            )
        }
    }

    private struct SkippedResponse: Decodable {
        let items: [SkippedCandidateDTO]
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

            HStack(spacing: 26) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if let top = candidates.first {
                        Task { await decide(.reject, for: top) }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.white)
                        Circle()
                            .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1.5)
                        Image(systemName: "xmark")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(AppTheme.Colors.darkGray)
                    }
                    .frame(width: 62, height: 62)
                    .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .disabled(candidates.isEmpty)

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if let top = candidates.first {
                        Task { await decide(.like, for: top) }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.Colors.primaryRed, AppTheme.Colors.secondaryRed],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Circle()
                            .strokeBorder(Color.white.opacity(0.35), lineWidth: 2)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 76, height: 76)
                    .shadow(color: AppTheme.Colors.primaryRed.opacity(0.40), radius: 16, x: 0, y: 8)
                }
                .buttonStyle(.plain)
                .disabled(candidates.isEmpty)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if let top = candidates.first {
                        directMessageTarget = top
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.white)
                        Circle()
                            .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1.5)
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.primaryRed)
                    }
                    .frame(width: 62, height: 62)
                    .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 6)
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
