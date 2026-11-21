import SwiftUI

struct MatchesView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var selectedTab: MainTab
    @State private var selectedProfile: UserProfile?

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            if appState.matches.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "heart.circle")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(AppTheme.Colors.primaryRed.opacity(0.8))
                    Text("Seus matches aparecerão aqui")
                        .font(AppTheme.Typography.jakartaBold(18))
                        .foregroundStyle(AppTheme.Colors.darkGray)
                    Text("Quando você e outra pessoa curtirem um ao outro no Descobrir, o match será criado automaticamente.")
                        .font(AppTheme.Typography.jakartaRegular(14))
                        .foregroundStyle(AppTheme.Colors.textGray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 90)
                .padding(.horizontal, 32)
            } else {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(appState.matches) { match in
                        matchCard(match)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .refreshable {
            await appState.loadSocialData()
        }
        .sheet(item: $selectedProfile) { profile in
            ProfileDetailSheet(profile: profile)
        }
    }

    private func matchCard(_ match: MatchItem) -> some View {
        Button {
            selectedProfile = match.profile
        } label: {
            ZStack(alignment: .bottomLeading) {
                if let firstPhoto = match.profile.photos.first {
                    PhotoContentView(photo: firstPhoto)
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipped()
                }

                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.75)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Text("\(match.profile.firstName), \(match.profile.age)")
                            .font(AppTheme.Typography.headline())
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        if match.profile.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.white)
                        }

                        let partnerOnline = appState.onlineUsers[match.profile.id.uuidString.lowercased()] ?? match.profile.isOnline
                        if partnerOnline {
                            Circle()
                                .fill(Color(hex: "10B981"))
                                .frame(width: 8, height: 8)
                        }
                    }

                    Button {
                        selectedTab = .conversations
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left.fill")
                                .font(.system(size: 11))
                            Text("Conversar")
                                .font(AppTheme.Typography.micro())
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.Colors.primaryRed, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .strokeBorder(AppTheme.Colors.glassBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}
