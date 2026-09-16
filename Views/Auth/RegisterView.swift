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
            

            
            VStack {
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
            } // End of VStack wrapping steps
            .padding(.top, 8)
            
            Spacer()
        }
        .background(Theme.background.ignoresSafeArea())
        .alert(isPresented: Binding<Bool>(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Alert(title: Text("Atenção"), message: Text(viewModel.errorMessage ?? ""), dismissButton: .default(Text("OK")))
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Steps
    
    var stepName: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Qual é o seu nome completo?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)
            
            CustomTextField(title: "Nome e Sobrenome", placeholder: "Seu nome completo", text: $viewModel.name)
            
            PrimaryButton(title: "Continuar", isEnabled: !viewModel.name.isEmpty) {
                withAnimation { viewModel.validateAndProceed() }
            }
        }
        .padding(.horizontal)
    }
    
    var stepCPF: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("E o seu CPF?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)
            
            CustomTextField(title: "CPF", placeholder: "000.000.000-00", text: $viewModel.cpf, keyboardType: .numberPad)
            
            PrimaryButton(title: "Continuar", isEnabled: viewModel.cpf.filter { $0.isNumber }.count == 11) {
                withAnimation { viewModel.validateAndProceed() }
            }
        }
        .padding(.horizontal)
    }
    
    var stepBirthDate: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Qual a sua data de nascimento?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)
            
            DatePicker("Data de Nascimento", selection: $viewModel.birthDate, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            
            PrimaryButton(title: "Continuar") {
                withAnimation { viewModel.validateAndProceed() }
            }
        }
        .padding(.horizontal)
    }
    
    var stepEmail: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Informe seu melhor e-mail")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)
            
            CustomTextField(title: "E-mail", placeholder: "exemplo@email.com", text: $viewModel.email, keyboardType: .emailAddress)
            
            PrimaryButton(title: "Continuar", isEnabled: viewModel.email.contains("@")) {
                withAnimation { viewModel.validateAndProceed() }
            }
        }
        .padding(.horizontal)
    }
    
    var stepPassword: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Crie uma senha segura")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)
            
            CustomTextField(title: "Senha", placeholder: "Mínimo 6 caracteres", text: $viewModel.password, isSecure: true)
            
            PrimaryButton(title: "Continuar", isEnabled: viewModel.password.count >= 6) {
                withAnimation { viewModel.validateAndProceed() }
            }
        }
        .padding(.horizontal)
    }
    
    var stepUsername: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Escolha seu nome de usuário")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)
            Text("Ele identificará seu perfil e suas ofertas únicas no app")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Usuário").font(.subheadline).foregroundColor(Theme.textSecondary)
                HStack {
                    Text("@").foregroundColor(Theme.primary).fontWeight(.bold)
                    TextField("seu.usuario", text: $viewModel.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding()
                .background(Theme.inputBackground)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
            }
            
            PrimaryButton(title: "Continuar", isEnabled: !viewModel.username.isEmpty) {
                withAnimation { viewModel.validateAndProceed() }
            }
        }
        .padding(.horizontal)
    }
    
    var stepLocation: some View {
        VStack(alignment: .center, spacing: 20) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Theme.primary)
            
            Text("De onde você é?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)
            
            Text("Usamos sua localização para sugerir anúncios e vendedores perto de você.")
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
            
            Spacer().frame(height: 20)
            
            PrimaryButton(title: "Continuar", isEnabled: !viewModel.locationName.isEmpty) {
                withAnimation { viewModel.validateAndProceed() }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - WhatsApp Style Profile Setup
    var stepProfileSetup: some View {
        VStack(alignment: .center, spacing: 20) {
            VStack(spacing: 6) {
                Text("Dados do Perfil")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.textPrimary)
                
                Text("Por favor, informe seu nome e adicione uma foto de perfil opcional.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 4)
            
            // WhatsApp Style Avatar Picker with Camera Badge
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if let profileImage = viewModel.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 130, height: 130)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Theme.border, lineWidth: 2))
                            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                    } else {
                        Circle()
                            .fill(Theme.lightGreen)
                            .frame(width: 130, height: 130)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(Theme.primary.opacity(0.7))
                            )
                            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                    }
                    
                    // WhatsApp-style camera icon badge at bottom-right
                    ZStack {
                        Circle()
                            .fill(Theme.primary)
                            .frame(width: 40, height: 40)
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 2, y: 2)
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
            .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Nome de Exibição")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textSecondary)
                
                HStack {
                    TextField("Seu nome (ex: João)", text: $viewModel.visibleName)
                        .font(.body)
                    
                    Image(systemName: "pencil")
                        .foregroundColor(Theme.textSecondary)
                }
                .padding()
                .background(Theme.inputBackground)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                
                Text("Este é o nome que aparecerá no seu perfil e nas conversas do chat.")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal)
            
            Spacer().frame(height: 12)
            
            PrimaryButton(title: "Concluir cadastro", isEnabled: !viewModel.visibleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                let newUser = User(
                    id: UUID(),
                    name: viewModel.name,
                    cpf: viewModel.cpf,
                    birthDate: viewModel.birthDate,
                    email: viewModel.email,
                    phone: "",
                    username: viewModel.username,
                    visibleName: viewModel.visibleName,
                    avatarURL: nil,
                    location: viewModel.locationName,
                    latitude: viewModel.latitude,
                    longitude: viewModel.longitude,
                    memberSince: Date(),
                    isProfessional: false
                )
                
                authViewModel.currentUser = newUser
                authViewModel.isAuthenticated = true
                dismiss()
            }
            .padding(.horizontal)
        }
        .onAppear {
            if viewModel.visibleName.isEmpty {
                viewModel.visibleName = viewModel.name.components(separatedBy: " ").first ?? ""
            }
        }
    }
}
