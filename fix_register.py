import re

with open("ViewModels/RegisterViewModel.swift", "r", encoding="utf-8") as f:
    content = f.read()

# Fix the duplicate count checks with proper limit(1) queries
new_validate = """    func validateAndProceed() {
        errorMessage = nil
        
        Task { @MainActor in
            struct IDResponse: Codable { let id: UUID }
            
            switch self.currentStep {
            case .name:
                let trimmedName = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedName.count < 3 || !trimmedName.contains(" ") {
                    self.errorMessage = "Digite seu nome e sobrenome completo."
                    return
                }
            case .cpf:
                let cleanCpf = self.cpf.filter { $0.isNumber }
                if cleanCpf.count != 11 {
                    self.errorMessage = "O CPF deve conter exatamente 11 números."
                    return
                }
                if !RegisterViewModel.isValidCPF(cleanCpf) {
                    self.errorMessage = "CPF inválido. Por favor, verifique os números."
                    return
                }
                do {
                    let existing: [IDResponse] = try await supabase.database.from("profiles").select("id").eq("document", value: cleanCpf).limit(1).execute().value
                    if !existing.isEmpty {
                        self.errorMessage = "Este CPF já está cadastrado em nosso sistema."
                        return
                    }
                } catch {
                    print("Erro verificando CPF: \(error)")
                }
            case .birthDate:
                let age = Calendar.current.dateComponents([.year], from: self.birthDate, to: Date()).year ?? 0
                if age < 18 {
                    self.errorMessage = "É necessário ter mais de 18 anos para se cadastrar."
                    return
                }
            case .email:
                let cleanEmail = self.email.trimmingCharacters(in: .whitespacesAndNewlines)
                if !RegisterViewModel.isValidEmail(cleanEmail) {
                    self.errorMessage = "Digite um endereço de e-mail válido (ex: nome@email.com)."
                    return
                }
                do {
                    let existing: [IDResponse] = try await supabase.database.from("profiles").select("id").eq("email", value: cleanEmail.lowercased()).limit(1).execute().value
                    if !existing.isEmpty {
                        self.errorMessage = "Este e-mail já está em uso por outra conta."
                        return
                    }
                } catch {
                    print("Erro verificando email: \(error)")
                }
            case .password:
                if self.password.count < 6 {
                    self.errorMessage = "A senha deve ter no mínimo 6 caracteres."
                    return
                }
            case .username:
                let cleanUser = self.username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanUser.isEmpty {
                    self.errorMessage = "Digite um nome de usuário."
                    return
                }
                if !RegisterViewModel.isValidUsername(cleanUser) {
                    self.errorMessage = "O usuário deve ter de 3 a 20 caracteres e conter apenas letras, números, ponto ou underline."
                    return
                }
                do {
                    let existing: [IDResponse] = try await supabase.database.from("profiles").select("id").eq("username", value: cleanUser).limit(1).execute().value
                    if !existing.isEmpty {
                        self.errorMessage = "Este nome de usuário '@\(cleanUser)' já está em uso. Escolha outro."
                        return
                    }
                } catch {
                    print("Erro verificando username: \(error)")
                }
            default:
                break
            }
            
            self.nextStep()
        }
    }"""

content = re.sub(r'func validateAndProceed\(\) \{.*?self\.nextStep\(\)\n\s*\}\n\s*\}', new_validate, content, flags=re.DOTALL)

# Fix register function
new_register = """    func register(authViewModel: AuthViewModel, completion: @escaping () -> Void) {
        self.errorMessage = nil
        Task {
            do {
                let response = try await supabase.auth.signUp(email: self.email, password: self.password)
                let user = response.user
                var avatarUrlStr: String? = nil
                if let image = self.profileImage, let data = image.jpegData(compressionQuality: 0.7) {
                    let fileName = "\(user.id.uuidString).jpg"
                    do {
                        try await supabase.storage.from("avatars").upload(
                            path: fileName,
                            file: data
                        )
                        let publicUrl = try supabase.storage.from("avatars").getPublicURL(path: fileName)
                        avatarUrlStr = publicUrl.absoluteString
                    } catch {
                        print("Erro ao fazer upload do avatar: \(error)")
                    }
                }
                
                let currentCpf = self.cpf
                let cleanCpf = currentCpf.filter { char in char.isNumber }
                let newProfile = Profile(
                    id: user.id,
                    name: self.name,
                    visible_name: self.visibleName.isEmpty ? nil : self.visibleName,
                    username: self.username,
                    email: self.email,
                    document: cleanCpf,
                    location: self.locationName.isEmpty ? "Desconhecido" : self.locationName,
                    avatar_url: avatarUrlStr,
                    created_at: Date(),
                    rating: nil,
                    response_time: nil
                )
                
                try await supabase.database
                    .from("profiles")
                    .insert(newProfile)
                    .execute()
                    
                let finalEmail = self.email
                let finalPassword = self.password
                
                await MainActor.run {
                    authViewModel.login(emailOrUsername: finalEmail, password: finalPassword)
                    completion()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Ocorreu um erro no cadastro: \(error.localizedDescription)"
                }
            }
        }
    }
}"""

content = re.sub(r'func register\(authViewModel: AuthViewModel, completion: @escaping \(\) -> Void\).*', new_register, content, flags=re.DOTALL)

with open("ViewModels/RegisterViewModel.swift", "w", encoding="utf-8") as f:
    f.write(content)
