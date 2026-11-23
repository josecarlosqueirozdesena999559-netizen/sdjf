import SwiftUI

// ============================================================
// MARK: - Juntô Custom Icon System
// Ícones vetoriais desenhados à mão — estilo app premium (Nubank, N26, PicPay).
// Nunca use SF Symbols nas áreas principais. Use JuntoIcon() em todo o app.
// ============================================================

/// Enum central de todos os ícones do sistema Juntô.
enum JuntoIconKind {
    // ── Navegação (Tab Bar) ──────────────────────────────
    case tabFriends
    case tabGroups
    case tabActivity
    // ── Ações gerais ────────────────────────────────────
    case plus
    case addPerson
    case checkmark
    case close
    case chevronRight
    case chevronLeft
    case send
    case edit
    case trash
    case search
    case share
    case link
    case mic
    case camera
    case photo
    case bell
    case bellOff
    case eye
    case eyeOff
    case info
    case warn
    case qrCode
    case crown
    case shield
    case shieldOff
    case block
    case play
    case pause
    case sparkle
    case ellipsis
    case swipeReply
    // ── Financeiro / Dinheiro ────────────────────────────
    case pix
    case wallet
    case coin
    case chartPie
    case chartBar
    case dollarSign
    case receipt
    case splitBill
    case checkPaid
    case alertSpend
    // ── Categorias de Grupo ──────────────────────────────
    case catTravel        // Viagem
    case catBBQ           // Churrasco
    case catBar           // Bar & Drinks
    case catHome          // Casa
    case catCouple        // Casal
    case catParty         // Festa
    case catSport         // Esporte
    case catGift          // Presente
    case catWork          // Trabalho
    // ── Conta / Perfil ───────────────────────────────────
    case person
    case personGroup
    case lock
    case docText
    case logout
    case inviteQR
    case inviteFriends
}

/// View de ícone com tamanho e cor configuráveis.
struct JuntoIcon: View {
    let kind: JuntoIconKind
    var size: CGFloat = 22
    var color: Color = JuntoColors.textMain
    var weight: CGFloat = 1.6   // espessura padrão das linhas stroke

    var body: some View {
        Canvas { ctx, sz in
            draw(ctx: ctx, sz: sz)
        }
        .frame(width: size, height: size)
        .foregroundColor(color)
    }

