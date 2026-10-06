import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ResultsScreen().tabItem { Label("Resultados", systemImage: "chart.bar.fill") }
            MapScreen().tabItem { Label("Mapa", systemImage: "map.fill") }
            RegionsScreen().tabItem { Label("Regiões", systemImage: "map.circle.fill") }
            CandidatesScreen().tabItem { Label("Candidatos", systemImage: "person.3.fill") }
            AboutScreen().tabItem { Label("Sobre", systemImage: "info.circle.fill") }
        }
    }
}