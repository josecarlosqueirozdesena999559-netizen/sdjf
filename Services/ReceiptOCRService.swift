import UIKit
import Vision

/// Serviço de Reconhecimento Óptico de Caracteres (OCR) Nativo do iOS para Recibos, Notas Fiscais (NFC-e/SAT) e Comandas Reais
final class ReceiptOCRService {
    static let shared = ReceiptOCRService()

    private init() {}

    /// Processa uma foto real de recibo/comanda agrupando observações por linha horizontal (2D) e extrai itens reais
    func recognizeReceipt(from image: UIImage) async -> [ComandaItem] {
        guard let cgImage = normalizedCGImage(from: image) else {
            return []
        }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { [weak self] request, error in
                guard let self = self else {
                    continuation.resume(returning: [])
                    return
                }

                if let error = error {
                    print("[OCR] Erro Vision: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                    continuation.resume(returning: [])
                    return
                }

                let rows = self.clusterObservationsIntoRows(observations)
                let items = self.parseReceiptRows(rows)
                continuation.resume(returning: items)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["pt-BR", "pt-PT", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("[OCR] Falha ao executar Vision OCR: \(error.localizedDescription)")
                continuation.resume(returning: [])
            }
        }
    }

    /// Normaliza a orientação da foto (evita que fotos tiradas na câmera fiquem rotacionadas para o Vision)
    private func normalizedCGImage(from image: UIImage) -> CGImage? {
        if image.imageOrientation == .up, let cg = image.cgImage {
            return cg
        }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        let normalized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        return normalized.cgImage ?? image.cgImage
    }

    private struct TextBox {
        let text: String
        let box: CGRect
        var midY: CGFloat { box.midY }
        var minX: CGFloat { box.minX }
        var height: CGFloat { max(box.height, 0.012) }
    }

    /// Agrupa caixas de texto que estão na mesma linha horizontal (esquerda = nome do produto, direita = valor R$)
    private func clusterObservationsIntoRows(_ observations: [VNRecognizedTextObservation]) -> [String] {
        var boxes: [TextBox] = []
        for obs in observations {
            guard let top = obs.topCandidates(1).first else { continue }
            let txt = top.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !txt.isEmpty else { continue }
            boxes.append(TextBox(text: txt, box: obs.boundingBox))
        }

        // Vision usa origem no canto inferior esquerdo: Y maior = mais no topo da imagem
        boxes.sort { $0.midY > $1.midY }

        var rows: [[TextBox]] = []
        for b in boxes {
            if let lastRowIdx = rows.indices.last {
                let rowRef = rows[lastRowIdx]
                let avgMidY = rowRef.map(\.midY).reduce(0, +) / CGFloat(rowRef.count)
                let avgHeight = rowRef.map(\.height).reduce(0, +) / CGFloat(rowRef.count)
                let tolerance = max(0.015, avgHeight * 0.62)
                if abs(b.midY - avgMidY) <= tolerance {
                    rows[lastRowIdx].append(b)
                    continue
                }
            }
            rows.append([b])
        }

        return rows.map { row in
            row.sorted { $0.minX < $1.minX }
                .map(\.text)
                .joined(separator: " ")
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /// Analisa linhas agrupadas reais de cupons fiscais, NFC-e, comandas e notas simples
    private func parseReceiptRows(_ rows: [String]) -> [ComandaItem] {
        let ignoredKeywords = [
            "CNPJ", "CPF", "CUPOM FISCAL", "EXTRATO", "NFC-E", "NFCE", "SAT",
            "VALOR TOTAL", "SUBTOTAL", "SUB-TOTAL", "TOTAL A PAGAR", "TOTAL R$",
            "TROCO", "DINHEIRO", "CARTAO", "CARTÃO", "CREDITO", "CRÉDITO",
            "DEBITO", "DÉBITO", "PIX", "OBRIGADO", "VOLTE SEMPRE", "CONSUMIDOR",
            "CHAVE DE ACESSO", "CONSULTA", "TRIBUTOS", "IMPOSTO", "ICMS",
            "PROTOCOLO", "AUTORIZACAO", "AUTORIZAÇÃO", "QTD. TOTAL", "QTDE TOTAL",
            "DESCONTO", "ACRESCIMO", "ACRÉSCIMO", "FORMA DE PAGAMENTO", "PAGAMENTO"
        ]

        var items: [ComandaItem] = []
        var pendingDescription: String? = nil

        for rawLine in rows {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard line.count >= 2 else { continue }
            let upper = line.uppercased()

            if isIgnoredMetadataLine(upper: upper, keywords: ignoredKeywords) {
                pendingDescription = nil
                continue
            }

            // Caso 1: Linha estilo NFC-e contendo cálculo explícito: "2 UN x 12,50 = 25,00" ou "3 x 8,00 24,00"
            if let mult = parseMultiplicationLine(line) {
                let desc = cleanDescription(mult.desc.isEmpty ? (pendingDescription ?? "") : mult.desc)
                if !desc.isEmpty {
                    let qty = max(1, mult.quantity)
                    let unit = mult.unitPrice > 0 ? mult.unitPrice : (mult.totalPrice / Double(qty))
                    let total = mult.totalPrice > 0 ? mult.totalPrice : (unit * Double(qty))
                    items.append(makeItem(name: desc, quantity: qty, unitPrice: unit, totalPrice: total))
                    pendingDescription = nil
                    continue
                }
            }

            // Caso 2: Linha completa com descrição + valor no final (ex: "2x Heineken 600ml 36,00" ou "Água Mineral 7,00")
            if let sameLine = extractItemFromSingleLine(line) {
                items.append(sameLine)
                pendingDescription = nil
                continue
            }

            // Caso 3: Linha contendo APENAS preço (ex: "R$ 45,90" ou "19,90") logo abaixo do nome do item
            if let onlyPrice = extractStandalonePrice(line), let prevDesc = pendingDescription {
                let cleaned = cleanDescription(prevDesc)
                if !cleaned.isEmpty {
                    let parsedQty = extractLeadingQuantity(from: cleaned)
                    let unit = onlyPrice / Double(max(1, parsedQty.quantity))
                    items.append(makeItem(name: parsedQty.cleanedName, quantity: parsedQty.quantity, unitPrice: unit, totalPrice: onlyPrice))
                    pendingDescription = nil
                    continue
                }
            }

            // Caso 4: Possível linha de descrição (sem preço), guardar para combinar com a linha seguinte
            if looksLikeItemDescription(line) {
                pendingDescription = line
            }
        }

        return items
    }

    private func isIgnoredMetadataLine(upper: String, keywords: [String]) -> Bool {
        if upper == "TOTAL" || upper.hasPrefix("TOTAL ") || upper.hasPrefix("TOTAL:") {
            return true
        }
        return keywords.contains(where: { upper.contains($0) })
    }

    private func parseMultiplicationLine(_ line: String) -> (desc: String, quantity: Int, unitPrice: Double, totalPrice: Double)? {
        // Exemplos: "2 UN x 6,50 13,00" | "3x 15,00 = 45,00" | "Cerveja 4 x 12,00 48,00"
        let pattern = #"^(.*?)(\d{1,3})(?:[.,]\d{1,3})?\s*(?:UN|UNID|PC|CX|KG|L|LT)?\s*[xX\*]\s*(?:R\$\s*)?(\d{1,4}[.,]\d{2})(?:\s*(?:=|\s)\s*(?:R\$\s*)?(\d{1,5}[.,]\d{2}))?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) else {
            return nil
        }

        let descRaw = Range(match.range(at: 1), in: line).map { String(line[$0]) } ?? ""
        guard let qtyRange = Range(match.range(at: 2), in: line),
              let unitRange = Range(match.range(at: 3), in: line),
              let qty = Int(line[qtyRange]), qty > 0, qty <= 500,
              let unit = parseMonetaryValue(String(line[unitRange])), unit > 0 else {
            return nil
        }

        var total = unit * Double(qty)
        if match.range(at: 4).location != NSNotFound,
           let totalRange = Range(match.range(at: 4), in: line),
           let parsedTotal = parseMonetaryValue(String(line[totalRange])), parsedTotal > 0 {
            total = parsedTotal
        }

        return (descRaw.trimmingCharacters(in: .whitespaces), qty, unit, total)
    }

    private func extractItemFromSingleLine(_ line: String) -> ComandaItem? {
        // Valor monetário brasileiro no fim da linha (ex: "12,90", "R$ 1.250,00", "45.90")
        let pricePattern = #"(?:R\$\s*)?(\d{1,3}(?:\.\d{3})*,\d{2}|\d{1,4}[.,]\d{2})(?:\s*[A-Za-z%]{1,3})?$"#
        guard let regex = try? NSRegularExpression(pattern: pricePattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)),
              let priceRange = Range(match.range(at: 1), in: line),
              let fullRange = Range(match.range, in: line),
              let priceValue = parseMonetaryValue(String(line[priceRange])),
              priceValue > 0, priceValue < 50000 else {
            return nil
        }

        let rawDesc = String(line[..<fullRange.lowerBound])
        let cleaned = cleanDescription(rawDesc)
        guard cleaned.count >= 2, cleaned.rangeOfCharacter(from: .letters) != nil else {
            return nil
        }

        let qtyParsed = extractLeadingQuantity(from: cleaned)
        let qty = max(1, qtyParsed.quantity)
        let unitPrice = priceValue / Double(qty)
        return makeItem(name: qtyParsed.cleanedName, quantity: qty, unitPrice: unitPrice, totalPrice: priceValue)
    }

    private func extractStandalonePrice(_ line: String) -> Double? {
        let pattern = #"^(?:R\$\s*)?(\d{1,3}(?:\.\d{3})*,\d{2}|\d{1,4}[.,]\d{2})$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)),
              let r = Range(match.range(at: 1), in: line),
              let val = parseMonetaryValue(String(line[r])),
              val > 0, val < 50000 else {
            return nil
        }
        return val
    }

    private func looksLikeItemDescription(_ line: String) -> Bool {
        let cleaned = cleanDescription(line)
        guard cleaned.count >= 3, cleaned.count <= 65 else { return false }
        guard cleaned.rangeOfCharacter(from: .letters) != nil else { return false }
        // Evita datas, horários e telefones como descrição
        if cleaned.range(of: #"^\d{2}/\d{2}/\d{2,4}"#, options: .regularExpression) != nil { return false }
        if cleaned.range(of: #"^\d{2}:\d{2}"#, options: .regularExpression) != nil { return false }
        return true
    }

    private func extractLeadingQuantity(from text: String) -> (quantity: Int, cleanedName: String) {
        let pattern = #"^(\d{1,2})\s*(?:[xX\*]|UN|un)?\s+(.+)$"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: text.utf16.count)),
           let qRange = Range(match.range(at: 1), in: text),
           let nRange = Range(match.range(at: 2), in: text),
           let q = Int(text[qRange]), q > 0, q <= 99 {
            return (q, String(text[nRange]).trimmingCharacters(in: .whitespaces))
        }
        return (1, text)
    }

    private func cleanDescription(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // Remove código sequencial de cupom (ex: "001 ", "002 ") e código de barras EAN (8-14 dígitos)
        s = s.replacingOccurrences(of: #"^\d{1,3}\s+\d{7,14}\s+"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"^\d{7,14}\s+"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"^0\d{2}\s+"#, with: "", options: .regularExpression)
        s = s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "-:.*=|")))
        return s
    }

    private func parseMonetaryValue(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        if trimmed.contains(",") {
            let normalized = trimmed
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: ".")
            return Double(normalized)
        }
        return Double(trimmed)
    }

    private func makeItem(name: String, quantity: Int, unitPrice: Double, totalPrice: Double) -> ComandaItem {
        let displayName = name.prefix(1).uppercased() + name.dropFirst().lowercased()
        let detail = quantity > 1 ? "\(quantity)x \(formatBRL(unitPrice))" : ""
        return ComandaItem(
            name: displayName,
            detail: detail,
            price: totalPrice,
            isSelected: true,
            quantity: quantity,
            unitPrice: unitPrice
        )
    }

    private func formatBRL(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.currencyCode = "BRL"
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "R$ %.2f", value)
    }
}
