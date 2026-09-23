import SwiftUI
import PhotosUI
import UniformTypeIdentifiers



struct EditProductView: View {
    @StateObject private var viewModel: EditProductViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    init(product: Product) {
        _viewModel = StateObject(wrappedValue: EditProductViewModel(product: product))
    }
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedMedia: [SelectedMedia] = []
    @State private var isLoadingMedia: Bool = false
    
    var onPublishSuccess: (() -> Void)? = nil
    
    private var selectedCategoryText: String {
        guard let id = viewModel.selectedCategoryId else { return "Selecione a categoria" }
        return MockData.categories.first(where: { $0.id == id })?.name ?? "Selecione"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    mediaSection
                    priceSection
                    mainInfoSection
                    Spacer(minLength: 40)
                }
            }
            .background(Color.white)
            .navigationTitle("Editar AnÃºncio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(Theme.primary)
                }
            }
            .safeAreaInset(edge: .bottom) { bottomButton }
            .onChange(of: selectedItems) { _, newItems in
                loadMedia(from: newItems)
            }
            .overlay(loadingOverlay)
            .onChange(of: viewModel.publishSuccess) { _, success in
                if success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                        onPublishSuccess?()
                    }
                }
            }
            .alert("Erro", isPresented: Binding<Bool>(
                get: { viewModel.publishError != nil },
                set: { if !$0 { viewModel.publishError = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.publishError ?? "Erro desconhecido")
            }
        }
    }
    
    @ViewBuilder private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fotos e VÃƒÂ­deos")
                .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .any(of: [.images, .videos])) {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.badge.ellipsis")
                                .font(.custom("Inter-Regular", size: 28))
                            Text("Adicionar")
                                .font(.custom("Inter-Regular", size: 12, relativeTo: .caption))
                                
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
                        Image(uiImage: media.image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                Group {
                                    if media.isVideo {
                                        ZStack {
                                            Color.black.opacity(0.3)
                                            Image(systemName: "play.circle.fill")
                                                .font(.custom("Inter-Bold", size: 24, relativeTo: .title))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            )
                            .overlay(
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
                                .padding(6),
                                alignment: .topTrailing
                            )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 16)
    }
    
    @ViewBuilder private var priceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PreÃƒÂ§o do Produto")
                .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                .foregroundColor(Theme.textPrimary)
            
            HStack {
                Text("R$")
                    .font(.custom("Inter-Bold", size: 22, relativeTo: .title2))
                    
                    .foregroundColor(Theme.textSecondary)
                TextField("0,00", text: $viewModel.price)
                    .font(.custom("Inter-Bold", size: 24))
                    .keyboardType(.decimalPad)
                    .foregroundColor(Theme.textPrimary)
            }
            .padding()
            .background(Theme.inputBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder private var mainInfoSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("TÃƒÂ­tulo")
                    .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                TextField("Ex: iPhone 13 128GB impecÃƒÂ¡vel", text: $viewModel.title)
                    .padding()
                    .background(Theme.inputBackground)
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("DescriÃƒÂ§ÃƒÂ£o")
                    .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                TextEditor(text: $viewModel.description)
                    .frame(height: 120)
                    .padding(8)
                    .background(Theme.inputBackground)
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Estado de conservaÃƒÂ§ÃƒÂ£o")
                    .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                HStack {
                    ForEach(ProductCondition.allCases, id: \.self) { condition in
                        ConditionButton(
                            condition: condition,
                            isSelected: viewModel.selectedCondition == condition,
                            action: { viewModel.selectedCondition = condition }
                        )
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Categoria")
                    .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                Menu {
                    ForEach(MockData.categories) { cat in
                        Button(action: { viewModel.selectedCategoryId = cat.id }) {
                            Text(cat.name)
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedCategoryText)
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
                Text("LocalizaÃƒÂ§ÃƒÂ£o")
                    .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                TextField("Ex: SÃƒÂ£o Paulo - SP", text: $viewModel.location)
                    .padding()
                    .background(Theme.inputBackground)
                    .cornerRadius(12)
            }
            
            Toggle("Aceita negociaÃƒÂ§ÃƒÂ£o?", isOn: $viewModel.acceptsNegotiation)
                .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                .padding(.vertical, 8)
                .tint(Theme.primary)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder private var bottomButton: some View {
        Button(action: { 
            if authViewModel.currentUser?.id != nil {
                let images = selectedMedia.map { $0.image }
                viewModel.save(images: images)
            }
        }) {
            HStack {
                if viewModel.isPublishing {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Publicar AnÃƒÂºncio")
                        .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
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
    
    @ViewBuilder private var loadingOverlay: some View {
        Group {
            if viewModel.isPublishing || viewModel.publishSuccess {
                ZStack {
                    Color.black.opacity(0.6).edgesIgnoringSafeArea(.all)
                    VStack(spacing: 20) {
                        if viewModel.isPublishing {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Salvando...")
                                .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                                .foregroundColor(.white)
                        } else if viewModel.publishSuccess {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.custom("Inter-Regular", size: 60))
                                .foregroundColor(.green)
                            Text("AlteraÃ§Ãµes salvas!")
                                .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(40)
                    .background(Color(UIColor.systemGray6).opacity(0.2))
                    .cornerRadius(20)
                }
            }
        }
    }
    
    private func loadMedia(from items: [PhotosPickerItem]) {
        Task {
            isLoadingMedia = true
            var loadedMedia: [SelectedMedia] = []
            
            for item in items {
                // For video fallback/mock, since actual video extraction is complex,
                // we check if it is a video type and provide a dummy image or try to load.
                if item.supportedContentTypes.contains(UTType.movie) ||
                   item.supportedContentTypes.contains(UTType.video) ||
                   item.supportedContentTypes.contains(UTType.mpeg4Movie) ||
                   item.supportedContentTypes.contains(UTType.quickTimeMovie) {
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

