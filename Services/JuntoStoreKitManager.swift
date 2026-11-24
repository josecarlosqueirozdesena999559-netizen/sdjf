import Foundation
import StoreKit

/// Gerenciador real de assinaturas Apple StoreKit 2 (Juntô Pro Mensal e Anual) — Compliance Guideline 3.1.1
@MainActor
final class JuntoStoreKitManager: ObservableObject {
    static let shared = JuntoStoreKitManager()

    static let monthlyProductId = "com.achou.com.pro.monthly"
    static let yearlyProductId = "com.achou.com.pro.yearly"

    @Published var products: [Product] = []
    @Published var isLoadingProducts: Bool = false
    @Published var isPurchasing: Bool = false
    @Published var lastErrorMessage: String? = nil

    private var updatesTask: Task<Void, Never>? = nil

    private init() {
        updatesTask = listenForTransactionUpdates()
    }

    deinit {
        updatesTask?.cancel()
    }

    var monthlyProduct: Product? {
        products.first(where: { $0.id == Self.monthlyProductId })
    }

    var yearlyProduct: Product? {
        products.first(where: { $0.id == Self.yearlyProductId })
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: [Self.monthlyProductId, Self.yearlyProductId])
            products = loaded.sorted(by: { $0.price < $1.price })
        } catch {
            lastErrorMessage = "Não foi possível carregar os planos da App Store no momento."
        }
    }

    /// Compra real via StoreKit 2 e validação/sincronização com o servidor PostgreSQL
    func purchase(planType: ProPlanType, username: String) async -> (success: Bool, planName: String?, expiresDateText: String?, errorMessage: String?) {
        isPurchasing = true
        lastErrorMessage = nil
        defer { isPurchasing = false }

        if products.isEmpty {
            await loadProducts()
        }

        let targetId = planType == .yearly ? Self.yearlyProductId : Self.monthlyProductId
        guard let product = products.first(where: { $0.id == targetId }) else {
            let msg = "Plano ainda não publicado no App Store Connect (\(targetId))."
            lastErrorMessage = msg
            return (false, nil, nil, msg)
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verifyTransaction(verification)
                let expiresText = formatExpiration(transaction.expirationDate)
                let planName = planType == .yearly ? "Anual (\(product.displayPrice))" : "Mensal (\(product.displayPrice))"

                await JuntoBackendService.shared.verifyAppleSubscription(
                    username: username,
                    productId: product.id,
                    transactionId: String(transaction.id),
                    expiresAtISO: transaction.expirationDate.map { ISO8601DateFormatter().string(from: $0) }
                )

                await transaction.finish()
                return (true, planName, expiresText, nil)

            case .userCancelled:
                return (false, nil, nil, nil)

            case .pending:
                let msg = "Compra pendente de aprovação da Apple."
                lastErrorMessage = msg
                return (false, nil, nil, msg)

            @unknown default:
                return (false, nil, nil, "Não foi possível concluir a compra.")
            }
        } catch {
            let msg = "Falha na compra via App Store: \(error.localizedDescription)"
            lastErrorMessage = msg
            return (false, nil, nil, msg)
        }
    }

    /// Restaurar compras anteriores (exigência obrigatória da Apple Review)
    func restorePurchases(username: String) async -> (restored: Bool, planType: ProPlanType, planName: String?, expiresDateText: String?) {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            try await AppStore.sync()
        } catch {
            lastErrorMessage = "Não foi possível sincronizar com a App Store."
        }

        for await entitlement in Transaction.currentEntitlements {
            if let transaction = try? verifyTransaction(entitlement) {
                if transaction.productID == Self.yearlyProductId || transaction.productID == Self.monthlyProductId {
                    let isYearly = transaction.productID == Self.yearlyProductId
                    let planType: ProPlanType = isYearly ? .yearly : .monthly
                    let planName = isYearly ? "Anual (R$ 178,80)" : "Mensal (R$ 19,90)"
                    let expiresText = formatExpiration(transaction.expirationDate)

                    await JuntoBackendService.shared.verifyAppleSubscription(
                        username: username,
                        productId: transaction.productID,
                        transactionId: String(transaction.id),
                        expiresAtISO: transaction.expirationDate.map { ISO8601DateFormatter().string(from: $0) }
                    )

                    return (true, planType, planName, expiresText)
                }
            }
        }
        return (false, .none, nil, nil)
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached(priority: .background) {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
            }
        }
    }

    private func verifyTransaction<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    private func formatExpiration(_ date: Date?) -> String {
        let target = date ?? Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        let df = DateFormatter()
        df.locale = Locale(identifier: "pt_BR")
        df.dateFormat = "dd/MM/yyyy"
        return "Renova em \(df.string(from: target))"
    }
}
