import Foundation
import StoreKit

@MainActor
final class SubscriptionService: ObservableObject {
    static let monthlyProductId = "com.achou.com.premium.monthly"

    @Published private(set) var monthlyProduct: Product?
    @Published private(set) var isPurchasing = false
    @Published var errorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactions()
        Task {
            await loadProducts()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.monthlyProductId])
            monthlyProduct = products.first
        } catch {
            // Product may not be configured in App Store Connect yet
        }
    }

    func purchaseMonthly(appState: AppState) async {
        isPurchasing = true
        errorMessage = nil

        do {
            if monthlyProduct == nil {
                await loadProducts()
            }
            guard let product = monthlyProduct else {
                errorMessage = "Plano Premium (R$ 19,90/mês) ainda não disponível na App Store."
                isPurchasing = false
                return
            }

            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await syncWithBackend(transaction: transaction, appState: appState)
                await transaction.finish()
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Compra pendente de aprovação."
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isPurchasing = false
    }

    func restorePurchases(appState: AppState) async {
        isPurchasing = true
        errorMessage = nil
        do {
            try await AppStore.sync()
            for await result in Transaction.currentEntitlements {
                if let transaction = try? checkVerified(result),
                   transaction.productID == Self.monthlyProductId {
                    await syncWithBackend(transaction: transaction, appState: appState)
                }
            }
        } catch {
            errorMessage = "Não foi possível restaurar compras."
        }
        isPurchasing = false
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? await self.checkVerified(result) {
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw APIError.serverError(statusCode: 403, message: "Assinatura Apple não verificada.")
        case .verified(let safe):
            return safe
        }
    }

    private func syncWithBackend(transaction: Transaction, appState: AppState) async {
        struct VerifyBody: Encodable {
            let productId: String
            let originalTransactionId: String
            let latestTransactionId: String
            let expiresAt: Date?
            let environment: String
        }
        struct VerifyResponse: Decodable {
            let isPremium: Bool
            let isVerified: Bool
        }

        let envString = transaction.environment == .sandbox ? "Sandbox" : (transaction.environment == .xcode ? "Xcode" : "Production")
        let body = VerifyBody(
            productId: transaction.productID,
            originalTransactionId: String(transaction.originalID),
            latestTransactionId: String(transaction.id),
            expiresAt: transaction.expirationDate,
            environment: envString
        )

        if let res: VerifyResponse = try? await APIClient.shared.request(
            path: "/subscriptions/apple/verify",
            method: "POST",
            body: body
        ) {
            if var user = appState.currentUser {
                user.isVerified = res.isVerified
                appState.currentUser = user
                appState.isPremium = res.isPremium
                try? await LocalUserRepository().saveProfile(user)
            }
        }
    }
}
