import SwiftUI

/// Redireciona diretamente para o fluxo único de entrada via WhatsApp OTP (sem nome de usuário e sem senha)
struct RegisterFlowView: View {
    var body: some View {
        LoginView()
    }
}

// MARK: - Componente de 6 Quadrados de Código Estilo WhatsApp (Responsivo para qualquer tamanho de tela)
struct WhatsAppSixDigitOTPView: View {
    @Binding var code: String
    var onComplete: (() -> Void)? = nil
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // Campo numérico invisível para captura nativa do teclado e preenchimento automático de código (OTP)
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: code) { _, newValue in
                    let filtered = String(newValue.filter { $0.isNumber }.prefix(6))
                    if filtered != code {
                        code = filtered
                    }
                    if filtered.count == 6 {
                        onComplete?()
                    }
                }

            // 6 quadrados responsivos estilo WhatsApp
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    let charStr = digitAt(index)
                    let isCurrent = isFocused && (code.count == index || (code.count == 6 && index == 5))
                    let isFilled = !charStr.isEmpty

                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        isCurrent ? JuntoColors.primary : (isFilled ? JuntoColors.primary.opacity(0.45) : JuntoColors.inputBorder),
                                        lineWidth: isCurrent ? 1.8 : 1.0
                                    )
                            )

                        if isFilled {
                            Text(charStr)
                                .font(.inter(22, weight: .semibold))
                                .foregroundColor(JuntoColors.textMain)
                                .transition(.scale.combined(with: .opacity))
                        } else if isCurrent {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(JuntoColors.primary)
                                .frame(width: 2, height: 22)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isFocused = true
            }
        }
    }

    private func digitAt(_ index: Int) -> String {
        let digits = Array(code)
        guard index < digits.count else { return "" }
        return String(digits[index])
    }
}
