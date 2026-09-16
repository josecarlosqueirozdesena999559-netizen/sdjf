import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct SelectedMedia: Identifiable {
    let id = UUID()
    let image: UIImage
    let isVideo: Bool
}

struct PublishProductView: View {
    @StateObject private var viewModel = PublishViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedMedia: [SelectedMedia] = []
    @State private var isLoadingMedia: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // MEDIA SECTION
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fotos e Vídeos")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .any(of: [.images, .videos])) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "camera.badge.ellipsis")
                                            .font(.system(size: 28))
                                        Text("Adicionar")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                    }
                                    .frame(width: 100, height: 100)
                                    .background(Theme.primary.opacity(0.1))
                                    .foregroundColor(Theme.primary)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Theme.primary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                                    )
                                }
                                
                                if isLoadingMedia {
                                    ProgressView()
                                        .frame(width: 100, height: 100)
                                        .background(Theme.inputBackground)
                                        .cornerRadius(12)
                                }
                                
                                ForEach(selectedMedia) { media in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: media.image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        
                                        if media.isVideo {
                                            Color.black.opacity(0.3)
                                                .frame(width: 100, height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            Image(systemName: "play.circle.fill")
                                                .font(.largeTitle)
                                                .foregroundColor(.white)
                                                .position(x: 50, y: 50)
                                        }
                                        
                                        Button(action: {
                                            if let index = selectedMedia.firstIndex(where: { $0.id == media.id }) {
                                                selectedMedia.remove(at: index)
                                                if index < selectedItems.count {
                                                    selectedItems.remove(at: index)
                                                }
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .background(Circle().fill(Color.black.opacity(0.6)))
                                        }
                                        .padding(6)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 16)
                    
                    // PRICE SECTION
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preço do Produto")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                        
                        HStack {
                            Text("R$")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.textSecondary)
                            TextField("0,00", text: $viewModel.price)
                                .font(.system(size: 36, weight: .bold))
                                .keyboardType(.decimalPad)
                                .foregroundColor(Theme.textPrimary)
                        }
                        .padding()
                        .background(Theme.inputBackground)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // MAIN INFO SECTION
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Título")
                                .font(.headline)
                            TextField("Ex: iPhone 13 128GB impecável", text: $viewModel.title)
                                .padding()
                                .background(Theme.inputBackground)
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Descrição")
                                .font(.headline)
                            TextEditor(text: $viewModel.description)
                                .frame(height: 120)
                                .padding(8)
                                .background(Theme.inputBackground)
                                .cornerRadius(12)
                        }
                        
                        // Condition Pills
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Estado de conservação")
                                .font(.headline)
                            HStack {
                                ForEach(ProductCondition.allCases, id: \.self) { condition in
                                    Button(action: { viewModel.selectedCondition = condition }) {
                                        Text(condition.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .padding(.vertical, 10)
                                            .frame(maxWidth: .infinity)
                                            .background(viewModel.selectedCondition == condition ? Theme.primary : Theme.inputBackground)
                                            .foregroundColor(viewModel.selectedCondition == condition ? .white : Theme.textPrimary)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                        
                        // Category Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Categoria")
                                .font(.headline)
                            Menu {
                                ForEach(MockData.categories) { cat in
                                    Button(action: { viewModel.selectedCategoryId = cat.id }) {
                                        Text(cat.name)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.selectedCategoryId != nil ? MockData.categories.first(where: { $0.id == viewModel.selectedCategoryId })?.name ?? "Selecione" : "Selecione a categoria")
                                        .foregroundColor(viewModel.selectedCategoryId != nil ? Theme.textPrimary : Theme.textSecondary)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .padding()
                                .background(Theme.inputBackground)
                                .cornerRadius(12)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Localização")
                                .font(.headline)
                            TextField("Ex: São Paulo - SP", text: $viewModel.location)
                                .padding()
                                .background(Theme.inputBackground)
                                .cornerRadius(12)
                        }
                        
                        Toggle("Aceita negociação?", isOn: $viewModel.acceptsNegotiation)
                            .font(.headline)
                            .padding(.vertical, 8)
                            .tint(Theme.primary)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color.white)
            .navigationTitle("Anunciar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(Theme.primary)
                }
            }
            // FLOATING ACTION BUTTON
            .safeAreaInset(edge: .bottom) {
                Button(action: { viewModel.publish() }) {
                    HStack {
                        if viewModel.isPublishing {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Publicar Anúncio")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isFormValid ? Theme.primary : Theme.textSecondary.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .disabled(!viewModel.isFormValid || viewModel.isPublishing)
            }
            .onChange(of: selectedItems) { newItems in
                loadMedia(from: newItems)
            }
            .alert("Sucesso", isPresented: $viewModel.publishSuccess) {
                Button("Ver meus anúncios", role: .cancel) { dismiss() }
            } message: {
                Text("Seu anúncio foi publicado com sucesso e já está visível para os compradores!")
            }
        }
    }
    
    private func loadMedia(from items: [PhotosPickerItem]) {
        Task {
            isLoadingMedia = true
            var loadedMedia: [SelectedMedia] = []
            
            for item in items {
                var isVideo = false
                
                // For video fallback/mock, since actual video extraction is complex,
                // we check if it is a video type and provide a dummy image or try to load.
                if item.supportedContentTypes.contains(UTType.movie) ||
                   item.supportedContentTypes.contains(UTType.video) ||
                   item.supportedContentTypes.contains(UTType.mpeg4Movie) ||
                   item.supportedContentTypes.contains(UTType.quickTimeMovie) {
                    isVideo = true
                    // Provide a generic video thumbnail mock (just a gray square for now, overlaid with play button)
                    if let dummy = createDummyVideoThumbnail() {
                        loadedMedia.append(SelectedMedia(image: dummy, isVideo: true))
                    }
                    continue
                }
                
                // Load image
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    loadedMedia.append(SelectedMedia(image: image, isVideo: false))
                }
            }
            
            DispatchQueue.main.async {
                self.selectedMedia = loadedMedia
                self.isLoadingMedia = false
            }
        }
    }
    
    private func createDummyVideoThumbnail() -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.darkGray.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
