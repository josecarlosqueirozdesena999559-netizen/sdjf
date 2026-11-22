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
                .frame(width: 42, height: 5)
                .padding(.top, 10)

            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                Text("Pix Automático Juntô")
            }
            .font(.inter(12, weight: .bold))
            .foregroundColor(JuntoColors.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(JuntoColors.secondaryLight)
            .cornerRadius(20)

            VStack(spacing: 4) {
                Text(JuntoStore.formatBRL(data.amount))
                    .font(.inter(28, weight: .heavy))
                    .foregroundColor(JuntoColors.textMain)

                Text("\(data.title) • Para \(data.recipientName)")
                    .font(.inter(13, weight: .medium))
                    .foregroundColor(JuntoColors.textMuted)
            }

            // QR Code Real gerado via CoreImage
            Image(uiImage: generateQRCode(from: data.pixPayload))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 175, height: 175)
                .padding(14)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(JuntoColors.border, lineWidth: 1.2)
                )
                .cornerRadius(14)

            // Payload Copia e Cola
            Text(data.pixPayload)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(JuntoColors.textMuted)
                .lineLimit(2)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(JuntoColors.surfaceSubtle)
                .cornerRadius(8)

            VStack(spacing: 10) {
                JuntoPrimaryButton(title: "Copiar Código Pix", icon: "doc.on.doc.fill", color: JuntoColors.secondary) {
                    UIPasteboard.general.string = data.pixPayload
                    onCopy()
                    dismiss()
                }

                JuntoSecondaryButton(title: "Fechar") {
                    dismiss()
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 24)
        .background(JuntoColors.surface)
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
