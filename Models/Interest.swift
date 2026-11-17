import Foundation

struct Interest: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let sfSymbol: String

    static let all: [Interest] = [
        Interest(id: "academia", title: "Academia", sfSymbol: "dumbbell.fill"),
        Interest(id: "viagens", title: "Viagens", sfSymbol: "airplane"),
        Interest(id: "musica", title: "Música", sfSymbol: "music.note"),
        Interest(id: "jogos", title: "Jogos", sfSymbol: "gamecontroller.fill"),
        Interest(id: "danca", title: "Dança", sfSymbol: "figure.dance"),
        Interest(id: "cinema", title: "Cinema", sfSymbol: "film.fill"),
        Interest(id: "gastronomia", title: "Gastronomia", sfSymbol: "fork.knife"),
        Interest(id: "esportes", title: "Esportes", sfSymbol: "sportscourt.fill"),
        Interest(id: "tecnologia", title: "Tecnologia", sfSymbol: "laptopcomputer"),
        Interest(id: "natureza", title: "Natureza", sfSymbol: "leaf.fill"),
        Interest(id: "fotografia", title: "Fotografia", sfSymbol: "camera.fill"),
        Interest(id: "leitura", title: "Leitura", sfSymbol: "book.fill"),
        Interest(id: "festas", title: "Festas", sfSymbol: "party.popper.fill"),
        Interest(id: "praia", title: "Praia", sfSymbol: "sun.max.fill"),
        Interest(id: "animais", title: "Animais", sfSymbol: "pawprint.fill"),
        Interest(id: "arte", title: "Arte", sfSymbol: "paintpalette.fill")
    ]
}
