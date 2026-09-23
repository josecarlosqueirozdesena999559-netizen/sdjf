import SwiftUI

struct CategoriesView: View {
    @State private var searchText = ""
    let categories = MockData.categories
    
    var filteredCategories: [Category] {
        if searchText.isEmpty {
            return categories
        } else {
            return categories.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
            List {
                ForEach(filteredCategories) { category in
                    NavigationLink(destination: SearchResultsView(category: category)) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Theme.lightGreen)
                                    .frame(width: 48, height: 48)
                                Image(systemName: category.iconName)
                                    .foregroundColor(Theme.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(category.name)
                                    .typographySectionTitle()
                                Text(category.description)
                                    .typographyLabel()
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .searchable(text: $searchText, prompt: "Buscar em categorias...")
            .navigationTitle("Categorias")
    }
}
