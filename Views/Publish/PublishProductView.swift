import SwiftUI
import PhotosUI

struct PublishProductView: View {
    @StateObject private var viewModel = PublishViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Fotos do Produto")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            PhotosPicker(selection: $selectedItems, maxSelectionCount: 6, matching: .images) {
                                VStack {
                                    Image(systemName: "camera.fill")
                                        .font(.title2)
                                    Text("Adicionar")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .frame(width: 80, height: 80)
                                .background(Theme.inputBackground)
                                .foregroundColor(Theme.primary)
                                .cornerRadius(8)
                            }
                            
                            ForEach(0..<selectedImages.count, id: \.self) { index in
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        Button(action: {
                                            selectedImages.remove(at: index)
                                            selectedItems.remove(at: index)
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                                .background(Circle().fill(Color.white))
                                        }
                                        .offset(x: 5, y: -5)
                                        , alignment: .topTrailing
                                    )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onChange(of: selectedItems) { newItems in
                        Task {
                            selectedImages = []
                            for item in newItems {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    selectedImages.append(image)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Informações Principais")) {
                    TextField("Título (Ex: iPhone 13 128GB)", text: $viewModel.title)
                    TextField("Preço (R$ 0,00)", text: $viewModel.price)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Detalhes")) {
                    Picker("Estado", selection: $viewModel.selectedCondition) {
                        ForEach(ProductCondition.allCases, id: \.self) { condition in
                            Text(condition.rawValue).tag(condition)
                        }
                    }
                    
                    Picker("Categoria", selection: $viewModel.selectedCategoryId) {
                        Text("Selecione").tag(UUID?.none)
                        ForEach(MockData.categories) { category in
                            Text(category.name).tag(Optional(category.id))
                        }
                    }
                    
                    TextField("Localização (Ex: São Paulo - SP)", text: $viewModel.location)
                }
                
                Section(header: Text("Descrição")) {
                    TextEditor(text: $viewModel.description)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button(action: {
                        viewModel.publish()
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isPublishing {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Publicar Anúncio")
                                    .font(.headline)
                            }
                            Spacer()
                        }
                        .foregroundColor(viewModel.isFormValid ? .white : Theme.textSecondary)
                    }
                    .listRowBackground(viewModel.isFormValid ? Theme.primary : Theme.inputBackground)
                    .disabled(!viewModel.isFormValid || viewModel.isPublishing)
                }
            }
            .navigationTitle("Anunciar Produto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Cancelar")
                            .foregroundColor(Theme.primary)
                    }
                }
            }
            .alert("Sucesso", isPresented: $viewModel.publishSuccess) {
                Button("OK", role: .cancel) { dismiss() }
            } message: {
                Text("Seu anúncio foi publicado com sucesso!")
            }
        }
    }
}