    // ── Despachante ─────────────────────────────────────
    private func draw(ctx: GraphicsContext, sz: CGSize) {
        let w = sz.width, h = sz.height
        let s = min(w, h)
        var c = ctx
        c.stroke(Path { _ in }, with: .foreground) // define cor base

        switch kind {

        // ═══════════════════════════════════════════════
        // TAB BAR
        // ═══════════════════════════════════════════════

        case .tabFriends:
            // Pessoa: círculo cabeça + meio-elipse corpo
            let headR: CGFloat = s * 0.19
            let headCY = s * 0.33
            c.stroke(
                Path { p in
                    p.addEllipse(in: CGRect(x: w/2-headR, y: headCY-headR, width: headR*2, height: headR*2))
                },
                with: .foreground,
                lineWidth: weight
            )
            c.stroke(
                Path { p in
                    // corpo — arco semi-elipse inferior
                    let bY = headCY + headR + s * 0.045
                    let bW = s * 0.46
                    let bH = s * 0.26
                    p.move(to: CGPoint(x: w/2 - bW/2, y: bY + bH))
                    p.addCurve(
                        to: CGPoint(x: w/2 + bW/2, y: bY + bH),
                        control1: CGPoint(x: w/2 - bW/2, y: bY),
                        control2: CGPoint(x: w/2 + bW/2, y: bY)
                    )
                },
                with: .foreground,
                lineWidth: weight
            )

        case .tabGroups:
            // Dois perfis sobrepostos
            let r1: CGFloat = s * 0.16
            let cx1 = w * 0.37, cx2 = w * 0.60
            let hy: CGFloat = s * 0.30
            for cx in [cx1, cx2] {
                c.stroke(
                    Path { p in p.addEllipse(in: CGRect(x: cx-r1, y: hy-r1, width: r1*2, height: r1*2)) },
                    with: .foreground, lineWidth: weight
                )
            }
            let bY1 = hy + r1 + s * 0.04
            let bW1 = s * 0.36, bH1 = s * 0.22
            for cx in [cx1, cx2] {
                c.stroke(
                    Path { p in
                        p.move(to: CGPoint(x: cx - bW1/2, y: bY1 + bH1))
                        p.addCurve(
                            to: CGPoint(x: cx + bW1/2, y: bY1 + bH1),
                            control1: CGPoint(x: cx - bW1/2, y: bY1),
                            control2: CGPoint(x: cx + bW1/2, y: bY1)
                        )
                    },
                    with: .foreground, lineWidth: weight
                )
            }

        case .tabActivity:
            // Duas setas opostas (↔) em círculo
            let r = s * 0.36
            c.stroke(
                Path { p in p.addEllipse(in: CGRect(x: w/2-r, y: h/2-r, width: r*2, height: r*2)) },
                with: .foreground, lineWidth: weight
            )
            // Seta esquerda →
            let arrowY = h * 0.44
            let ax1 = w * 0.29, ax2 = w * 0.52
            c.stroke(Path { p in
                p.move(to: CGPoint(x: ax1, y: arrowY))
                p.addLine(to: CGPoint(x: ax2, y: arrowY))
                p.move(to: CGPoint(x: ax2 - s*0.08, y: arrowY - s*0.07))
                p.addLine(to: CGPoint(x: ax2, y: arrowY))
                p.addLine(to: CGPoint(x: ax2 - s*0.08, y: arrowY + s*0.07))
            }, with: .foreground, lineWidth: weight)
            // Seta direita ←
            let arrowY2 = h * 0.60
            let bx1 = w * 0.48, bx2 = w * 0.71
            c.stroke(Path { p in
                p.move(to: CGPoint(x: bx2, y: arrowY2))
                p.addLine(to: CGPoint(x: bx1, y: arrowY2))
                p.move(to: CGPoint(x: bx1 + s*0.08, y: arrowY2 - s*0.07))
                p.addLine(to: CGPoint(x: bx1, y: arrowY2))
                p.addLine(to: CGPoint(x: bx1 + s*0.08, y: arrowY2 + s*0.07))
            }, with: .foreground, lineWidth: weight)

        // ═══════════════════════════════════════════════
        // AÇÕES GERAIS
        // ═══════════════════════════════════════════════

        case .plus:
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.5, y: h*0.18))
                p.addLine(to: CGPoint(x: w*0.5, y: h*0.82))
                p.move(to: CGPoint(x: w*0.18, y: h*0.5))
                p.addLine(to: CGPoint(x: w*0.82, y: h*0.5))
            }, with: .foreground, lineWidth: weight)

        case .addPerson:
            // Silhueta + plus
            let hR = s * 0.18
            let hCY = s * 0.30
            c.stroke(Path { p in
                p.addEllipse(in: CGRect(x: w*0.25-hR, y: hCY-hR, width: hR*2, height: hR*2))
            }, with: .foreground, lineWidth: weight)
            c.stroke(Path { p in
                let bY = hCY + hR + s*0.04
                let bW = s*0.4, bH = s*0.24
                p.move(to: CGPoint(x: w*0.25 - bW/2, y: bY + bH))
                p.addCurve(to: CGPoint(x: w*0.25 + bW/2, y: bY + bH),
                           control1: CGPoint(x: w*0.25 - bW/2, y: bY),
                           control2: CGPoint(x: w*0.25 + bW/2, y: bY))
            }, with: .foreground, lineWidth: weight)
            // plus direita
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.72, y: h*0.42))
                p.addLine(to: CGPoint(x: w*0.72, y: h*0.76))
                p.move(to: CGPoint(x: w*0.56, y: h*0.59))
                p.addLine(to: CGPoint(x: w*0.88, y: h*0.59))
            }, with: .foreground, lineWidth: weight)

        case .checkmark:
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.17, y: h*0.52))
                p.addLine(to: CGPoint(x: w*0.42, y: h*0.76))
                p.addLine(to: CGPoint(x: w*0.83, y: h*0.26))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .close:
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.22, y: h*0.22))
                p.addLine(to: CGPoint(x: w*0.78, y: h*0.78))
                p.move(to: CGPoint(x: w*0.78, y: h*0.22))
                p.addLine(to: CGPoint(x: w*0.22, y: h*0.78))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round))

        case .chevronRight:
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.33, y: h*0.22))
                p.addLine(to: CGPoint(x: w*0.67, y: h*0.5))
                p.addLine(to: CGPoint(x: w*0.33, y: h*0.78))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .chevronLeft:
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.67, y: h*0.22))
                p.addLine(to: CGPoint(x: w*0.33, y: h*0.5))
                p.addLine(to: CGPoint(x: w*0.67, y: h*0.78))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .send:
            // Avião de papel moderno
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.14, y: h*0.5))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.22))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.78))
                p.addLine(to: CGPoint(x: w*0.14, y: h*0.5))
                p.move(to: CGPoint(x: w*0.14, y: h*0.5))
                p.addLine(to: CGPoint(x: w*0.56, y: h*0.5))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .edit:
            // Lápis
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.72, y: h*0.14))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.28))
                p.addLine(to: CGPoint(x: w*0.30, y: h*0.76))
                p.addLine(to: CGPoint(x: w*0.14, y: h*0.76))
                p.addLine(to: CGPoint(x: w*0.14, y: h*0.86))
                p.addLine(to: CGPoint(x: w*0.14, y: h*0.76))
                p.addLine(to: CGPoint(x: w*0.72, y: h*0.14))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .trash:
            // Lixeira moderna
            c.stroke(Path { p in
                // Tampa
                p.move(to: CGPoint(x: w*0.17, y: h*0.30))
                p.addLine(to: CGPoint(x: w*0.83, y: h*0.30))
                // Cabo da tampa
                p.move(to: CGPoint(x: w*0.38, y: h*0.30))
                p.addLine(to: CGPoint(x: w*0.38, y: h*0.18))
                p.addLine(to: CGPoint(x: w*0.62, y: h*0.18))
                p.addLine(to: CGPoint(x: w*0.62, y: h*0.30))
                // Corpo
                p.move(to: CGPoint(x: w*0.26, y: h*0.30))
                p.addLine(to: CGPoint(x: w*0.30, y: h*0.84))
                p.addLine(to: CGPoint(x: w*0.70, y: h*0.84))
                p.addLine(to: CGPoint(x: w*0.74, y: h*0.30))
                // Linhas internas
                p.move(to: CGPoint(x: w*0.42, y: h*0.40))
                p.addLine(to: CGPoint(x: w*0.42, y: h*0.74))
                p.move(to: CGPoint(x: w*0.58, y: h*0.40))
                p.addLine(to: CGPoint(x: w*0.58, y: h*0.74))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .search:
            let sr = s * 0.30
            let scx = w*0.42, scy = h*0.42
            c.stroke(Path { p in
                p.addEllipse(in: CGRect(x: scx-sr, y: scy-sr, width: sr*2, height: sr*2))
            }, with: .foreground, lineWidth: weight)
            c.stroke(Path { p in
                let angle = CGFloat.pi * 0.75
                p.move(to: CGPoint(x: scx + sr * cos(angle), y: scy + sr * sin(angle)))
                p.addLine(to: CGPoint(x: w*0.82, y: h*0.82))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round))

        case .share:
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.5, y: h*0.14))
                p.addLine(to: CGPoint(x: w*0.5, y: h*0.68))
                p.move(to: CGPoint(x: w*0.5, y: h*0.14))
                p.addLine(to: CGPoint(x: w*0.30, y: h*0.34))
                p.move(to: CGPoint(x: w*0.5, y: h*0.14))
                p.addLine(to: CGPoint(x: w*0.70, y: h*0.34))
                // base
                p.move(to: CGPoint(x: w*0.20, y: h*0.68))
                p.addLine(to: CGPoint(x: w*0.20, y: h*0.86))
                p.addLine(to: CGPoint(x: w*0.80, y: h*0.86))
                p.addLine(to: CGPoint(x: w*0.80, y: h*0.68))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .link:
            c.stroke(Path { p in
                // Elo superior
                let r: CGFloat = s * 0.17
                p.move(to: CGPoint(x: w*0.56, y: h*0.30))
                p.addArc(center: CGPoint(x: w*0.65, y: h*0.35), radius: r,
                         startAngle: .degrees(220), endAngle: .degrees(60), clockwise: false)
                p.move(to: CGPoint(x: w*0.44, y: h*0.70))
                p.addArc(center: CGPoint(x: w*0.35, y: h*0.65), radius: r,
                         startAngle: .degrees(40), endAngle: .degrees(240), clockwise: false)
                // Linha central
                p.move(to: CGPoint(x: w*0.38, y: h*0.62))
                p.addLine(to: CGPoint(x: w*0.62, y: h*0.38))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round))

        case .mic:
            // Microfone
            let mw = s*0.26, mh = s*0.40, mx = w*0.5-mw/2, my = h*0.10
            c.stroke(Path { p in
                p.addRoundedRect(in: CGRect(x: mx, y: my, width: mw, height: mh),
                                 cornerSize: CGSize(width: mw/2, height: mw/2))
            }, with: .foreground, lineWidth: weight)
            c.stroke(Path { p in
                // Arco externo
                p.move(to: CGPoint(x: w*0.22, y: h*0.44))
                p.addArc(center: CGPoint(x: w*0.5, y: h*0.44), radius: s*0.28,
                         startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
                // Linha central
                p.move(to: CGPoint(x: w*0.5, y: h*0.44 + s*0.28))
                p.addLine(to: CGPoint(x: w*0.5, y: h*0.86))
                p.move(to: CGPoint(x: w*0.33, y: h*0.86))
                p.addLine(to: CGPoint(x: w*0.67, y: h*0.86))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round))

        case .camera:
            c.stroke(Path { p in
                // Corpo
                p.addRoundedRect(in: CGRect(x: w*0.10, y: h*0.30, width: w*0.80, height: h*0.52),
                                 cornerSize: CGSize(width: s*0.08, height: s*0.08))
                // "Orelha" superior
                p.move(to: CGPoint(x: w*0.33, y: h*0.30))
                p.addLine(to: CGPoint(x: w*0.38, y: h*0.18))
                p.addLine(to: CGPoint(x: w*0.62, y: h*0.18))
                p.addLine(to: CGPoint(x: w*0.67, y: h*0.30))
                // Lente
                p.addEllipse(in: CGRect(x: w*0.36, y: h*0.37, width: s*0.28, height: s*0.28))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .photo:
            c.stroke(Path { p in
                p.addRoundedRect(in: CGRect(x: w*0.10, y: h*0.14, width: w*0.80, height: h*0.72),
                                 cornerSize: CGSize(width: s*0.08, height: s*0.08))
                // Sol / montanha
                p.move(to: CGPoint(x: w*0.14, y: h*0.68))
                p.addLine(to: CGPoint(x: w*0.38, y: h*0.46))
                p.addLine(to: CGPoint(x: w*0.56, y: h*0.60))
                p.addLine(to: CGPoint(x: w*0.70, y: h*0.50))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.68))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))
            c.stroke(Path { p in
                p.addEllipse(in: CGRect(x: w*0.56, y: h*0.26, width: s*0.16, height: s*0.16))
            }, with: .foreground, lineWidth: weight)

        case .bell:
            c.stroke(Path { p in
                // Sino
                p.move(to: CGPoint(x: w*0.26, y: h*0.70))
                p.addLine(to: CGPoint(x: w*0.74, y: h*0.70))
                p.addCurve(to: CGPoint(x: w*0.26, y: h*0.70),
                           control1: CGPoint(x: w*0.78, y: h*0.42),
                           control2: CGPoint(x: w*0.22, y: h*0.42))
                // Haste
                p.move(to: CGPoint(x: w*0.5, y: h*0.14))
                p.addLine(to: CGPoint(x: w*0.5, y: h*0.26))
                // Badalo
                p.move(to: CGPoint(x: w*0.40, y: h*0.70))
                p.addArc(center: CGPoint(x: w*0.5, y: h*0.70), radius: s*0.10,
                         startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .bellOff:
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.26, y: h*0.70))
                p.addLine(to: CGPoint(x: w*0.74, y: h*0.70))
                p.addCurve(to: CGPoint(x: w*0.26, y: h*0.70),
                           control1: CGPoint(x: w*0.78, y: h*0.42),
                           control2: CGPoint(x: w*0.22, y: h*0.42))
                p.move(to: CGPoint(x: w*0.14, y: h*0.14))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.86))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round))

        case .eye:
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.10, y: h*0.5))
                p.addCurve(to: CGPoint(x: w*0.90, y: h*0.5),
                           control1: CGPoint(x: w*0.3, y: h*0.18),
                           control2: CGPoint(x: w*0.7, y: h*0.18))
                p.addCurve(to: CGPoint(x: w*0.10, y: h*0.5),
                           control1: CGPoint(x: w*0.7, y: h*0.82),
                           control2: CGPoint(x: w*0.3, y: h*0.82))
                p.addEllipse(in: CGRect(x: w*0.38, y: h*0.36, width: s*0.24, height: s*0.24))
            }, with: .foreground, lineWidth: weight)

        case .eyeOff:
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.14, y: h*0.14))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.86))
                p.move(to: CGPoint(x: w*0.26, y: h*0.46))
                p.addCurve(to: CGPoint(x: w*0.90, y: h*0.5),
                           control1: CGPoint(x: w*0.3, y: h*0.26),
                           control2: CGPoint(x: w*0.7, y: h*0.22))
                p.move(to: CGPoint(x: w*0.74, y: h*0.62))
                p.addCurve(to: CGPoint(x: w*0.10, y: h*0.5),
                           control1: CGPoint(x: w*0.72, y: h*0.76),
                           control2: CGPoint(x: w*0.30, y: h*0.78))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round))

        case .info:
            c.stroke(Path { p in
                p.addEllipse(in: CGRect(x: w*0.14, y: h*0.14, width: s*0.72, height: s*0.72))
                p.move(to: CGPoint(x: w*0.5, y: h*0.44))
                p.addLine(to: CGPoint(x: w*0.5, y: h*0.70))
                p.addEllipse(in: CGRect(x: w*0.44, y: h*0.28, width: s*0.12, height: s*0.12))
            }, with: .foreground, lineWidth: weight)

        case .warn:
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.5, y: h*0.12))
                p.addLine(to: CGPoint(x: w*0.90, y: h*0.84))
                p.addLine(to: CGPoint(x: w*0.10, y: h*0.84))
                p.closeSubpath()
                p.move(to: CGPoint(x: w*0.5, y: h*0.40))
                p.addLine(to: CGPoint(x: w*0.5, y: h*0.62))
                p.addEllipse(in: CGRect(x: w*0.44, y: h*0.70, width: s*0.12, height: s*0.12))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .qrCode:
            // QR Code minimalista (3 cantos + linhas de dados)
            let q: CGFloat = s * 0.26
            for (ox, oy) in [(w*0.14, h*0.14), (w*0.60, h*0.14), (w*0.14, h*0.60)] {
                c.stroke(Path { p in
                    p.addRect(CGRect(x: ox, y: oy, width: q, height: q))
                    p.addRect(CGRect(x: ox+q*0.22, y: oy+q*0.22, width: q*0.56, height: q*0.56))
                }, with: .foreground, lineWidth: weight - 0.4)
            }
            // Dados
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.62, y: h*0.62))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.62))
                p.move(to: CGPoint(x: w*0.62, y: h*0.74))
                p.addLine(to: CGPoint(x: w*0.74, y: h*0.74))
                p.move(to: CGPoint(x: w*0.78, y: h*0.74))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.74))
                p.move(to: CGPoint(x: w*0.62, y: h*0.86))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.86))
                p.move(to: CGPoint(x: w*0.62, y: h*0.74))
                p.addLine(to: CGPoint(x: w*0.62, y: h*0.86))
            }, with: .foreground, lineWidth: weight - 0.4)

        case .crown:
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.14, y: h*0.70))
                p.addLine(to: CGPoint(x: w*0.26, y: h*0.36))
                p.addLine(to: CGPoint(x: w*0.5, y: h*0.58))
                p.addLine(to: CGPoint(x: w*0.74, y: h*0.26))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.58))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.70))
                p.addLine(to: CGPoint(x: w*0.14, y: h*0.70))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .shield:
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.5, y: h*0.12))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.26))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.52))
                p.addCurve(to: CGPoint(x: w*0.5, y: h*0.90),
                           control1: CGPoint(x: w*0.86, y: h*0.76),
                           control2: CGPoint(x: w*0.70, y: h*0.86))
                p.addCurve(to: CGPoint(x: w*0.14, y: h*0.52),
                           control1: CGPoint(x: w*0.30, y: h*0.86),
                           control2: CGPoint(x: w*0.14, y: h*0.76))
                p.addLine(to: CGPoint(x: w*0.14, y: h*0.26))
                p.closeSubpath()
                // Check interno
                p.move(to: CGPoint(x: w*0.33, y: h*0.52))
                p.addLine(to: CGPoint(x: w*0.46, y: h*0.65))
                p.addLine(to: CGPoint(x: w*0.68, y: h*0.40))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .shieldOff:
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.5, y: h*0.12))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.26))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.52))
                p.addCurve(to: CGPoint(x: w*0.5, y: h*0.90),
                           control1: CGPoint(x: w*0.86, y: h*0.76),
                           control2: CGPoint(x: w*0.70, y: h*0.86))
                p.addCurve(to: CGPoint(x: w*0.14, y: h*0.52),
                           control1: CGPoint(x: w*0.30, y: h*0.86),
                           control2: CGPoint(x: w*0.14, y: h*0.76))
                p.addLine(to: CGPoint(x: w*0.14, y: h*0.26))
                p.closeSubpath()
                // Slash
                p.move(to: CGPoint(x: w*0.30, y: h*0.30))
                p.addLine(to: CGPoint(x: w*0.70, y: h*0.70))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .block:
            c.stroke(Path { p in
                p.addEllipse(in: CGRect(x: w*0.14, y: h*0.14, width: s*0.72, height: s*0.72))
                p.move(to: CGPoint(x: w*0.26, y: h*0.26))
                p.addLine(to: CGPoint(x: w*0.74, y: h*0.74))
            }, with: .foreground, lineWidth: weight)

        case .play:
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.26, y: h*0.18))
                p.addLine(to: CGPoint(x: w*0.82, y: h*0.5))
                p.addLine(to: CGPoint(x: w*0.26, y: h*0.82))
                p.closeSubpath()
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .pause:
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.33, y: h*0.22))
                p.addLine(to: CGPoint(x: w*0.33, y: h*0.78))
                p.move(to: CGPoint(x: w*0.67, y: h*0.22))
                p.addLine(to: CGPoint(x: w*0.67, y: h*0.78))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round))

        case .sparkle:
            // Estrela 4 pontas + pontos satélite
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.5, y: h*0.14))
                p.addLine(to: CGPoint(x: w*0.56, y: h*0.44))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.5))
                p.addLine(to: CGPoint(x: w*0.56, y: h*0.56))
                p.addLine(to: CGPoint(x: w*0.5, y: h*0.86))
                p.addLine(to: CGPoint(x: w*0.44, y: h*0.56))
                p.addLine(to: CGPoint(x: w*0.14, y: h*0.5))
                p.addLine(to: CGPoint(x: w*0.44, y: h*0.44))
                p.closeSubpath()
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .ellipsis:
            for cx in [w*0.26, w*0.5, w*0.74] {
                c.fill(Path { p in
                    p.addEllipse(in: CGRect(x: cx - s*0.055, y: h*0.5 - s*0.055, width: s*0.11, height: s*0.11))
                }, with: .foreground)
            }

        case .swipeReply:
            c.stroke(Path { p in
                // Seta curva de resposta
                p.move(to: CGPoint(x: w*0.70, y: h*0.26))
                p.addCurve(to: CGPoint(x: w*0.26, y: h*0.5),
                           control1: CGPoint(x: w*0.72, y: h*0.14),
                           control2: CGPoint(x: w*0.26, y: h*0.26))
                p.addLine(to: CGPoint(x: w*0.70, y: h*0.5))
                // Ponta da seta
                p.move(to: CGPoint(x: w*0.26, y: h*0.36))
                p.addLine(to: CGPoint(x: w*0.26, y: h*0.5))
                p.addLine(to: CGPoint(x: w*0.40, y: h*0.5))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        // ═══════════════════════════════════════════════
        // FINANCEIRO / DINHEIRO
        // ═══════════════════════════════════════════════

        case .pix:
            // Losango Pix estilizado (4 pétalas arredondadas)
            let pixR = s * 0.30
            let pixCX = w * 0.5, pixCY = h * 0.5
            c.stroke(Path { p in
                for i in 0..<4 {
                    let angle = Double(i) * .pi / 2
                    let ax = pixCX + pixR * CGFloat(cos(angle))
                    let ay = pixCY + pixR * CGFloat(sin(angle))
                    if i == 0 {
                        p.move(to: CGPoint(x: ax, y: ay))
                    }
                    let nextAngle = angle + .pi / 2
                    let nx = pixCX + pixR * CGFloat(cos(nextAngle))
                    let ny = pixCY + pixR * CGFloat(sin(nextAngle))
                    p.addCurve(to: CGPoint(x: nx, y: ny),
                               control1: CGPoint(x: ax + pixR*0.5*CGFloat(cos(angle + .pi/4)),
                                                 y: ay + pixR*0.5*CGFloat(sin(angle + .pi/4))),
                               control2: CGPoint(x: nx + pixR*0.5*CGFloat(cos(nextAngle + .pi)),
                                                 y: ny + pixR*0.5*CGFloat(sin(nextAngle + .pi))))
                }
            }, with: .foreground, lineWidth: weight)

        case .wallet:
            // Carteira dobrada
            c.stroke(Path { p in
                p.addRoundedRect(in: CGRect(x: w*0.10, y: h*0.26, width: w*0.80, height: h*0.56),
                                 cornerSize: CGSize(width: s*0.08, height: s*0.08))
                // Dobra superior
                p.move(to: CGPoint(x: w*0.10, y: h*0.44))
                p.addLine(to: CGPoint(x: w*0.90, y: h*0.44))
                // Moeda / bolso
                p.addRoundedRect(in: CGRect(x: w*0.60, y: h*0.52, width: w*0.22, height: h*0.22),
                                 cornerSize: CGSize(width: s*0.05, height: s*0.05))
                // Ponto no bolso
                p.addEllipse(in: CGRect(x: w*0.69, y: h*0.60, width: s*0.08, height: s*0.08))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .coin:
            // Moeda com cifrão
            c.stroke(Path { p in
                p.addEllipse(in: CGRect(x: w*0.14, y: h*0.14, width: s*0.72, height: s*0.72))
                // R$ estilizado
                p.move(to: CGPoint(x: w*0.46, y: h*0.30))
                p.addLine(to: CGPoint(x: w*0.46, y: h*0.70))
                p.move(to: CGPoint(x: w*0.38, y: h*0.26))
                p.addLine(to: CGPoint(x: w*0.62, y: h*0.26))
                p.move(to: CGPoint(x: w*0.38, y: h*0.74))
                p.addLine(to: CGPoint(x: w*0.62, y: h*0.74))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round))

        case .chartPie:
            // Fatia de torta / pizza
            c.stroke(Path { p in
                p.addEllipse(in: CGRect(x: w*0.14, y: h*0.14, width: s*0.72, height: s*0.72))
                p.move(to: CGPoint(x: w*0.5, y: h*0.5))
                p.addLine(to: CGPoint(x: w*0.5, y: h*0.14))
                p.move(to: CGPoint(x: w*0.5, y: h*0.5))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.5))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round))

        case .chartBar:
            // Barras de gráfico crescendo
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.14, y: h*0.86))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.86))
                // 3 barras
                for (i, heightFrac): (Int, CGFloat) in [(0, 0.50), (1, 0.72), (2, 0.36)] {
                    let bx = w * (0.24 + Double(i)*0.22)
                    let by = h * (0.86 - heightFrac)
                    p.addRoundedRect(in: CGRect(x: bx, y: by, width: w*0.14, height: h*heightFrac),
                                     cornerSize: CGSize(width: s*0.03, height: s*0.03))
                }
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .dollarSign:
            // Cifrão R$ em círculo
            c.stroke(Path { p in
                p.addEllipse(in: CGRect(x: w*0.14, y: h*0.14, width: s*0.72, height: s*0.72))
                // R
                p.move(to: CGPoint(x: w*0.38, y: h*0.62))
                p.addLine(to: CGPoint(x: w*0.38, y: h*0.36))
                p.addArc(center: CGPoint(x: w*0.50, y: h*0.36), radius: s*0.12,
                         startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                p.addLine(to: CGPoint(x: w*0.38, y: h*0.50))
                p.addLine(to: CGPoint(x: w*0.62, y: h*0.62))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .receipt:
            // Recibo / comprovante
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.22, y: h*0.14))
                p.addLine(to: CGPoint(x: w*0.78, y: h*0.14))
                p.addLine(to: CGPoint(x: w*0.78, y: h*0.86))
                // Ziguezague na base
                p.move(to: CGPoint(x: w*0.78, y: h*0.86))
                p.addLine(to: CGPoint(x: w*0.66, y: h*0.76))
                p.addLine(to: CGPoint(x: w*0.54, y: h*0.86))
                p.addLine(to: CGPoint(x: w*0.42, y: h*0.76))
                p.addLine(to: CGPoint(x: w*0.30, y: h*0.86))
                p.addLine(to: CGPoint(x: w*0.22, y: h*0.76))
                p.addLine(to: CGPoint(x: w*0.22, y: h*0.14))
                // Linhas de texto
                p.move(to: CGPoint(x: w*0.33, y: h*0.36))
                p.addLine(to: CGPoint(x: w*0.67, y: h*0.36))
                p.move(to: CGPoint(x: w*0.33, y: h*0.50))
                p.addLine(to: CGPoint(x: w*0.67, y: h*0.50))
                p.move(to: CGPoint(x: w*0.33, y: h*0.63))
                p.addLine(to: CGPoint(x: w*0.56, y: h*0.63))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .splitBill:
            // Conta dividida (retângulo + linha central + 2 meias pessoas)
            c.stroke(Path { p in
                p.addRoundedRect(in: CGRect(x: w*0.14, y: h*0.22, width: w*0.72, height: h*0.60),
                                 cornerSize: CGSize(width: s*0.06, height: s*0.06))
                p.move(to: CGPoint(x: w*0.5, y: h*0.22))
                p.addLine(to: CGPoint(x: w*0.5, y: h*0.82))
                // R$ esquerdo
                p.move(to: CGPoint(x: w*0.26, y: h*0.44))
                p.addLine(to: CGPoint(x: w*0.26, y: h*0.62))
                p.move(to: CGPoint(x: w*0.20, y: h*0.40))
                p.addLine(to: CGPoint(x: w*0.32, y: h*0.40))
                p.move(to: CGPoint(x: w*0.20, y: h*0.66))
                p.addLine(to: CGPoint(x: w*0.32, y: h*0.66))
                // R$ direito
                p.move(to: CGPoint(x: w*0.74, y: h*0.44))
                p.addLine(to: CGPoint(x: w*0.74, y: h*0.62))
                p.move(to: CGPoint(x: w*0.68, y: h*0.40))
                p.addLine(to: CGPoint(x: w*0.80, y: h*0.40))
                p.move(to: CGPoint(x: w*0.68, y: h*0.66))
                p.addLine(to: CGPoint(x: w*0.80, y: h*0.66))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round))

        case .checkPaid:
            // Círculo com check duplo (confirmado/pago)
            c.stroke(Path { p in
                p.addEllipse(in: CGRect(x: w*0.12, y: h*0.12, width: s*0.76, height: s*0.76))
                p.move(to: CGPoint(x: w*0.26, y: h*0.52))
                p.addLine(to: CGPoint(x: w*0.44, y: h*0.68))
                p.addLine(to: CGPoint(x: w*0.74, y: h*0.36))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .alertSpend:
            // Raio (lightning bolt) = alerta de gasto
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.62, y: h*0.12))
                p.addLine(to: CGPoint(x: w*0.33, y: h*0.52))
                p.addLine(to: CGPoint(x: w*0.56, y: h*0.52))
                p.addLine(to: CGPoint(x: w*0.38, y: h*0.88))
                p.addLine(to: CGPoint(x: w*0.70, y: h*0.46))
                p.addLine(to: CGPoint(x: w*0.46, y: h*0.46))
                p.closeSubpath()
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        // ═══════════════════════════════════════════════
        // CATEGORIAS
        // ═══════════════════════════════════════════════

        case .catTravel:
            // Avião moderno visto de frente
            c.stroke(Path { p in
                // Fuselagem
                p.move(to: CGPoint(x: w*0.5, y: h*0.12))
                p.addLine(to: CGPoint(x: w*0.5, y: h*0.88))
                // Asas
                p.move(to: CGPoint(x: w*0.14, y: h*0.58))
                p.addCurve(to: CGPoint(x: w*0.86, y: h*0.58),
                           control1: CGPoint(x: w*0.3, y: h*0.42),
                           control2: CGPoint(x: w*0.70, y: h*0.42))
                // Estabilizadores traseiros
                p.move(to: CGPoint(x: w*0.30, y: h*0.76))
                p.addLine(to: CGPoint(x: w*0.70, y: h*0.76))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round))

        case .catBBQ:
            // Espeto de churrasco
            c.stroke(Path { p in
                // Espeto diagonal
                p.move(to: CGPoint(x: w*0.22, y: h*0.78))
                p.addLine(to: CGPoint(x: w*0.78, y: h*0.22))
                // 3 bolinhas na carne
                for t: CGFloat in [0.35, 0.52, 0.68] {
                    let cx = w*0.22 + (w*0.78 - w*0.22)*t
                    let cy = h*0.78 + (h*0.22 - h*0.78)*t
                    p.addEllipse(in: CGRect(x: cx - s*0.09, y: cy - s*0.09, width: s*0.18, height: s*0.18))
                }
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round))

        case .catBar:
            // Caneca de chopp
            c.stroke(Path { p in
                // Corpo
                p.addRoundedRect(in: CGRect(x: w*0.18, y: h*0.22, width: w*0.52, height: h*0.60),
                                 cornerSize: CGSize(width: s*0.06, height: s*0.06))
                // Alça
                p.move(to: CGPoint(x: w*0.70, y: h*0.36))
                p.addArc(center: CGPoint(x: w*0.78, y: h*0.52), radius: s*0.18,
                         startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
                p.addLine(to: CGPoint(x: w*0.70, y: h*0.68))
                // Espuma
                p.move(to: CGPoint(x: w*0.22, y: h*0.22))
                p.addCurve(to: CGPoint(x: w*0.46, y: h*0.22),
                           control1: CGPoint(x: w*0.30, y: h*0.12),
                           control2: CGPoint(x: w*0.38, y: h*0.12))
                p.addCurve(to: CGPoint(x: w*0.66, y: h*0.22),
                           control1: CGPoint(x: w*0.56, y: h*0.14),
                           control2: CGPoint(x: w*0.62, y: h*0.14))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .catHome:
            // Casa com telhado triangular
            c.stroke(Path { p in
                // Telhado
                p.move(to: CGPoint(x: w*0.14, y: h*0.52))
                p.addLine(to: CGPoint(x: w*0.5, y: h*0.16))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.52))
                // Paredes
                p.move(to: CGPoint(x: w*0.22, y: h*0.48))
                p.addLine(to: CGPoint(x: w*0.22, y: h*0.86))
                p.addLine(to: CGPoint(x: w*0.78, y: h*0.86))
                p.addLine(to: CGPoint(x: w*0.78, y: h*0.48))
                // Porta
                p.addRoundedRect(in: CGRect(x: w*0.40, y: h*0.62, width: w*0.20, height: h*0.24),
                                 cornerSize: CGSize(width: s*0.04, height: s*0.04))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .catCouple:
            // Coração duplo estilizado
            c.stroke(Path { p in
                for ox: CGFloat in [-s*0.12, s*0.12] {
                    p.move(to: CGPoint(x: w*0.5+ox, y: h*0.70))
                    p.addCurve(to: CGPoint(x: w*0.5+ox, y: h*0.36),
                               control1: CGPoint(x: w*0.14+ox, y: h*0.70),
                               control2: CGPoint(x: w*0.14+ox, y: h*0.26))
                    p.addArc(center: CGPoint(x: w*0.5+ox - s*0.07, y: h*0.36), radius: s*0.14,
                             startAngle: .degrees(0), endAngle: .degrees(-180), clockwise: true)
                    p.addArc(center: CGPoint(x: w*0.5+ox + s*0.07, y: h*0.36), radius: s*0.14,
                             startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
                }
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round))

        case .catParty:
            // Balão de festa
            c.stroke(Path { p in
                // Balão
                p.addEllipse(in: CGRect(x: w*0.26, y: h*0.14, width: s*0.44, height: s*0.44))
                // Fio
                p.move(to: CGPoint(x: w*0.5, y: h*0.58))
                p.addCurve(to: CGPoint(x: w*0.46, y: h*0.86),
                           control1: CGPoint(x: w*0.42, y: h*0.68),
                           control2: CGPoint(x: w*0.56, y: h*0.76))
                // Triângulo do nó
                p.move(to: CGPoint(x: w*0.42, y: h*0.58))
                p.addLine(to: CGPoint(x: w*0.58, y: h*0.58))
                p.addLine(to: CGPoint(x: w*0.5, y: h*0.68))
                p.closeSubpath()
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .catSport:
            // Troféu
            c.stroke(Path { p in
                // Copa
                p.move(to: CGPoint(x: w*0.26, y: h*0.18))
                p.addLine(to: CGPoint(x: w*0.26, y: h*0.52))
                p.addCurve(to: CGPoint(x: w*0.74, y: h*0.52),
                           control1: CGPoint(x: w*0.26, y: h*0.74),
                           control2: CGPoint(x: w*0.74, y: h*0.74))
                p.addLine(to: CGPoint(x: w*0.74, y: h*0.18))
                p.closeSubpath()
                // Alças
                p.move(to: CGPoint(x: w*0.26, y: h*0.30))
                p.addArc(center: CGPoint(x: w*0.17, y: h*0.36), radius: s*0.11,
                         startAngle: .degrees(0), endAngle: .degrees(-180), clockwise: true)
                p.move(to: CGPoint(x: w*0.74, y: h*0.30))
                p.addArc(center: CGPoint(x: w*0.83, y: h*0.36), radius: s*0.11,
                         startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
                // Haste + base
                p.move(to: CGPoint(x: w*0.5, y: h*0.52))
                p.addLine(to: CGPoint(x: w*0.5, y: h*0.74))
                p.move(to: CGPoint(x: w*0.30, y: h*0.74))
                p.addLine(to: CGPoint(x: w*0.70, y: h*0.74))
                p.addLine(to: CGPoint(x: w*0.70, y: h*0.84))
                p.addLine(to: CGPoint(x: w*0.30, y: h*0.84))
                p.closeSubpath()
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .catGift:
            // Caixinha de presente com laço
            c.stroke(Path { p in
                // Caixa
                p.addRoundedRect(in: CGRect(x: w*0.14, y: h*0.44, width: w*0.72, height: h*0.42),
                                 cornerSize: CGSize(width: s*0.06, height: s*0.06))
                // Tampa
                p.addRoundedRect(in: CGRect(x: w*0.10, y: h*0.36, width: w*0.80, height: h*0.14),
                                 cornerSize: CGSize(width: s*0.04, height: s*0.04))
                // Fita vertical
                p.move(to: CGPoint(x: w*0.5, y: h*0.36))
                p.addLine(to: CGPoint(x: w*0.5, y: h*0.86))
                // Laço esquerdo
                p.move(to: CGPoint(x: w*0.5, y: h*0.36))
                p.addCurve(to: CGPoint(x: w*0.5, y: h*0.22),
                           control1: CGPoint(x: w*0.26, y: h*0.36),
                           control2: CGPoint(x: w*0.26, y: h*0.14))
                // Laço direito
                p.addCurve(to: CGPoint(x: w*0.5, y: h*0.36),
                           control1: CGPoint(x: w*0.74, y: h*0.14),
                           control2: CGPoint(x: w*0.74, y: h*0.36))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .catWork:
            // Maleta / briefcase
            c.stroke(Path { p in
                p.addRoundedRect(in: CGRect(x: w*0.10, y: h*0.36, width: w*0.80, height: h*0.50),
                                 cornerSize: CGSize(width: s*0.08, height: s*0.08))
                // Alça superior
                p.move(to: CGPoint(x: w*0.34, y: h*0.36))
                p.addLine(to: CGPoint(x: w*0.34, y: h*0.24))
                p.addRoundedRect(in: CGRect(x: w*0.34, y: h*0.18, width: w*0.32, height: h*0.18),
                                 cornerSize: CGSize(width: s*0.06, height: s*0.06))
                p.addLine(to: CGPoint(x: w*0.66, y: h*0.36))
                // Divisor central
                p.move(to: CGPoint(x: w*0.10, y: h*0.58))
                p.addLine(to: CGPoint(x: w*0.90, y: h*0.58))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        // ═══════════════════════════════════════════════
        // CONTA / PERFIL
        // ═══════════════════════════════════════════════

        case .person:
            let pR: CGFloat = s*0.20
            let pCY: CGFloat = h*0.33
            c.stroke(Path { p in
                p.addEllipse(in: CGRect(x: w/2-pR, y: pCY-pR, width: pR*2, height: pR*2))
            }, with: .foreground, lineWidth: weight)
            c.stroke(Path { p in
                let bY = pCY + pR + s*0.05
                let bW = s*0.52, bH = s*0.28
                p.move(to: CGPoint(x: w/2-bW/2, y: bY+bH))
                p.addCurve(to: CGPoint(x: w/2+bW/2, y: bY+bH),
                           control1: CGPoint(x: w/2-bW/2, y: bY),
                           control2: CGPoint(x: w/2+bW/2, y: bY))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round))

        case .personGroup:
            // Igual ao tabGroups mas com tamanho normal
            let gR: CGFloat = s*0.16
            let gcx1 = w*0.36, gcx2 = w*0.60, ghy: CGFloat = h*0.30
            for cx in [gcx1, gcx2] {
                c.stroke(Path { p in
                    p.addEllipse(in: CGRect(x: cx-gR, y: ghy-gR, width: gR*2, height: gR*2))
                }, with: .foreground, lineWidth: weight)
                c.stroke(Path { p in
                    let bY = ghy + gR + s*0.04
                    let bW = s*0.36, bH = s*0.24
                    p.move(to: CGPoint(x: cx-bW/2, y: bY+bH))
                    p.addCurve(to: CGPoint(x: cx+bW/2, y: bY+bH),
                               control1: CGPoint(x: cx-bW/2, y: bY),
                               control2: CGPoint(x: cx+bW/2, y: bY))
                }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round))
            }

        case .lock:
            c.stroke(Path { p in
                p.addRoundedRect(in: CGRect(x: w*0.20, y: h*0.44, width: w*0.60, height: h*0.44),
                                 cornerSize: CGSize(width: s*0.08, height: s*0.08))
                p.move(to: CGPoint(x: w*0.34, y: h*0.44))
                p.addArc(center: CGPoint(x: w*0.5, y: h*0.36), radius: s*0.17,
                         startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
                p.addLine(to: CGPoint(x: w*0.66, y: h*0.44))
                p.addEllipse(in: CGRect(x: w*0.44, y: h*0.58, width: s*0.12, height: s*0.12))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .docText:
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.22, y: h*0.14))
                p.addLine(to: CGPoint(x: w*0.64, y: h*0.14))
                p.addLine(to: CGPoint(x: w*0.78, y: h*0.28))
                p.addLine(to: CGPoint(x: w*0.78, y: h*0.86))
                p.addLine(to: CGPoint(x: w*0.22, y: h*0.86))
                p.closeSubpath()
                // Dobra
                p.move(to: CGPoint(x: w*0.64, y: h*0.14))
                p.addLine(to: CGPoint(x: w*0.64, y: h*0.28))
                p.addLine(to: CGPoint(x: w*0.78, y: h*0.28))
                // Linhas de texto
                p.move(to: CGPoint(x: w*0.33, y: h*0.44))
                p.addLine(to: CGPoint(x: w*0.67, y: h*0.44))
                p.move(to: CGPoint(x: w*0.33, y: h*0.56))
                p.addLine(to: CGPoint(x: w*0.67, y: h*0.56))
                p.move(to: CGPoint(x: w*0.33, y: h*0.68))
                p.addLine(to: CGPoint(x: w*0.56, y: h*0.68))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .logout:
            // Seta saindo de porta
            c.stroke(Path { p in
                // Porta (retângulo aberto à direita)
                p.move(to: CGPoint(x: w*0.56, y: h*0.18))
                p.addLine(to: CGPoint(x: w*0.26, y: h*0.18))
                p.addLine(to: CGPoint(x: w*0.26, y: h*0.82))
                p.addLine(to: CGPoint(x: w*0.56, y: h*0.82))
                // Seta para direita
                p.move(to: CGPoint(x: w*0.46, y: h*0.5))
                p.addLine(to: CGPoint(x: w*0.82, y: h*0.5))
                p.move(to: CGPoint(x: w*0.66, y: h*0.36))
                p.addLine(to: CGPoint(x: w*0.82, y: h*0.5))
                p.addLine(to: CGPoint(x: w*0.66, y: h*0.64))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))

        case .inviteQR:
            // QR + seta compartilhamento
            c.stroke(Path { p in
                // Mini QR (2 cantos)
                for (ox, oy) in [(w*0.14, h*0.14), (w*0.56, h*0.14)] {
                    let q: CGFloat = s*0.26
                    p.addRect(CGRect(x: ox, y: oy, width: q, height: q))
                }
                p.addRect(CGRect(x: w*0.14, y: h*0.56, width: s*0.26, height: s*0.26))
                // Seta compartilhar (canto inferior direito)
                p.move(to: CGPoint(x: w*0.70, y: h*0.70))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.70))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.86))
                p.addLine(to: CGPoint(x: w*0.56, y: h*0.86))
                p.addLine(to: CGPoint(x: w*0.56, y: h*0.70))
                p.addLine(to: CGPoint(x: w*0.70, y: h*0.70))
                p.move(to: CGPoint(x: w*0.71, y: h*0.57))
                p.addLine(to: CGPoint(x: w*0.71, y: h*0.70))
                p.move(to: CGPoint(x: w*0.63, y: h*0.65))
                p.addLine(to: CGPoint(x: w*0.71, y: h*0.57))
                p.addLine(to: CGPoint(x: w*0.79, y: h*0.65))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight - 0.4, lineCap: .round, lineJoin: .round))

        case .inviteFriends:
            // Pessoa + seta apontando para ela
            let ifR: CGFloat = s*0.18
            let ifCY: CGFloat = h*0.32
            c.stroke(Path { p in
                p.addEllipse(in: CGRect(x: w*0.38-ifR, y: ifCY-ifR, width: ifR*2, height: ifR*2))
            }, with: .foreground, lineWidth: weight)
            c.stroke(Path { p in
                let bY = ifCY + ifR + s*0.04
                let bW = s*0.44, bH = s*0.26
                p.move(to: CGPoint(x: w*0.38-bW/2, y: bY+bH))
                p.addCurve(to: CGPoint(x: w*0.38+bW/2, y: bY+bH),
                           control1: CGPoint(x: w*0.38-bW/2, y: bY),
                           control2: CGPoint(x: w*0.38+bW/2, y: bY))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round))
            // Seta de convite
            c.stroke(Path { p in
                p.move(to: CGPoint(x: w*0.72, y: h*0.36))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.50))
                p.addLine(to: CGPoint(x: w*0.72, y: h*0.64))
                p.move(to: CGPoint(x: w*0.56, y: h*0.50))
                p.addLine(to: CGPoint(x: w*0.86, y: h*0.50))
            }, with: .foreground, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))
        }
    }
}

// ============================================================
// MARK: - Filled (solid) icon variant — uso para estados ativos
// ============================================================
struct JuntoIconFilled: View {
    let kind: JuntoIconKind
    var size: CGFloat = 22
    var color: Color = JuntoColors.textMain

    var body: some View {
        // Stroke mais pesado simula "filled" mantendo o design consistente
        JuntoIcon(kind: kind, size: size, color: color, weight: 2.4)
    }
}

// ============================================================
// MARK: - Wrapper conveniente: ícone em círculo colorido
// ============================================================
struct JuntoIconBubble: View {
    let kind: JuntoIconKind
    var size: CGFloat = 42
    var iconColor: Color = .white
    var bgColor: Color = JuntoColors.primary

    var body: some View {
        Circle()
            .fill(bgColor)
            .frame(width: size, height: size)
            .overlay(
                JuntoIcon(kind: kind, size: size * 0.52, color: iconColor, weight: 1.8)
            )
    }
}

// ============================================================
// MARK: - Helpers: conversão SF Symbol → JuntoIconKind
// ============================================================
extension JuntoIconKind {
    /// Converte nomes de categoria para ícone Juntô.
    static func category(_ name: String) -> JuntoIconKind {
        switch name {
        case "Viagem":        return .catTravel
        case "Churrasco":     return .catBBQ
        case "Bar & Drinks":  return .catBar
        case "Casa":          return .catHome
        case "Casal":         return .catCouple
        case "Festa":         return .catParty
        case "Esporte":       return .catSport
        case "Presente":      return .catGift
        case "Trabalho":      return .catWork
        default:              return .receipt
        }
    }

    /// Converte nome do ícone de atividade (legado) para JuntoIconKind.
    static func activity(_ sfName: String) -> JuntoIconKind {
        switch sfName {
        case "checkmark.circle", "checkmark.circle.fill": return .checkPaid
        case "dollarsign.circle":                          return .coin
        case "house":                                      return .catHome
        case "exclamationmark.triangle.fill":              return .alertSpend
        case "bell":                                       return .bell
        case "person.badge.plus":                          return .addPerson
        case "person.2":                                   return .personGroup
        default:                                           return .receipt
        }
    }
}
