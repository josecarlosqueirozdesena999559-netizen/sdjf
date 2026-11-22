import SwiftUI
import CoreImage.CIFilterBuiltins

struct PixSheetView: View {
    let data: PixChargeSheetData
    let onCopy: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(JuntoColors.border)
                .frame(width: 40, height: 4)
                .padding(.top, 10)

            Text("Pagar com Pix")
                .font(.inter(18, weight: .regular))
                .foregroundColor(JuntoColors.textMain)

            VStack(spacing: 4) {
                Text(JuntoStore.formatBRL(data.amount))
                    .font(.inter(28, weight: .medium))
                    .foregroundColor(JuntoColors.primary)

                Text("\(data.title) • \(data.recipientName)")
                    .font(.inter(13, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
            }

            Image(uiImage: generateQRCode(from: data.pixPayload))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 170, height: 170)
                .padding(14)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(JuntoColors.border, lineWidth: 1)
                )

            Text(data.pixPayload)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(JuntoColors.textMuted)
                .lineLimit(2)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(JuntoColors.surfaceSubtle)
                .cornerRadius(8)

            JuntoPillButton(title: "Copiar código Pix", icon: "doc.on.doc") {
                UIPasteboard.general.string = data.pixPayload
                onCopy()
                dismiss()
            }

            Button("Fechar") { dismiss() }
                .font(.inter(14, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
                .padding(.bottom, 10)
        }
        .padding(.horizontal, 24)
        .background(Color.white)
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
