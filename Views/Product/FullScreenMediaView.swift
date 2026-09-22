import SwiftUI
import AVKit

struct FullScreenMediaView: View {
    let mediaUrls: [String]
    @State var currentIndex: Int
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                TabView(selection: $currentIndex) {
                    ForEach(0..<mediaUrls.count, id: \.self) { index in
                        let urlString = mediaUrls[index]
                        if let url = URL(string: urlString) {
                            if isVideo(url: urlString) {
                                VideoPlayer(player: AVPlayer(url: url))
                                    .edgesIgnoringSafeArea(.all)
                                    .tag(index)
                            } else {
                                ZoomableImageView(url: url)
                                    .tag(index)
                            }
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.custom("Inter-Bold", size: 22, relativeTo: .title2))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
            }
            .toolbarBackground(Color.black.opacity(0.6), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    private func isVideo(url: String) -> Bool {
        let lowercased = url.lowercased()
        return lowercased.hasSuffix(".mp4") || lowercased.hasSuffix(".mov") || lowercased.hasSuffix(".m3u8") || lowercased.contains("video")
    }
}

struct ZoomableImageView: View {
    let url: URL
    @State private var currentScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0
    @State private var currentOffset = CGSize.zero
    @State private var finalOffset = CGSize.zero
    
    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(currentScale * finalScale)
                    .offset(x: currentOffset.width + finalOffset.width, y: currentOffset.height + finalOffset.height)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { scale in
                                currentScale = scale
                            }
                            .onEnded { scale in
                                finalScale *= scale
                                currentScale = 1.0
                                if finalScale < 1.0 {
                                    withAnimation(.spring()) {
                                        finalScale = 1.0
                                        finalOffset = .zero
                                    }
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                if finalScale > 1.0 {
                                    currentOffset = value.translation
                                }
                            }
                            .onEnded { value in
                                if finalScale > 1.0 {
                                    finalOffset.width += currentOffset.width
                                    finalOffset.height += currentOffset.height
                                    currentOffset = .zero
                                }
                            }
                    )
            } else if phase.error != nil {
                Image(systemName: "photo")
                    .font(.custom("Inter-Regular", size: 50))
                    .foregroundColor(.gray)
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}
