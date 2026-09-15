import SwiftUI

struct MyAdsView: View {
    @State private var selectedTab = 0
    let tabs = ["Ativos", "Vendidos", "Pausados"]
    
    var body: some View {
        VStack {
            Picker("Filtro", selection: $selectedTab) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Text(tabs[index]).tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "tag.slash")
                    .font(.largeTitle)
                    .foregroundColor(Theme.textSecondary)
                Text("Você não possui anúncios nesta categoria.")
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Meus anúncios")
        .navigationBarTitleDisplayMode(.inline)
    }
}
