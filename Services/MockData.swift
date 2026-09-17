import Foundation

struct MockData {
    static let categories: [Category] = [
        Category(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, name: "Eletrônicos", description: "TVs, Computadores...", iconName: "desktopcomputer"),
        Category(id: UUID(uuidString: "11111111-1111-1111-1111-111111111112")!, name: "Celulares", description: "Smartphones e acessórios", iconName: "iphone"),
        Category(id: UUID(uuidString: "11111111-1111-1111-1111-111111111113")!, name: "Eletrodomésticos", description: "Geladeiras, fogões...", iconName: "refrigerator"),
        Category(id: UUID(uuidString: "11111111-1111-1111-1111-111111111114")!, name: "Moda", description: "Roupas, calçados...", iconName: "tshirt"),
        Category(id: UUID(uuidString: "11111111-1111-1111-1111-111111111115")!, name: "Casa", description: "Móveis e decoração", iconName: "house"),
        Category(id: UUID(uuidString: "11111111-1111-1111-1111-111111111116")!, name: "Esportes", description: "Bicicletas, academia...", iconName: "bicycle"),
        Category(id: UUID(uuidString: "11111111-1111-1111-1111-111111111117")!, name: "Veículos", description: "Carros e motos", iconName: "car"),
        Category(id: UUID(uuidString: "11111111-1111-1111-1111-111111111118")!, name: "Livros e Games", description: "Console, HQs...", iconName: "gamecontroller"),
        Category(id: UUID(uuidString: "11111111-1111-1111-1111-111111111119")!, name: "Beleza", description: "Cosméticos, perfumes...", iconName: "staroflife")
    ]
    
    static let users: [User] = [
        User(id: UUID(), name: "Ana Souza", cpf: "444.444.444-44", birthDate: Date(), email: "ana@email.com", phone: "85999999999", username: "anasouza", visibleName: "Ana Souza", avatarURL: nil, location: "Fortaleza - CE", latitude: -3.7172, longitude: -38.5434, memberSince: Date(), isProfessional: false),
        User(id: UUID(), name: "Pedro Costa", cpf: "555.555.555-55", birthDate: Date(), email: "pedro@email.com", phone: "41999999999", username: "pedrocosta", visibleName: "Pedro C.", avatarURL: nil, location: "Curitiba - PR", latitude: -25.4284, longitude: -49.2733, memberSince: Date(), isProfessional: false)
    ]
    
    static var sellers: [Seller] {
        return users.map { user in
            Seller(id: UUID(), user: user, isVerified: true, rating: Double.random(in: 4.0...5.0), reviewCount: Int.random(in: 10...500), salesCount: Int.random(in: 5...1000), averageResponseTime: "2 horas", bio: "Vendedor de produtos de alta qualidade.")
        }
    }
    
    static let products: [Product] = [
        Product(id: UUID(), title: "iPhone 13 128GB", description: "Excelente estado, sem marcas de uso. Bateria 90%.", price: 2499.00, condition: .used, categoryId: categories[1].id, sellerId: users[0].id, location: "Fortaleza - CE", images: [], createdAt: Date(), views: 150, isActive: true, deliveryMethod: "Retirada em mãos", acceptsNegotiation: true),
        Product(id: UUID(), title: "MacBook Air M1", description: "Novo na caixa, lacrado. Garantia Apple.", price: 6500.00, condition: .new, categoryId: categories[0].id, sellerId: users[0].id, location: "São Paulo - SP", images: [], createdAt: Date(), views: 320, isActive: true, deliveryMethod: "Envio pelos correios", acceptsNegotiation: false),
        Product(id: UUID(), title: "Smart TV LG 55 4K", description: "TV com 1 ano de uso, controle smart magic incluso.", price: 1800.00, condition: .used, categoryId: categories[0].id, sellerId: users[1].id, location: "Rio de Janeiro - RJ", images: [], createdAt: Date(), views: 89, isActive: true, deliveryMethod: "A combinar", acceptsNegotiation: true),
        Product(id: UUID(), title: "Bicicleta Caloi Aro 29", description: "Bicicleta mountain bike, excelente para trilhas.", price: 950.00, condition: .used, categoryId: categories[5].id, sellerId: users[0].id, location: "Belo Horizonte - MG", images: [], createdAt: Date(), views: 45, isActive: true, deliveryMethod: "Retirada em mãos", acceptsNegotiation: true),
        Product(id: UUID(), title: "PlayStation 5", description: "Console PS5 versão disco. Acompanha 1 controle e 2 jogos.", price: 3800.00, condition: .used, categoryId: categories[7].id, sellerId: users[1].id, location: "Curitiba - PR", images: [], createdAt: Date(), views: 500, isActive: true, deliveryMethod: "A combinar", acceptsNegotiation: false)
    ]
}

