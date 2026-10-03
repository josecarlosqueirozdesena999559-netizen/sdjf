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
    let votos: Int
    let percentual: Double
    let cor: String
}

struct ElectionResult: Codable {
    let eleicao: String
    let cargo: String
    let cargoNome: String
    let abrangencia: ElectionScope
    let secoesTotalizadas: Int
    let secoesTotal: Int
    let votosValidos: Int
    let brancos: Int
    let nulos: Int
    let abstencoes: Int
    let candidatos: [Candidate]
    let atualizadoEm: String
    let desatualizado: Bool?
    let mensagem: String?

    var progress: Double { secoesTotal == 0 ? 0 : Double(secoesTotalizadas) / Double(secoesTotal) }
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