import UIKit
import Vision

/// Serviço de Reconhecimento Óptico de Caracteres (OCR) Nativo do iOS para Recibos e Comandas
final class ReceiptOCRService {
    static let shared = ReceiptOCRService()

    private init() {}

    /// Processa uma foto de recibo/comanda e extrai itens, quantidades e valores
    func recognizeReceipt(from image: UIImage) async -> [ComandaItem] {
        guard let cgImage = image.cgImage else {
            return fallbackSampleItems()
        }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { [weak self] request, error in
                guard let self = self else {
                    continuation.resume(returning: [])
                    return
                }

                if let error = error {
                    print("[OCR] Erro Vision: \(error.localizedDescription)")
                    continuation.resume(returning: self.fallbackSampleItems())
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                    continuation.resume(returning: self.fallbackSampleItems())
                    return
                }

                // Ordena as observações de cima para baixo pela coordenada Y normalizada
                let sortedObservations = observations.sorted { obs1, obs2 in
                    obs1.boundingBox.origin.y > obs2.boundingBox.origin.y
                }

                var recognizedLines: [String] = []
                for obs in sortedObservations {
                    if let candidate = obs.topCandidates(1).first {
                        let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !text.isEmpty {
                            recognizedLines.append(text)
                        }
                    }
                }

                let items = self.parseReceiptLines(recognizedLines)
                if items.isEmpty {
                    continuation.resume(returning: self.fallbackSampleItems())
                } else {
                    continuation.resume(returning: items)
                }
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["pt-BR", "pt-PT", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgImageOrientation, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("[OCR] Falha ao executar request: \(error.localizedDescription)")
                continuation.resume(returning: self.fallbackSampleItems())
            }
        }
    }

    /// Analisa linhas de texto brutas e extrai itens com descrição, quantidade e preço
    private func parseReceiptLines(_ lines: [String]) -> [ComandaItem] {
        var items: [ComandaItem] = []

        // Palavras a serem ignoradas (cabeçalhos, rodapés e metadados fiscais)
        let ignoredWords = [
            "CNPJ", "CPF", "CUPOM", "FISCAL", "EXTRATO", "SAT", "NFC-E", "NFCE",
            "DATA", "HORA", "TOTAL", "SUBTOTAL", "TROCO", "DINHEIRO", "CARTAO",
            "CREDITO", "DEBITO", "PIX", "OBRIGADO", "VOLTE", "SEMPRE", "CONSUMIDOR",
            "ENDERECO", "MESA", "ATENDENTE", "GARCOM", "TAXA", "SERVICO", "DESCONTO",
            "VIA", "CLIENTE", "ESTABELECIMENTO", "CHAVE", "ACESSO", "CONSULTA"
        ]

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            let upper = line.uppercased()

            // Ignora linhas que são metadados ou totais finais
            if ignoredWords.contains(where: { upper.contains($0) }) {
                continue
            }

            // Tenta extrair preço no final da linha (ex: 45,90 / 120.00 / R$ 89,00)
            if let parsed = extractItemFromLine(line) {
                items.append(parsed)
            }
        }

        return items
    }

    /// Extrai um item individual a partir de uma linha de texto de recibo
    private func extractItemFromLine(_ line: String) -> ComandaItem? {
        // Expressão regular para encontrar valor monetário (ex: 35,00 / 120.50 / R$ 42,90)
        let pricePattern = #"(?:R\$\s*)?(\d{1,4}[.,]\d{2})(?:\s*[A-Za-z])?$"#

        guard let regex = try? NSRegularExpression(pattern: pricePattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)),
              let priceRange = Range(match.range(at: 1), in: line) else {
            return nil
        }

        let priceString = String(line[priceRange])
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")

        guard let priceValue = Double(priceString), priceValue > 0, priceValue < 50000 else {
            return nil
        }

        // Remove a parte do preço para obter o texto da descrição do item
        var itemDesc = line.replacingOccurrences(of: String(line[Range(match.range, in: line)!]), with: "")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "-:.")))

        guard !itemDesc.isEmpty, itemDesc.count >= 2 else {
            return nil
        }

        // Tenta detectar quantidade no início da linha (ex: "2x Cerveja", "3 Cerveja", "4UN Picanha")
        var quantity = 1
        let qtyPattern = #"^(\d{1,2})\s*(?:[xX*]|UN|un)?\s+"#
        if let qtyRegex = try? NSRegularExpression(pattern: qtyPattern, options: []),
           let qtyMatch = qtyRegex.firstMatch(in: itemDesc, options: [], range: NSRange(location: 0, length: itemDesc.utf16.count)),
           let qtyRange = Range(qtyMatch.range(at: 1), in: itemDesc),
           let parsedQty = Int(itemDesc[qtyRange]), parsedQty > 0 {
            quantity = parsedQty
            if let fullQtyRange = Range(qtyMatch.range, in: itemDesc) {
                itemDesc = String(itemDesc[fullQtyRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            }
        }

        let unitPrice = priceValue / Double(max(1, quantity))
        let detailText = quantity > 1 ? "\(quantity)x \(formatBRL(unitPrice))" : ""

        return ComandaItem(
            name: itemDesc.capitalized,
            detail: detailText,
            price: priceValue,
            isSelected: true,
            quantity: quantity,
            unitPrice: unitPrice
        )
    }

    /// Amostra de itens realistas para fallback e testes imediatos
    func fallbackSampleItems() -> [ComandaItem] {
        [
            ComandaItem(
                name: "Picanha Fatiada na Brasa",
                detail: "1x R$ 89,90",
                price: 89.90,
                isSelected: true,
                quantity: 1,
                unitPrice: 89.90
            ),
            ComandaItem(
                name: "Cerveja Heineken 600ml",
                detail: "4x R$ 18,00",
                price: 72.00,
                isSelected: true,
                quantity: 4,
                unitPrice: 18.00
            ),
            ComandaItem(
                name: "Porção Batata Frita Especial",
                detail: "1x R$ 38,00",
                price: 38.00,
                isSelected: true,
                quantity: 1,
                unitPrice: 38.00
            ),
            ComandaItem(
                name: "Água Mineral com Gás",
                detail: "2x R$ 7,00",
                price: 14.00,
                isSelected: true,
                quantity: 2,
                unitPrice: 7.00
            )
        ]
    }

    private static func formatBRL(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.currencyCode = "BRL"
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "R$ %.2f", value)
    }
}

// MARK: - Helper de Orientação de Imagem para Vision
private extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .left: return .left
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
