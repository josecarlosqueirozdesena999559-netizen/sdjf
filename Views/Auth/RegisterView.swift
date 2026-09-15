import SwiftUI
import PhotosUI

struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedItem: PhotosPickerItem? = nil
    
    var body: some View {
        VStack {
            HStack {
                if viewModel.currentStep != .name {
                    Button(action: {
                        withAnimation { viewModel.previousStep() }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Theme.textPrimary)
                    }
                }
                Spacer()
                Text("Passo \(viewModel.currentStep.rawValue + 1) de \(RegisterStep.allCases.count)")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                if viewModel.currentStep != .name {
                    // Spacer for balance
                    Image(systemName: "chevron.left").opacity(0)
                }
            }
            .padding()
            
            ProgressView(value: Double(viewModel.currentStep.rawValue + 1), total: Double(RegisterStep.allCases.count))
                .tint(Theme.primary)
                .padding(.horizontal)
            
            Spacer()
            
            switch viewModel.currentStep {
            case .name:
                stepName
            case .cpf:
                stepCPF
            case .birthDate:
                stepBirthDate
            case .email:
                stepEmail
            case .password:
                stepPassword
            case .username:
                stepUsername
            case .location:
                stepLocation
            case .profileSetup:
                stepProfileSetup
            }
            
            Spacer()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
    }
    
    // MARK: - Steps
    
    var stepName: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Qual é o seu nome completo?")
                .font(.title2)
                .fontWeight(.bold)
            
            CustomTextField(title: "Nome", placeholder: "Seu nome completo", text: $viewModel.name)
            
            PrimaryButton(title: "Continuar", isEnabled: !viewModel.name.isEmpty) {
                withAnimation { viewModel.nextStep() }
            }
        }
        .padding()
    }
    
    var stepCPF: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("E o seu CPF?")
                .font(.title2)
                .fontWeight(.bold)
            
            CustomTextField(title: "CPF", placeholder: "000.000.000-00", text: $viewModel.cpf, keyboardType: .numberPad)
            
            PrimaryButton(title: "Continuar", isEnabled: viewModel.cpf.count >= 11) {
                withAnimation { viewModel.nextStep() }
            }
        }
        .padding()
    }
    
    var stepBirthDate: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Qual a sua data de nascimento?")
                .font(.title2)
                .fontWeight(.bold)
            
            DatePicker("Data de Nascimento", selection: $viewModel.birthDate, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            
            PrimaryButton(title: "Continuar") {
                withAnimation { viewModel.nextStep() }
            }
        }
        .padding()
    }
    
    var stepEmail: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Informe seu melhor e-mail")
                .font(.title2)
                .fontWeight(.bold)
            
            CustomTextField(title: "E-mail", placeholder: "exemplo@email.com", text: $viewModel.email, keyboardType: .emailAddress)
            
            PrimaryButton(title: "Continuar", isEnabled: viewModel.email.contains("@")) {
                withAnimation { viewModel.nextStep() }
            }
        }
        .padding()
    }
    
    var stepPassword: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Crie uma senha segura")
                .font(.title2)
                .fontWeight(.bold)
            
            CustomTextField(title: "Senha", placeholder: "Sua senha", text: $viewModel.password, isSecure: true)
            
            PrimaryButton(title: "Continuar", isEnabled: viewModel.password.count >= 6) {
                withAnimation { viewModel.nextStep() }
            }
        }
        .padding()
    }
    
    var stepUsername: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Escolha um nome de usuário")
                .font(.title2)
                .fontWeight(.bold)
            Text("Este nome será usado para seu link de perfil")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
            
            CustomTextField(title: "Usuário", placeholder: "@seu.usuario", text: $viewModel.username)
            
            PrimaryButton(title: "Continuar", isEnabled: !viewModel.username.isEmpty) {
                withAnimation { viewModel.nextStep() }
            }
        }
        .padding()
    }
    
    var stepLocation: some View {
        VStack(alignment: .center, spacing: 24) {
            Image(systemName: "location.fill")
                .font(.system(size: 60))
                .foregroundColor(Theme.primary)
            
            Text("De onde você é?")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Usamos sua localização para mostrar produtos próximos a você.")
                .multilineTextAlignment(.center)
                .foregroundColor(Theme.textSecondary)
            
            if !viewModel.locationName.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(viewModel.locationName)
                        .font(.headline)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
            
            if viewModel.isFetchingLocation {
                ProgressView()
                    .padding()
            } else if viewModel.locationName.isEmpty {
                Button(action: {
                    viewModel.requestLocation()
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Usar minha localização atual")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.lightGreen)
                    .foregroundColor(Theme.primary)
                    .cornerRadius(12)
                }
            }
            
            Spacer()
            
            PrimaryButton(title: "Continuar", isEnabled: !viewModel.locationName.isEmpty) {
                withAnimation { viewModel.nextStep() }
            }
        }
        .padding()
    }
    
    var stepProfileSetup: some View {
        VStack(alignment: .center, spacing: 24) {
            Text("Quase lá!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Adicione uma foto e o nome que os outros usuários verão.")
                .multilineTextAlignment(.center)
                .foregroundColor(Theme.textSecondary)
            
            PhotosPicker(selection: $selectedItem, matching: .images) {
                if let profileImage = viewModel.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.border, lineWidth: 2))
                } else {
                    Circle()
                        .fill(Theme.lightGreen)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.title)
                                .foregroundColor(Theme.primary)
                        )
                }
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        viewModel.profileImage = uiImage
                    }
                }
            }
            
            CustomTextField(title: "Nome de exibição (como no WhatsApp)", placeholder: "Nome Visível", text: $viewModel.visibleName)
            
            Spacer()
            
            PrimaryButton(title: "Concluir cadastro", isEnabled: !viewModel.visibleName.isEmpty) {
                // Mock registration completion
                let newUser = User(id: UUID(), name: viewModel.name, cpf: viewModel.cpf, birthDate: viewModel.birthDate, email: viewModel.email, phone: "", username: viewModel.username, visibleName: viewModel.visibleName, avatarURL: nil, location: viewModel.locationName, latitude: viewModel.latitude, longitude: viewModel.longitude, memberSince: Date(), isProfessional: false)
                
                authViewModel.currentUser = newUser
                authViewModel.isAuthenticated = true
                dismiss() // If navigated from Login, authViewModel update will transition to Home
            }
        }
        .padding()
        .onAppear {
            if viewModel.visibleName.isEmpty {
                // Puxar o primeiro nome por padrao
                viewModel.visibleName = viewModel.name.components(separatedBy: " ").first ?? ""
            }
        }
    }
}
