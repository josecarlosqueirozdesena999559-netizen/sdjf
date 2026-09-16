import SwiftUI

struct PublishProductView: View {
    @StateObject private var viewModel = PublishViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Fotos Placeholder
                    HStack {
                        Button(action: {}) {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                Text("Adicionar")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .frame(width: 90, height: 90)
                            .background(Theme.lightGreen)
                            .foregroundColor(Theme.primary)
                            .cornerRadius(12)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        CustomTextField(title: "Título", placeholder: "Ex: iPhone 13 128GB", text: $viewModel.title)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Descrição")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                            TextEditor(text: $viewModel.description)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.border, lineWidth: 1)
                                )
                        }
                        
                        CustomTextField(title: "Preço (R$)", placeholder: "0,00", text: $viewModel.price, keyboardType: .decimalPad)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Estado")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                            Picker("Estado", selection: $viewModel.selectedCondition) {
                                ForEach(ProductCondition.allCases, id: \.self) { condition in
                                    Text(condition.rawValue).tag(condition)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Categoria")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                            
                            Menu {
                                ForEach(MockData.categories) { category in
                                    Button(category.name) {
                                        viewModel.selectedCategoryId = category.id
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(MockData.categories.first { $0.id == viewModel.selectedCategoryId }?.name ?? "Selecione uma categoria")
                                        .foregroundColor(viewModel.selectedCategoryId == nil ? .gray : Theme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                            }
                        }
                        
                        CustomTextField(title: "Localização", placeholder: "Ex: São Paulo - SP", text: $viewModel.location)
                        
                        
                    }
                    .padding(.horizontal)
                    
                    PrimaryButton(title: "Publicar anúncio", isEnabled: viewModel.isFormValid, isLoading: viewModel.isPublishing) {
                        viewModel.publish()
                    }
                    .padding()
                }
                .padding(.vertical)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Anunciar produto")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Sucesso", isPresented: $viewModel.publishSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Seu anúncio foi publicado com sucesso!")
            }
        }
    }
}
