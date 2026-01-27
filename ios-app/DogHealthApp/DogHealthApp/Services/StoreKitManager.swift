import Foundation
import StoreKit

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    private let productIDs: Set<String> = [
        "com.petly.premium.monthly",
        "com.petly.premium.annual"
    ]
    
    private var updateListenerTask: Task<Void, Error>?
    
    var hasActiveSubscription: Bool {
        !purchasedProductIDs.isEmpty
    }
    
    var monthlyProduct: Product? {
        products.first { $0.id == "com.petly.premium.monthly" }
    }
    
    var annualProduct: Product? {
        products.first { $0.id == "com.petly.premium.annual" }
    }
    
    private init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price }
            isLoading = false
        } catch {
            print("Failed to load products: \(error)")
            errorMessage = "Failed to load subscription options. Please try again."
            isLoading = false
        }
    }
    
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchasedProducts()
                await transaction.finish()
                isLoading = false
                return true
                
            case .userCancelled:
                isLoading = false
                return false
                
            case .pending:
                isLoading = false
                errorMessage = "Purchase is pending approval."
                return false
                
            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            isLoading = false
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            isLoading = false
            
            if purchasedProductIDs.isEmpty {
                errorMessage = "No previous purchases found."
            }
        } catch {
            isLoading = false
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
    }
    
    func updatePurchasedProducts() async {
        var purchasedIDs: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.revocationDate == nil {
                    purchasedIDs.insert(transaction.productID)
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        purchasedProductIDs = purchasedIDs
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }
    
    func subscriptionPeriod(for product: Product) -> String? {
        guard let subscription = product.subscription else { return nil }
        
        let unit = subscription.subscriptionPeriod.unit
        let value = subscription.subscriptionPeriod.value
        
        switch unit {
        case .day:
            return value == 1 ? "day" : "\(value) days"
        case .week:
            return value == 1 ? "week" : "\(value) weeks"
        case .month:
            return value == 1 ? "month" : "\(value) months"
        case .year:
            return value == 1 ? "year" : "\(value) years"
        @unknown default:
            return nil
        }
    }
    
    func hasIntroductoryOffer(for product: Product) -> Bool {
        product.subscription?.introductoryOffer != nil
    }
    
    func introductoryOfferDescription(for product: Product) -> String? {
        guard let offer = product.subscription?.introductoryOffer else { return nil }
        
        let period = offer.period
        let unit: String
        
        switch period.unit {
        case .day:
            unit = period.value == 1 ? "day" : "\(period.value) days"
        case .week:
            unit = period.value == 1 ? "week" : "\(period.value) weeks"
        case .month:
            unit = period.value == 1 ? "month" : "\(period.value) months"
        case .year:
            unit = period.value == 1 ? "year" : "\(period.value) years"
        @unknown default:
            unit = ""
        }
        
        switch offer.paymentMode {
        case .freeTrial:
            return "\(unit) free trial"
        case .payAsYouGo:
            return "\(offer.displayPrice) for \(unit)"
        case .payUpFront:
            return "\(offer.displayPrice) for \(unit)"
        @unknown default:
            return nil
        }
    }
}
