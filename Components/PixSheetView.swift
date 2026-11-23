import SwiftUI
import CoreImage.CIFilterBuiltins

struct PixSheetView: View {
    let data: PixChargeSheetData
    let onCopy: () -> Void
    @Environment(\.dismiss) private var dismiss

    enum PixTab: String, CaseIterable {
        case qrCode = "QR Code Pix"
        case copyKey = "Copiar Pix"
    }

    @State private var selectedTab: PixTab = .qrCode
    @State private var copiedPayload = false
    @State private var timeRemaining = 300 // 5 minutos = 300 segundos
    @State private var timer: Timer? = nil

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    private var formattedTime: String {
        let mins = timeRemaining / 60
        let secs = timeRemaining % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    var body: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(JuntoColors.border)
                .frame(width: 40, height: 4)
                .padding(.top, 10)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Pagar com Pix")
                            .font(.inter(18, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                        Text("Manual")
                            .font(.inter(10, weight: .semibold))
                            .foregroundColor(JuntoColors.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(JuntoColors.primaryLight)
                            .clipShape(Capsule())
                    }
                    Text("\(data.title) • Para: \(data.recipientName)")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }
                Spacer()
                Button { dismiss() } label: {
                    JuntoIcon(kind: .close, size: 12, color: JuntoColors.textMuted, weight: 2.0)
                        .frame(width: 30, height: 30)
                        .background(JuntoColors.surfaceSubtle)
                        .clipShape(Circle())
                }
            }

            // Banner de validade de 5 minutos
            HStack(spacing: 8) {
                Circle()
                    .fill(timeRemaining > 60 ? JuntoColors.pixGreen : JuntoColors.danger)
                    .frame(width: 8, height: 8)

                if timeRemaining > 0 {
                    Text("Pix válido por 5 minutos • Expira em")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)

                    Text(formattedTime)
                        .font(.inter(12, weight: .bold))
                        .foregroundColor(timeRemaining > 60 ? JuntoColors.textMain : JuntoColors.danger)
                        .monospacedDigit()
                } else {
                    Text("Tempo de 5 minutos expirado. Gere novamente.")
                        .font(.inter(12, weight: .medium))
                        .foregroundColor(JuntoColors.danger)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(JuntoColors.surfaceSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Valor em destaque
            Text(JuntoStore.formatBRL(data.amount))
                .font(.inter(26, weight: .medium))
                .foregroundColor(JuntoColors.primary)

            // Seletor de abas
            HStack(spacing: 8) {
                ForEach(PixTab.allCases, id: \.self) { tab in
                    let active = selectedTab == tab
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) { selectedTab = tab }
                    } label: {
                        Text(tab.rawValue)
                            .font(.inter(13, weight: .medium))
                            .foregroundColor(active ? .white : JuntoColors.textMain)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(active ? JuntoColors.primary : Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(active ? JuntoColors.primary : JuntoColors.border, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            if selectedTab == .qrCode {
                VStack(spacing: 8) {
                    Text("Aponte a câmera ou leitor Pix do seu banco")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)

                    Image(uiImage: generateQRCode(from: data.pixPayload))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .padding(10)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(JuntoColors.border, lineWidth: 1)
                        )
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Código Pix Copia e Cola:")
                        .font(.inter(12, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)

                    Text(data.pixPayload)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(JuntoColors.textMuted)
                        .lineLimit(3)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(JuntoColors.surfaceSubtle)
                        .cornerRadius(8)
                }
                .padding(.vertical, 8)
            }

            JuntoPillButton(
                title: copiedPayload ? "Código Pix copiado!" : "Copiar código Pix",
                icon: copiedPayload ? "checkmark" : "doc.on.doc"
            ) {
                UIPasteboard.general.string = data.pixPayload
                copiedPayload = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onCopy()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedPayload = false }
            }

            Button("Fechar") { dismiss() }
                .font(.inter(14, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
                .padding(.bottom, 6)
        }
        .padding(.horizontal, 20)
        .background(Color.white)
        .onAppear {
            timeRemaining = 300
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timer?.invalidate()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)
        if let outputImage = filter.outputImage,
           let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgimg)
        }
        return UIImage(systemName: "qrcode") ?? UIImage()
    }
}
