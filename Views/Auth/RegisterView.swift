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
                Button(action: {
                    if viewModel.currentStep == .name {
                        dismiss()
                    } else {
                        withAnimation { viewModel.previousStep() }
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.custom("Inter-Bold", size: 22, relativeTo: .title2))
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
                Text("Passo \(viewModel.currentStep.rawValue + 1) de \(RegisterStep.allCases.count)")
                    .font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                if viewModel.currentStep != .name {
                    Image(systemName: "chevron.left").opacity(0)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            ProgressView(value: Double(viewModel.currentStep.rawValue + 1), total: Double(RegisterStep.allCases.count))
                .tint(Theme.primary)
                .padding(.horizontal)
                .padding(.top, 4)
            
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
            }
            .padding(.top, 4)
            
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
                .font(.custom("Inter-Bold", size: 22, relativeTo: .title2))
                
                .foregroundColor(Theme.textPrimary)
            
            CustomTextField(title: "Nome e Sobrenome", placeholder: "Seu nome completo", text: $viewModel.name)
            
            PrimaryButton(title: "Continuar", isEnabled: !viewModel.name.isEmpty, isLoading: viewModel.isChecking) {
                withAnimation { viewModel.validateAndProceed() }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    var stepCPF: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("E o seu CPF?")
                .font(.custom("Inter-Bold", size: 22, relativeTo: .title2))
                
                .foregroundColor(Theme.textPrimary)
            
            CustomTextField(title: "CPF", placeholder: "000.000.000-00", text: $viewModel.cpf, keyboardType: .numberPad)
                .onChange(of: viewModel.cpf) { _, newValue in
                    let numbers = newValue.filter { $0.isNumber }
                    var result = ""
                    for (index, char) in numbers.enumerated() {
                        if index == 3 || index == 6 { result.append(".") }
                        else if index == 9 { result.append("-") }
                        if index < 11 { result.append(char) }
                    }
                    if viewModel.cpf != result { viewModel.cpf = result }
                }
            
            PrimaryButton(title: "Continuar", isEnabled: viewModel.cpf.filter { $0.isNumber }.count == 11, isLoading: viewModel.isChecking) {
                withAnimation { viewModel.validateAndProceed() }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    var stepBirthDate: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Qual a sua data de nascimento?")
                .font(.custom("Inter-Bold", size: 22, relativeTo: .title2))
                
                .foregroundColor(Theme.textPrimary)
            
            DatePicker("Data de Nascimento", selection: $viewModel.birthDate, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            
            PrimaryButton(title: "Continuar", isLoading: viewModel.isChecking) {
                withAnimation { viewModel.validateAndProceed() }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    var stepEmail: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Informe seu melhor e-mail")
                .font(.custom("Inter-Bold", size: 22, relativeTo: .title2))
                
                .foregroundColor(Theme.textPrimary)
            
            CustomTextField(title: "E-mail", placeholder: "exemplo@email.com", text: $viewModel.email, keyboardType: .emailAddress)
            
            PrimaryButton(title: "Continuar", isEnabled: viewModel.email.contains("@"), isLoading: viewModel.isChecking) {
                withAnimation { viewModel.validateAndProceed() }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    var stepPassword: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Crie uma senha segura")
                .font(.custom("Inter-Bold", size: 22, relativeTo: .title2))
                
                .foregroundColor(Theme.textPrimary)
            
            CustomTextField(title: "Senha", placeholder: "Mínimo 6 caracteres", text: $viewModel.password, isSecure: true)
            
            PrimaryButton(title: "Continuar", isEnabled: viewModel.password.count >= 6, isLoading: viewModel.isChecking) {
                withAnimation { viewModel.validateAndProceed() }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    var stepUsername: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Escolha seu nome de usuário")
                .font(.custom("Inter-Bold", size: 22, relativeTo: .title2))
                
                .foregroundColor(Theme.textPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Usuário").font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline)).foregroundColor(Theme.textSecondary)
                HStack {
                    Text("@").foregroundColor(Theme.primary)
                    TextField("seunome", text: $viewModel.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: viewModel.username) { _, _ in
                            viewModel.checkUsernameAvailability()
                        }
                    
                    if viewModel.isCheckingUsername {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if viewModel.isUsernameAvailable == true {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .transition(.scale)
                    }
                }
                .padding()
                .background(Theme.inputBackground)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                
                if let available = viewModel.isUsernameAvailable, available {
                    Text("Nome de usuário disponível")
                        .font(.custom("Inter-Regular", size: 12, relativeTo: .caption))
                        .foregroundColor(Theme.primary)
                }
            }
            
            PrimaryButton(title: "Continuar", isEnabled: !viewModel.username.isEmpty, isLoading: viewModel.isChecking) {
                withAnimation { viewModel.validateAndProceed() }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    var stepLocation: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60) // Moves everything up slightly
                
                // Illustration — use cropped asset from design reference
                Image("location_illustration")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320)
                    .mask(Rectangle().padding(.top, 20).padding(.leading, 20))
                    .padding(.bottom, 24)
                
                // Title: "De onde você é?" — "você" in green
                Group {
                    Text("De onde ").foregroundColor(Color(hex: "1A1A2E")) +
                    Text("você ").foregroundColor(Theme.primary) +
                    Text("é?").foregroundColor(Color(hex: "1A1A2E"))
                }
                .font(.custom("Inter-Bold", size: 24))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)
                
                // Subtitle
                Text("Usamos sua localização para mostrar\nprodutos próximos a você.")
                    .font(.custom("Inter-Regular", size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 36)
                    .padding(.bottom, 40)
                
                // Location confirmed badge
                if !viewModel.locationName.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(viewModel.locationName)
                            .font(.custom("Inter-SemiBold", size: 15))
                            .foregroundColor(Theme.textPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.lightGreen)
                    .cornerRadius(12)
                    .padding(.bottom, 24)
                }
                
                if viewModel.isFetchingLocation {
                    ProgressView("Obtendo localização...")
                        .padding(.bottom, 24)
                } else if viewModel.locationName.isEmpty {
                    // Only show 'Usar minha localização atual' if location is NOT set yet
                    Button(action: { viewModel.requestLocation() }) {
                        HStack(spacing: 10) {
                            Image(systemName: "paperplane.fill")
                                .font(.custom("Inter-Bold", size: 16))
                            Text("Usar minha localização atual")
                                .font(.custom("Inter-Bold", size: 16))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Theme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(32)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                
                Spacer()
                
                // Continuar — shown ONLY after location set
                if !viewModel.locationName.isEmpty {
                    PrimaryButton(title: "Continuar") {
                        withAnimation { viewModel.validateAndProceed() }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }



    
    // MARK: - Profile Setup Step
    var stepProfileSetup: some View {
        VStack(alignment: .center, spacing: 20) {
            VStack(spacing: 6) {
                Text("Dados do Perfil")
                    .font(.custom("Inter-Bold", size: 22, relativeTo: .title2))
                    
                    .foregroundColor(Theme.textPrimary)
                
                Text("Por favor, informe seu nome e adicione uma foto de perfil opcional.")
                    .font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 4)
            
            // Profile Avatar Picker with Camera Badge
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
                                    .font(.custom("Inter-Regular", size: 48))
                                    .foregroundColor(Theme.primary.opacity(0.7))
                            )
                            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                    }
                    
                    ZStack {
                        Circle()
                            .fill(Theme.primary)
                            .frame(width: 40, height: 40)
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                        
                        Image(systemName: "camera.fill")
                            .font(.custom("Inter-Bold", size: 18))
                            .foregroundColor(.white)
                    }
                    .offset(x: 2, y: 2)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        viewModel.profileImage = uiImage
                    }
                }
            }
            .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Nome de Exibição")
                    .font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline))
                    
                    .foregroundColor(Theme.textSecondary)
                
                HStack {
                    TextField("Seu nome (ex: João)", text: $viewModel.visibleName)
                        .font(.custom("Inter-Regular", size: 17, relativeTo: .body))
                    
                    Image(systemName: "pencil")
                        .foregroundColor(Theme.textSecondary)
                }
                .padding()
                .background(Theme.inputBackground)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                
                Text("Este é o nome que aparecerá no seu perfil e nas conversas do chat.")
                    .font(.custom("Inter-Regular", size: 12, relativeTo: .caption))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal)
            
            Spacer().frame(height: 12)
            
            PrimaryButton(title: "Concluir cadastro", isEnabled: !viewModel.visibleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, isLoading: viewModel.isChecking) {
                viewModel.register(authViewModel: authViewModel) {
                    // Do nothing, SplashView will route automatically
                }
            }
            .padding(.horizontal)
        }
        .customBackButton()
        .onAppear {
            if viewModel.visibleName.isEmpty {
                viewModel.visibleName = viewModel.name.components(separatedBy: " ").first ?? ""
            }
        }
    }
}


