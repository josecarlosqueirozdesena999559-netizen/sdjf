import UIKit
import Foundation

/// Gerador nativo de Relatórios PDF do Juntô Pro (UIGraphicsPDFRenderer — 100% offline/nativo no iOS)
enum JuntoProPDFGenerator {

    /// Gera PDF completo de "Meus gastos" para o período selecionado
    static func generateExpensesReportPDF(
        userName: String,
        periodLabel: String,
        totalAmount: Double,
        paidAmount: Double,
        pendingAmount: Double,
        items: [PersonalExpenseRecord]
    ) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let safePeriod = periodLabel
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Junto_Relatorio_Gastos_\(safePeriod).pdf")

        let primaryColor = UIColor(red: 20/255, green: 33/255, blue: 61/255, alpha: 1) // #14213D
        let greenColor = UIColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 1)
        let orangeColor = UIColor(red: 234/255, green: 88/255, blue: 12/255, alpha: 1)
        let mutedColor = UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1)
        let dividerColor = UIColor(red: 229/255, green: 231/255, blue: 235/255, alpha: 1)

        let df = DateFormatter()
        df.locale = Locale(identifier: "pt_BR")
        df.dateFormat = "dd/MM/yyyy 'às' HH:mm"
        let generatedAt = df.string(from: Date())

        do {
            try renderer.writePDF(to: fileURL) { ctx in
                ctx.beginPage()
                var y: CGFloat = 44
                let left: CGFloat = 42
                let width: CGFloat = pageRect.width - (left * 2)

                // Cabeçalho Juntô Pro
                let brandAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                    .foregroundColor: primaryColor
                ]
                ("Juntô Pro — Relatório de Gastos" as NSString).draw(at: CGPoint(x: left, y: y), withAttributes: brandAttrs)
                y += 30

                let metaAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                    .foregroundColor: mutedColor
                ]
                ("Titular: \(userName)  ·  Período: \(periodLabel)  ·  Emitido em \(generatedAt)" as NSString)
                    .draw(at: CGPoint(x: left, y: y), withAttributes: metaAttrs)
                y += 26

                drawLine(ctx: ctx.cgContext, x: left, y: y, width: width, color: dividerColor)
                y += 20

                // Resumo Financeiro
                let colW = width / 3
                drawSummaryColumn(title: "Total gasto", value: formatBRL(totalAmount), color: primaryColor, x: left, y: y)
                drawSummaryColumn(title: "Já pago", value: formatBRL(paidAmount), color: greenColor, x: left + colW, y: y)
                drawSummaryColumn(title: "Falta pagar", value: formatBRL(pendingAmount), color: pendingAmount > 0 ? orangeColor : mutedColor, x: left + colW * 2, y: y)
                y += 58

                drawLine(ctx: ctx.cgContext, x: left, y: y, width: width, color: dividerColor)
                y += 22

                let secAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                    .foregroundColor: primaryColor
                ]
                ("Detalhamento dos pagamentos (\(items.count))" as NSString).draw(at: CGPoint(x: left, y: y), withAttributes: secAttrs)
                y += 26

                if items.isEmpty {
                    ("Nenhum pagamento registrado neste período." as NSString).draw(at: CGPoint(x: left, y: y), withAttributes: metaAttrs)
                } else {
                    for item in items {
                        if y > pageRect.height - 70 {
                            ctx.beginPage()
                            y = 44
                        }
                        let titleAttrs: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 12.5, weight: .semibold),
                            .foregroundColor: primaryColor
                        ]
                        let subAttrs: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                            .foregroundColor: mutedColor
                        ]
                        let valAttrs: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 12.5, weight: .bold),
                            .foregroundColor: item.isPaid ? greenColor : orangeColor
                        ]

                        ("\(item.title) — \(item.groupName)" as NSString).draw(at: CGPoint(x: left, y: y), withAttributes: titleAttrs)

                        let valStr = "\(formatBRL(item.amount)) (\(item.isPaid ? "Pago" : "Pendente"))" as NSString
                        let valSize = valStr.size(withAttributes: valAttrs)
                        valStr.draw(at: CGPoint(x: left + width - valSize.width, y: y), withAttributes: valAttrs)
                        y += 17

                        ("\(item.category) · \(item.dateText)" as NSString).draw(at: CGPoint(x: left, y: y), withAttributes: subAttrs)
                        y += 18

                        drawLine(ctx: ctx.cgContext, x: left, y: y, width: width, color: dividerColor)
                        y += 10
                    }
                }
            }
            return fileURL
        } catch {
            return nil
        }
    }

    /// Gera PDF de fechamento oficial de um grupo (membros, cotas pagas/pendentes e despesas)
    static func generateGroupClosurePDF(group: RoleGroup, ownerPixKey: String) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let safeTitle = group.title
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Junto_Fechamento_\(safeTitle).pdf")

        let primaryColor = UIColor(red: 20/255, green: 33/255, blue: 61/255, alpha: 1)
        let greenColor = UIColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 1)
        let orangeColor = UIColor(red: 234/255, green: 88/255, blue: 12/255, alpha: 1)
        let mutedColor = UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1)
        let dividerColor = UIColor(red: 229/255, green: 231/255, blue: 235/255, alpha: 1)

        let df = DateFormatter()
        df.locale = Locale(identifier: "pt_BR")
        df.dateFormat = "dd/MM/yyyy 'às' HH:mm"

        do {
            try renderer.writePDF(to: fileURL) { ctx in
                ctx.beginPage()
                var y: CGFloat = 44
                let left: CGFloat = 42
                let width: CGFloat = pageRect.width - (left * 2)

                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                    .foregroundColor: primaryColor
                ]
                ("Fechamento do Grupo: \(group.title)" as NSString).draw(at: CGPoint(x: left, y: y), withAttributes: titleAttrs)
                y += 30

                let metaAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                    .foregroundColor: mutedColor
                ]
                ("Categoria: \(group.category)  ·  \(group.participants.count) participantes  ·  Emitido em \(df.string(from: Date()))" as NSString)
                    .draw(at: CGPoint(x: left, y: y), withAttributes: metaAttrs)
                y += 18
                if !ownerPixKey.isEmpty {
                    ("Chave Pix do organizador: \(ownerPixKey)" as NSString).draw(at: CGPoint(x: left, y: y), withAttributes: metaAttrs)
                    y += 22
                }

                drawLine(ctx: ctx.cgContext, x: left, y: y, width: width, color: dividerColor)
                y += 20

                let colW = width / 3
                drawSummaryColumn(title: "Meta do pote", value: formatBRL(group.potTarget), color: primaryColor, x: left, y: y)
                drawSummaryColumn(title: "Arrecadado", value: formatBRL(group.potBalance), color: greenColor, x: left + colW, y: y)
                drawSummaryColumn(title: "Total gasto", value: formatBRL(group.totalSpent), color: primaryColor, x: left + colW * 2, y: y)
                y += 58

                drawLine(ctx: ctx.cgContext, x: left, y: y, width: width, color: dividerColor)
                y += 22

                let secAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                    .foregroundColor: primaryColor
                ]
                ("Status dos participantes" as NSString).draw(at: CGPoint(x: left, y: y), withAttributes: secAttrs)
                y += 24

                for p in group.participants {
                    let nameAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 12.5, weight: .medium),
                        .foregroundColor: primaryColor
                    ]
                    let statusText = p.hasPaid
                        ? "Pago (\(formatBRL(p.quotaAmount)))"
                        : "Pendente (\(formatBRL(p.quotaAmount)))"
                    let statusAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                        .foregroundColor: p.hasPaid ? greenColor : orangeColor
                    ]

                    (p.name as NSString).draw(at: CGPoint(x: left, y: y), withAttributes: nameAttrs)
                    let sz = (statusText as NSString).size(withAttributes: statusAttrs)
                    (statusText as NSString).draw(at: CGPoint(x: left + width - sz.width, y: y), withAttributes: statusAttrs)
                    y += 20
                    drawLine(ctx: ctx.cgContext, x: left, y: y, width: width, color: dividerColor)
                    y += 10
                }
            }
            return fileURL
        } catch {
            return nil
        }
    }

    private static func drawSummaryColumn(title: String, value: String, color: UIColor, x: CGFloat, y: CGFloat) {
        let lblAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1)
        ]
        let valAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: color
        ]
        (title as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: lblAttrs)
        (value as NSString).draw(at: CGPoint(x: x, y: y + 17), withAttributes: valAttrs)
    }

    private static func drawLine(ctx: CGContext, x: CGFloat, y: CGFloat, width: CGFloat, color: UIColor) {
        ctx.saveGState()
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(0.8)
        ctx.move(to: CGPoint(x: x, y: y))
        ctx.addLine(to: CGPoint(x: x + width, y: y))
        ctx.strokePath()
        ctx.restoreGState()
    }

    private static func formatBRL(_ value: Double) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.numberStyle = .currency
        f.currencyCode = "BRL"
        return f.string(from: NSNumber(value: value)) ?? String(format: "R$ %.2f", value)
    }
}
