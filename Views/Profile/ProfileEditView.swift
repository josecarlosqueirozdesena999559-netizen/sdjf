import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username = ""
    @State private var visibleName = ""
    @State private var location = ""
    @State private var responseTime = "Responde em até 1 hora"
    @State private var bio = ""
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    
    let responseOptions = [
        "Responde imediatamente",
        "Responde em até 1 hora",
        "Responde em algumas horas",
        "Responde em até 1 dia",
        "Pode demorar a responder"
    ]
    
    @State private var isSaving = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        VStack(spacing: 12) {
                            if let profileImage = profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Theme.inputBackground)
                                    .frame(width: 90, height: 90)
                                    .overlay(
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.custom("Inter-Regular", size: 90))
                                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                                    )
                            }
                            
                            Text("Alterar foto de perfil")
                                .font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline))
                                
                                .foregroundColor(Theme.primary)
                        }
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    self.profileImage = uiImage
                                }
                            }
                        }
                    }
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            
            Section(header: Text("Informações Pessoais")) {
                HStack {
                    Text("Nome")
                        .frame(width: 80, alignment: .leading)
                    TextField("Seu nome", text: $visibleName)
                }
                HStack {
                    Text("Usuário")
                        .frame(width: 80, alignment: .leading)
                    TextField("Nome de usuário", text: $username)
                        .autocapitalization(.none)
                }
                HStack {
                    Text("Cidade")
                        .frame(width: 80, alignment: .leading)
                    TextField("Ex: São Paulo - SP", text: $location)
                }
            }
            
            Section(header: Text("Perfil de Vendedor")) {
                Picker("Tempo de Resposta", selection: $responseTime) {
                    ForEach(responseOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                VStack(alignment: .leading) {
                    Text("Biografia")
                    TextEditor(text: $bio)
                        .frame(height: 80)
                }
            }
        }
        .navigationTitle("Editar Perfil")
        .customBackButton()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: saveProfile) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Salvar")
                            .foregroundColor(Theme.primary)
                            
                    }
                }
                .disabled(isSaving)
            }
        }
        .onAppear {
            username = authViewModel.currentUser?.username ?? ""
            visibleName = authViewModel.currentUser?.visibleName ?? ""
            location = authViewModel.currentUser?.location ?? ""
            // Mocking some defaults for demonstration since Seller isn't in AuthViewModel
            bio = "Vendo itens que não uso mais, tudo bem conservado!"
        }
    }
    
    private func saveProfile() {
        guard let userId = authViewModel.currentUser?.id else { return }
        isSaving = true
        
        Task {
            do {
                struct UpdateProfile: Codable {
                    let username: String
                    let visible_name: String
                    let location: String
                    let avg_response_time: String
                }
                let updateData = UpdateProfile(
                    username: username,
                    visible_name: visibleName,
                    location: location,
                    avg_response_time: responseTime
                )
                
                try await supabase.database
                    .from("profiles")
                    .update(updateData)
                    .eq("id", value: userId)
                    .execute()
                
                await MainActor.run {
                    authViewModel.currentUser?.username = username
                    authViewModel.currentUser?.visibleName = visibleName
                    authViewModel.currentUser?.location = location
                    authViewModel.currentUser?.responseTime = responseTime
                    isSaving = false
                    dismiss()
                }
            } catch {
                print("Failed to save profile: \(error)")
                await MainActor.run { isSaving = false }
            }
        }
    }
}
