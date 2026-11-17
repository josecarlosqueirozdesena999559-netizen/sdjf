import SwiftUI

struct SwipeableProfileCard: View {
    let profile: UserProfile
    var isTopCard: Bool = true
    var onDecision: (SwipeDecision) -> Void
    var onInfoTap: () -> Void

    @State private var offset: CGSize = .zero

    private let swipeThreshold: CGFloat = 115

    private var likeOpacity: Double {
        min(max(Double(offset.width / swipeThreshold), 0), 1)
    }

    private var rejectOpacity: Double {
        min(max(Double(-offset.width / swipeThreshold), 0), 1)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            PhotoGalleryView(photos: profile.photos, enableSwipeGesture: false)

            // Bottom readability scrim
            LinearGradient(
                colors: [
                    Color.black.opacity(0.0),
                    Color.black.opacity(0.35),
                    Color.black.opacity(0.78)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            // Swipe feedback stamps
            VStack {
                HStack {
                    if likeOpacity > 0.08 {
                        Text("CURTIR")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(AppTheme.Colors.primaryRed.opacity(0.9), in: Capsule())
                            .opacity(likeOpacity)
                    }
                    Spacer()
                    if rejectOpacity > 0.08 {
                        Text("PASSAR")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(AppTheme.Colors.darkGray.opacity(0.85), in: Capsule())
                            .opacity(rejectOpacity)
                    }
                }
                .padding(.top, 28)
                .padding(.horizontal, 18)
                Spacer()
            }
            .allowsHitTesting(false)

            // Overlaid profile metadata
            VStack(alignment: .leading, spacing: 10) {
                if profile.isOnline {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Online agora")
                            .font(AppTheme.Typography.micro())
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .glassPill()
                }

                HStack(alignment: .center, spacing: 8) {
                    Text("\(profile.firstName), \(profile.age)")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundStyle(.white)

                    if profile.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(AppTheme.Colors.white)
                            .accessibilityLabel("Perfil verificado")
                    }

                    Spacer()

                    Button(action: onInfoTap) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Ver informações adicionais")
                }

                HStack(spacing: 5) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("A cerca de \(profile.distanceKm) km • \(profile.city)")
                        .font(AppTheme.Typography.subheadline())
                }
                .foregroundStyle(Color.white.opacity(0.92))

                if !profile.interests.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(profile.interests.prefix(4)) { interest in
                                GlassInterestChip(interest: interest)
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.14), radius: 18, x: 0, y: 10)
        .offset(x: offset.width, y: offset.height * 0.25)
        .rotationEffect(.degrees(Double(offset.width / 22)))
        .gesture(
            isTopCard
            ? DragGesture(minimumDistance: 12)
                .onChanged { gesture in
                    offset = gesture.translation
                }
                .onEnded { gesture in
                    if gesture.translation.width > swipeThreshold {
                        completeSwipe(direction: 1, decision: .like)
                    } else if gesture.translation.width < -swipeThreshold {
                        completeSwipe(direction: -1, decision: .reject)
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                            offset = .zero
                        }
                    }
                }
            : nil
        )
    }

    private func completeSwipe(direction: CGFloat, decision: SwipeDecision) {
        withAnimation(.easeOut(duration: 0.22)) {
            offset = CGSize(width: direction * 520, height: 40)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            onDecision(decision)
            offset = .zero
        }
    }
}
