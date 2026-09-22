import SwiftUI

struct ProfileSetupSheet: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var bio: String = ""
    @State private var responseTime: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String? = nil

    let responseOptions = ["Menos de 1 hora", "Poucas horas", "Mesmo dia", "Em até 1 dia", "Alguns dias"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Configure seu perfil")
                            .font(.custom("Inter-Bold", size: 22, relativeTo: .title2))
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textPrimary)

                        Text("Essas informações ajudam compradores a conhecer você.")
                            .font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.top, 8)

                    // Bio field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Biografia")
                            .font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline))
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.textSecondary)

                        ZStack(alignment: .topLeading) {
                            if bio.isEmpty {
                                Text("Escreva um pouco sobre você ou seus produtos…")
                                    .foregroundColor(Color.gray.opacity(0.6))
                                    .font(.custom("Inter-Regular", size: 17, relativeTo: .body))
                                    .padding(14)
                            }
                            TextEditor(text: $bio)
                                .font(.custom("Inter-Regular", size: 17, relativeTo: .body))
                                .frame(minHeight: 110)
                                .opacity(bio.isEmpty ? 0.98 : 1)
                        }
                        .background(Theme.inputBackground)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                    }

                    // Response time picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tempo de resposta")
                            .font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline))
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.textSecondary)

                        VStack(spacing: 10) {
                            ForEach(responseOptions, id: \.self) { option in
                                Button(action: { responseTime = option }) {
                                    HStack {
                                        Text(option)
                                            .font(.custom("Inter-Regular", size: 17, relativeTo: .body))
                                            .foregroundColor(Theme.textPrimary)
                                        Spacer()
                                        if responseTime == option {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Theme.primary)
                                        } else {
                                            Circle()
                                                .stroke(Theme.border, lineWidth: 1.5)
                                                .frame(width: 22, height: 22)
                                        }
                                    }
                                    .padding(14)
                                    .background(responseTime == option ? Theme.lightGreen : Theme.inputBackground)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(responseTime == option ? Theme.primary : Theme.border, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }

                    if let error = errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                        }
                        .font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline))
                        .foregroundColor(.red)
                    }

                    // Save button
                    Button(action: saveProfile) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.primary)
                                .cornerRadius(30)
                        } else {
                            Text("Salvar perfil")
                                .font(.custom("Inter-SemiBold", size: 17, relativeTo: .headline))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.primary)
                                .cornerRadius(30)
                        }
                    }
                    .disabled(isSaving)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { skipSetup() }) {
                        Image(systemName: "arrow.left")
                            .font(.custom("Inter-SemiBold", size: 16))
                            .foregroundColor(Theme.textPrimary)
                    }
                }
            }
        }
        .interactiveDismissDisabled(true)
    }

    private func skipSetup() {
        authViewModel.needsProfileSetup = false
        dismiss()
    }

    private func saveProfile() {
        guard let userId = authViewModel.currentUser?.id else { return }
        isSaving = true
        errorMessage = nil

        Task {
            do {
                struct ProfileUpdate: Encodable {
                    let bio: String?
                    let avg_response_time: String?
                }
                let update = ProfileUpdate(
                    bio: bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : bio.trimmingCharacters(in: .whitespacesAndNewlines),
                    avg_response_time: responseTime.isEmpty ? nil : responseTime
                )
                try await supabase.database
                    .from("profiles")
                    .update(update)
                    .eq("id", value: userId.uuidString)
                    .execute()

                await MainActor.run {
                    authViewModel.currentUser?.bio = bio.isEmpty ? nil : bio
                    authViewModel.currentUser?.responseTime = responseTime.isEmpty ? nil : responseTime
                    authViewModel.needsProfileSetup = false
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Erro ao salvar perfil."
                    isSaving = false
                }
            }
        }
    }
}
