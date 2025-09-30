import Foundation
import StoreKit

@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    
    private let productIDs: Set<String> = ["pup_monthly", "pup_annual"]
    
    private init() {
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            
            try await verifyWithBackend(transaction: transaction)
            
            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }
    
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchasedProducts()
        
        for await result in Transaction.currentEntitlements {
            let transaction = try checkVerified(result)
            try await verifyWithBackend(transaction: transaction)
        }
    }
    
    private func updatePurchasedProducts() async {
        var purchasedProducts: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if transaction.revocationDate == nil {
                purchasedProducts.insert(transaction.productID)
            }
        }
        
        self.purchasedProductIDs = purchasedProducts
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func verifyWithBackend(transaction: Transaction) async throws {
        guard let token = AppState().userToken else {
            throw StoreError.noAuthToken
        }
        
        guard let url = URL(string: "\(APIConfig.baseURL)/iap/verify") else {
            throw StoreError.invalidURL
        }
        
        let requestBody = ["transactionId": String(transaction.id)]
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StoreError.verificationFailed
        }
    }
}

enum StoreError: Error {
    case failedVerification
    case noAuthToken
    case invalidURL
    case verificationFailed
}
