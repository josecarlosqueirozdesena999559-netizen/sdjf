import SwiftUI
import PhotosUI
import Supabase

struct StoriesRowView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var viewModel: HomeViewModel
    
    @State private var selectedStoryUser: Profile? = nil
    @State private var showStoryViewer = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isUploading = false
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // My Story / Add Story
                VStack {
                    ZStack(alignment: .bottomTrailing) {
                        if let user = authViewModel.currentUser {
                            if !viewModel.myStories.isEmpty {
                                // Has active story
                                Button(action: {
                                    selectedStoryUser = Profile(id: user.id, name: user.name, visible_name: user.visibleName, username: user.username, email: user.email, document: nil, location: user.location, avatar_url: user.avatarURL, created_at: nil, rating: nil, avg_response_time: nil, bio: nil, latitude: nil, longitude: nil, is_online: nil, last_seen: nil)
                                    showStoryViewer = true
                                }) {
                                    AsyncImage(url: URL(string: user.avatarURL ?? "")) { phase in
                                        if let image = phase.image {
                                            image.resizable().scaledToFill()
                                        } else {
                                            Image(systemName: "person.crop.circle.fill").resizable().foregroundColor(.gray)
                                        }
                                    }
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Theme.primary, lineWidth: 2))
                                    .padding(2)
                                }
                            } else {
                                // No active story -> show avatar with "+"
                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    AsyncImage(url: URL(string: user.avatarURL ?? "")) { phase in
                                        if let image = phase.image {
                                            image.resizable().scaledToFill()
                                        } else {
                                            Image(systemName: "person.crop.circle.fill").resizable().foregroundColor(.gray)
                                        }
                                    }
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                                    .overlay(
                                        ZStack {
                                            Circle().fill(Theme.primary)
                                            Image(systemName: "plus").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                                        }
                                        .frame(width: 20, height: 20)
                                        .offset(x: 4, y: 4)
                                    , alignment: .bottomTrailing)
                                }
                            }
                        }
                        
                        if isUploading {
                            ProgressView()
                                .frame(width: 60, height: 60)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                    }
                    Text("Seu Story")
                        .typographyCaption()
                        .foregroundColor(Theme.textSecondary)
                }
                
                // Followed users stories
                ForEach(viewModel.followedUsersWithStories, id: \.id) { profile in
                    Button(action: {
                        selectedStoryUser = profile
                        showStoryViewer = true
                    }) {
                        VStack {
                            AsyncImage(url: URL(string: profile.avatar_url ?? "")) { phase in
                                if let image = phase.image {
                                    image.resizable().scaledToFill()
                                } else {
                                    Image(systemName: "person.crop.circle.fill").resizable().foregroundColor(.gray)
                                }
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Theme.primary, lineWidth: 2))
                            .padding(2)
                            
                            Text(profile.visible_name ?? profile.name)
                                .typographyCaption()
                                .foregroundColor(Theme.textPrimary)
                                .lineLimit(1)
                                .frame(width: 70)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .fullScreenCover(isPresented: $showStoryViewer) {
            if let profile = selectedStoryUser {
                let stories = profile.id == authViewModel.currentUser?.id ? viewModel.myStories : (viewModel.storiesByUser[profile.id] ?? [])
                StoryViewer(profile: profile, stories: stories, onDismiss: { showStoryViewer = false })
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem = newItem else { return }
            Task {
                await uploadStory(item: newItem)
            }
        }
    }
    
    private func uploadStory(item: PhotosPickerItem) async {
        isUploading = true
        defer { isUploading = false; selectedItem = nil }
        guard let user = authViewModel.currentUser else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.7) {
                let path = "\(user.id.uuidString)/\(UUID().uuidString).jpg"
                try await supabase.storage.from("stories").upload(path: path, file: jpeg, options: FileOptions(contentType: "image/jpeg"))
                
                let publicUrl = try supabase.storage.from("stories").getPublicURL(path: path).absoluteString
                
                struct InsertStory: Codable {
                    let user_id: UUID
                    let media_url: String
                    let media_type: String
                }
                
                try await supabase.database.from("stories").insert(InsertStory(user_id: user.id, media_url: publicUrl, media_type: "image")).execute()
                
                // Refresh
                viewModel.fetchStories(currentUserId: user.id)
            }
        } catch {
            print("Upload story error: \(error)")
        }
    }
}
