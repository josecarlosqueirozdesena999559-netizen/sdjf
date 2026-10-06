import Foundation

enum Office: String, CaseIterable, Identifiable, Codable {
    case presidente, governador, senador
    case deputadoFederal = "deputado-federal"
    case deputadoEstadual = "deputado-estadual"
    var id: String { rawValue }
    var title: String {
        switch self {
        case .presidente: "Presidente"
        case .governador: "Governador"
        case .senador: "Senador"
        case .deputadoFederal: "Deputado Federal"
        case .deputadoEstadual: "Deputado Estadual/Distrital"
        }
    }
}

enum ElectionRound: Int, CaseIterable, Identifiable {
    case first = 1
    case second = 2
    var id: Int { rawValue }
    var title: String { "\(rawValue)º turno" }
    var availableOffices: [Office] { self == .second ? [.presidente, .governador] : Office.allCases }
}

struct ElectionScope: Codable { let tipo: String; let sigla: String?; let nome: String }

struct Candidate: Codable, Identifiable {
    let id: String
    let nome: String
    let nomeUrna: String
    let numero: Int
    let partido: String
    let coligacao: String?
    let cargo: String?
    let foto: String?
    let vice: String?
    let situacao: String?
    let eleito: Bool?
    let segundoTurno: Bool?
    let votos: Int
    let percentual: Double
    let cor: String

    var mapLightColorHex: String { CandidateMapPalette.colors(for: self).light }
    var mapDarkColorHex: String { CandidateMapPalette.colors(for: self).dark }
    var photoStatus: String? {
        let status = (situacao ?? "").folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "pt_BR")).lowercased()
        if status.contains("nao eleito") { return "NÃO ELEITO" }
        if eleito == true || (status.contains("eleito") && !status.contains("nao eleito")) { return "ELEITO" }
        if segundoTurno == true || status.contains("2º turno") || status.contains("2o turno") || status.contains("segundo turno") { return "2º TURNO" }
        return nil
    }
    func photoStatus(for round: ElectionRound) -> String? {
        guard photoStatus == "2º TURNO", round == .second else { return photoStatus }
        return "EM DISPUTA"
    }
    func displayedSituation(for round: ElectionRound) -> String? {
        photoStatus == nil ? situacao : nil
    }
}

struct ElectionResult: Codable {
    let eleicao: String
    let turno: Int?
    let cargo: String
    let cargoNome: String
    let abrangencia: ElectionScope
    let secoesTotalizadas: Int
    let secoesTotal: Int
    let votosValidos: Int
    let brancos: Int
    let nulos: Int
    let abstencoes: Int
    let eleitoradoAptoSecoesNaoTotalizadas: Int?
    let candidatos: [Candidate]
    let atualizadoEm: String
    let desatualizado: Bool?
    let mensagem: String?

    var progress: Double { secoesTotal == 0 ? 0 : Double(secoesTotalizadas) / Double(secoesTotal) }
    var isFinalized: Bool {
        (secoesTotal > 0 && secoesTotalizadas >= secoesTotal) || mensagem?.localizedCaseInsensitiveContains("totalização final") == true
    }
    var leaderCannotBeOvertaken: Bool {
        if isFinalized { return true }
        let ranking = orderedCandidates
        guard ranking.count > 1,
              ranking[0].votos > 0,
              let remainingElectors = eleitoradoAptoSecoesNaoTotalizadas,
              remainingElectors >= 0 else { return false }
        return ranking[0].votos - ranking[1].votos > remainingElectors
    }
    var orderedCandidates: [Candidate] { candidatos.sorted { $0.votos == $1.votos ? $0.numero < $1.numero : $0.votos > $1.votos } }
    var atualizadoEmFormatado: String {
        let parser = ISO8601DateFormatter()
        guard let date = parser.date(from: atualizadoEm) else { return atualizadoEm }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

struct Municipality: Codable, Identifiable, Hashable {
    let id: Int
    let nome: String
    let uf: String?
}

let brazilStates = ["AC","AL","AP","AM","BA","CE","DF","ES","GO","MA","MT","MS","MG","PA","PB","PR","PE","PI","RJ","RN","RS","RO","RR","SC","SP","SE","TO"]
private enum CandidateMapPalette {
    private static let byParty: [String: (light: String, dark: String)] = [
        "PT": ("#FFCDD2", "#C62828"),
        "PL": ("#BBDEFB", "#1565C0"),
        "PSD": ("#D1C4E9", "#512DA8"),
        "NOVO": ("#FFE0B2", "#EF6C00"),
        "MISSÃO": ("#B2DFDB", "#00796B"),
        "PSTU": ("#FFCDD2", "#8E0000"),
        "PCB": ("#F8BBD0", "#AD1457"),
        "DC": ("#D7CCC8", "#5D4037"),
        "PCO": ("#F8BBD0", "#C2185B"),
        "DEMOCRATA": ("#B2EBF2", "#00838F"),
        "AVANTE": ("#DCEDC8", "#558B2F"),
        "UP": ("#FFF9C4", "#F9A825")
    ]

    private static let fallback: [(light: String, dark: String)] = [
        ("#D1C4E9", "#512DA8"), ("#B2DFDB", "#00796B"),
        ("#FFE0B2", "#E65100"), ("#C5CAE9", "#303F9F"),
        ("#F8BBD0", "#AD1457"), ("#DCEDC8", "#558B2F"),
        ("#B3E5FC", "#0277BD"), ("#FFECB3", "#FF8F00")
    ]

    static func colors(for candidate: Candidate) -> (light: String, dark: String) {
        let normalizedName = candidate.nomeUrna.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "pt_BR")).uppercased()
        let party = candidate.partido.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "pt_BR")).uppercased()
        if candidate.numero == 13 || normalizedName.contains("LULA") { return ("#FFCDD2", "#C62828") }
        if normalizedName.contains("FLAVIO BOLSONARO") || (candidate.numero == 22 && party == "PL") { return ("#BBDEFB", "#1565C0") }
        if let known = byParty[candidate.partido.uppercased()] { return known }
        let hash = party.unicodeScalars.reduce(0) { (($0 &* 31) &+ Int($1.value)) & 0x7fffffff }
        return fallback[hash % fallback.count]
    }
}

struct MapSummary: Codable {
    let cores: [String: String]
    let disputas: [String]?
}
