import SwiftUI

struct ProfileEditView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username = ""
    @State private var visibleName = ""
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Theme.inputBackground)
                            .frame(width: 90, height: 90)
                            .overlay(
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 90))
                                    .foregroundColor(Theme.textSecondary.opacity(0.5))
                            )
                        
                        Text("Alterar foto de perfil")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.primary)
                    }
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            
            Section(header: Text("Informações")) {
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
            }
        }
        .navigationTitle("Editar Perfil")
        .customBackButton()
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            username = authViewModel.currentUser?.username ?? ""
            visibleName = authViewModel.currentUser?.visibleName ?? ""
        }
    }
}

