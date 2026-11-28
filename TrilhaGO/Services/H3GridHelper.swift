import Foundation
import CoreLocation

enum H3GridHelper {
    /// Gera hexágonos determinísticos (equivalentes à resolução ~9/10) ao redor de uma coordenada.
    static func hexRadiusMeters(resolution: Int) -> Double {
        resolution == 10 ? 65.0 : 120.0
    }

    static func hexKey(for coord: CLLocationCoordinate2D, resolution: Int = 9) -> String {
        let stepLat = resolution == 10 ? 0.0011 : 0.0020
        let stepLon = resolution == 10 ? 0.0013 : 0.0023
        let q = Int(floor(coord.latitude / stepLat))
        let r = Int(floor(coord.longitude / stepLon))
        return "h3r\(resolution)_\(q)_\(r)"
    }

    static func polygon(center: CLLocationCoordinate2D, radiusMeters: Double) -> [CLLocationCoordinate2D] {
        let latDegPerMeter = 1.0 / 111_320.0
        let lonDegPerMeter = 1.0 / (111_320.0 * max(0.2, cos(center.latitude * .pi / 180.0)))
        return (0..<6).map { i in
            let angle = Double(i) * (.pi / 3.0) + (.pi / 6.0)
            let dLat = radiusMeters * sin(angle) * latDegPerMeter
            let dLon = radiusMeters * cos(angle) * lonDegPerMeter
            return CLLocationCoordinate2D(latitude: center.latitude + dLat, longitude: center.longitude + dLon)
        }
    }

    static func nearbyHexes(around center: CLLocationCoordinate2D, resolution: Int = 9) -> [TerritoryHex] {
        let stepLat = resolution == 10 ? 0.0011 : 0.0020
        let stepLon = resolution == 10 ? 0.0013 : 0.0023
        let baseQ = Int(floor(center.latitude / stepLat))
        let baseR = Int(floor(center.longitude / stepLon))
        let radius = hexRadiusMeters(resolution: resolution)

        var list: [TerritoryHex] = []
        for dq in -2...2 {
            for dr in -2...2 {
                let q = baseQ + dq
                let r = baseR + dr
                let offsetLon = (q % 2 == 0) ? 0.0 : (stepLon * 0.5)
                let c = CLLocationCoordinate2D(
                    latitude: (Double(q) + 0.5) * stepLat,
                    longitude: (Double(r) + 0.5) * stepLon + offsetLon
                )
                let id = "h3r\(resolution)_\(q)_\(r)"
                let seed = abs(q * 31 + r * 17) % 5
                let team: TrilhaTeam? = seed == 0 ? .esmeralda : (seed == 1 ? .horizonte : (seed == 2 ? .solar : nil))
                list.append(TerritoryHex(
                    id: id,
                    center: c,
                    vertices: polygon(center: c, radiusMeters: radius * 0.94),
                    ownerTeam: team,
                    points: team == nil ? 0 : (seed + 1) * 15
                ))
            }
        }
        return list
    }
}
