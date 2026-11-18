import SwiftUI
import UIKit

struct PhotoGalleryView: View {
    let photos: [ProfilePhoto]
    var enableSwipeGesture: Bool = true
    var autoAdvance: Bool = false
    @State private var currentIndex: Int = 0
    private let autoTimer = Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                if photos.isEmpty {
                    emptyPlaceholder
                } else {
                    let safeIndex = min(max(0, currentIndex), photos.count - 1)
                    PhotoContentView(photo: photos[safeIndex])
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .id(photos[safeIndex].id)
                        .transition(.opacity.animation(.easeInOut(duration: 0.22)))

                    // Tap zones: left = previous, right = next
                    HStack(spacing: 0) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                goToPrevious()
                            }
                            .accessibilityLabel("Foto anterior")

                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                goToNext()
                            }
                            .accessibilityLabel("Próxima foto")
                    }

                    if photos.count > 1 {
                        PhotoProgressBars(totalCount: photos.count, currentIndex: safeIndex)
                            .padding(.top, 12)
                            .padding(.horizontal, 14)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                enableSwipeGesture && photos.count > 1
                ? DragGesture(minimumDistance: 24)
                    .onEnded { value in
                        if value.translation.width < -35 {
                            goToNext()
                        } else if value.translation.width > 35 {
                            goToPrevious()
                        }
                    }
                : nil
            )
            .onChange(of: photos.count) { _, newCount in
                if currentIndex >= newCount {
                    currentIndex = max(0, newCount - 1)
                }
            }
            .onReceive(autoTimer) { _ in
                guard autoAdvance, photos.count > 1 else { return }
                goToNext()
            }
        }
    }

    private var emptyPlaceholder: some View {
        ZStack {
            AppTheme.Colors.chipUnselected
            VStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textGray)
                Text("Sem fotos")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.textGray)
            }
        }
    }

    private func goToNext() {
        guard photos.count > 1 else { return }
        withAnimation(.easeInOut(duration: 0.22)) {
            if currentIndex < photos.count - 1 {
                currentIndex += 1
            } else {
                currentIndex = 0
            }
        }
    }

    private func goToPrevious() {
        guard photos.count > 1 else { return }
        withAnimation(.easeInOut(duration: 0.22)) {
            if currentIndex > 0 {
                currentIndex -= 1
            } else {
                currentIndex = photos.count - 1
            }
        }
    }
}

struct PhotoProgressBars: View {
    let totalCount: Int
    let currentIndex: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<totalCount, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.38))
                    .frame(height: 3.5)
                    .shadow(color: Color.black.opacity(0.22), radius: 2, x: 0, y: 1)
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }
        }
    }
}

struct PhotoContentView: View {
    let photo: ProfilePhoto

    var body: some View {
        if let data = photo.imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else if let remote = photo.remoteURL, let url = URL(string: remote) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    demoPlaceholder
                @unknown default:
                    demoPlaceholder
                }
            }
        } else {
            demoPlaceholder
        }
    }

    private var demoPlaceholder: some View {
        let colors = (photo.placeholderPaletteHexes ?? ["292932", "494957"]).map { Color(hex: $0) }
        return ZStack {
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 12) {
                Image(systemName: photo.placeholderSymbol ?? "person.fill")
                    .font(.system(size: 54, weight: .light))
                    .foregroundStyle(Color.white.opacity(0.78))
                if let caption = photo.placeholderCaption {
                    Text(caption)
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(Color.white.opacity(0.75))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
        }
    }
}
