import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                Text("Unlock Premium")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Get unlimited access to your AI Petly assistant")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            VStack(spacing: 16) {
                FeatureRow(icon: "message.fill", title: "Unlimited Chat", description: "Ask as many questions as you want")
                FeatureRow(icon: "brain.head.profile", title: "AI-Powered Advice", description: "Get instant, reliable health guidance")
                FeatureRow(icon: "shield.checkered", title: "Safety First", description: "Built-in emergency detection and warnings")
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 12) {
                ForEach(subscriptionService.products, id: \.id) { product in
                    SubscriptionButton(
                        product: product,
                        isPurchasing: isPurchasing
                    ) {
                        purchaseProduct(product)
                    }
                }
                
                if subscriptionService.products.isEmpty {
                    ProgressView("Loading subscription options...")
                        .frame(height: 50)
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                Button("Restore Purchases") {
                    restorePurchases()
                }
                .font(.footnote)
                .foregroundColor(PetlyColors.primaryGreen)
                .disabled(isPurchasing)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 4) {
                Text("Privacy Policy • Terms of Service")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("Cancel anytime in Settings")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)
        }
    }
    
    private func purchaseProduct(_ product: Product) {
        isPurchasing = true
        errorMessage = nil
        
        Task {
            do {
                let transaction = try await subscriptionService.purchase(product)
                if transaction != nil {
                    DispatchQueue.main.async {
                        self.appState.checkSubscriptionStatus()
                        self.isPurchasing = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isPurchasing = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Purchase failed. Please try again."
                    self.isPurchasing = false
                }
            }
        }
    }
    
    private func restorePurchases() {
        isPurchasing = true
        errorMessage = nil
        
        Task {
            do {
                try await subscriptionService.restorePurchases()
                DispatchQueue.main.async {
                    self.appState.checkSubscriptionStatus()
                    self.isPurchasing = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Restore failed. Please try again."
                    self.isPurchasing = false
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(PetlyColors.primaryGreen)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct SubscriptionButton: View {
    let product: Product
    let isPurchasing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscriptionTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(subscriptionSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(product.displayPrice)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(PetlyColors.primaryGreen)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isPurchasing)
    }
    
    private var subscriptionTitle: String {
        switch product.id {
        case "pup_monthly":
            return "Monthly"
        case "pup_annual":
            return "Annual"
        default:
            return "Subscription"
        }
    }
    
    private var subscriptionSubtitle: String {
        switch product.id {
        case "pup_monthly":
            return "Billed monthly"
        case "pup_annual":
            return "Best value • Save 40%"
        default:
            return ""
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView()
            .environmentObject(AppState())
    }
}
