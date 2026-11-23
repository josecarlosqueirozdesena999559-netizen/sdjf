import SwiftUI

/// Sistema de Ícones Nativos iOS (SF Symbols) do Juntô — limpo, sem fundos coloridos pesados e sem Canvas FGV
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

    var sfSymbolName: String {
        switch self {
        case .tabFriends:    return "person"
        case .tabGroups:     return "person.2"
        case .tabActivity:   return "arrow.left.arrow.right.circle"
        case .plus:          return "plus"
        case .addPerson:     return "person.badge.plus"
        case .checkmark:     return "checkmark"
        case .close:         return "xmark"
        case .chevronRight:  return "chevron.right"
        case .chevronLeft:   return "chevron.left"
        case .send:          return "paperplane.fill"
        case .edit:          return "pencil"
        case .trash:         return "trash"
        case .search:        return "magnifyingglass"
        case .share:         return "square.and.arrow.up"
        case .link:          return "link"
        case .mic:           return "mic.fill"
        case .camera:        return "camera"
        case .photo:         return "photo.on.rectangle"
        case .bell:          return "bell"
        case .bellOff:       return "bell.slash"
        case .eye:           return "eye"
        case .eyeOff:        return "eye.slash"
        case .info:          return "info.circle"
        case .warn:          return "exclamationmark.triangle"
        case .qrCode:        return "qrcode"
        case .crown:         return "crown.fill"
        case .shield:        return "checkmark.shield"
        case .shieldOff:     return "shield.slash"
        case .block:         return "nosign"
        case .play:          return "play.fill"
        case .pause:         return "pause.fill"
        case .sparkle:       return "sparkles"
        case .ellipsis:      return "ellipsis"
        case .swipeReply:    return "arrowshape.turn.up.left"
        case .pix:           return "qrcode"
        case .wallet:        return "creditcard"
        case .coin:          return "dollarsign.circle"
        case .chartPie:      return "chart.pie"
        case .chartBar:      return "chart.bar"
        case .dollarSign:    return "dollarsign.circle"
        case .receipt:       return "list.bullet.rectangle.portrait"
        case .splitBill:     return "arrow.down.left.circle"
        case .checkPaid:     return "checkmark.circle"
        case .alertSpend:    return "exclamationmark.triangle"
        case .catTravel:     return "airplane"
        case .catBBQ:        return "fork.knife"
        case .catBar:        return "mug"
        case .catHome:       return "house"
        case .catCouple:     return "heart"
        case .catParty:      return "sparkles"
        case .catSport:      return "sportscourt"
        case .catGift:       return "gift"
        case .catWork:       return "briefcase"
        case .person:        return "person"
        case .personGroup:   return "person.2"
        case .lock:          return "lock.shield"
        case .docText:       return "doc.text"
        case .logout:        return "rectangle.portrait.and.arrow.right"
        case .inviteQR:      return "qrcode"
        case .inviteFriends: return "person.badge.plus"
        }
    }
}

/// View de ícone nativo iOS (SF Symbols) sem desenho manual Canvas.
struct JuntoIcon: View {
    let kind: JuntoIconKind
    var size: CGFloat = 18
    var color: Color = JuntoColors.textMain
    var weight: CGFloat = 1.6

    private var fontWeight: Font.Weight {
        if weight >= 2.1 { return .medium }
        return .regular
    }

    var body: some View {
        Image(systemName: kind.sfSymbolName)
            .font(.system(size: size, weight: fontWeight))
            .foregroundColor(color)
    }
}

extension JuntoIconKind {
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

    static func activity(_ sfName: String) -> JuntoIconKind {
        switch sfName {
        case "checkmark.circle", "checkmark.circle.fill": return .checkPaid
        case "dollarsign.circle":                          return .coin
        case "house":                                      return .catHome
        case "exclamationmark.triangle", "exclamationmark.triangle.fill": return .alertSpend
        case "bell":                                       return .bell
        case "person.badge.plus":                          return .addPerson
        case "person.2", "person.2.fill", "person.2.badge.plus": return .personGroup
        default:                                           return .receipt
        }
    }
}
