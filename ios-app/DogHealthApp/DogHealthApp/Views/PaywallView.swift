import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedPlan: SubscriptionPlan = .monthly
    
    enum SubscriptionPlan {
        case monthly
        case annual
        
        var title: String {
            switch self {
            case .monthly: return "Monthly"
            case .annual: return "Annual"
            }
        }
        
        var price: String {
            switch self {
            case .monthly: return "$9.99/month"
            case .annual: return "$79.99/year"
            }
        }
        
        var savings: String? {
            switch self {
            case .monthly: return nil
            case .annual: return "Save 33%"
            }
        }
        
        var productId: String {
            switch self {
            case .monthly: return "pup_monthly"
            case .annual: return "pup_annual"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Unlock Full Access")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Get unlimited AI-powered guidance for your dog's health")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 15) {
                FeatureRow(icon: "message.fill", text: "Unlimited chat with AI")
                FeatureRow(icon: "book.fill", text: "Access to health library")
                FeatureRow(icon: "bell.fill", text: "Personalized reminders")
                FeatureRow(icon: "heart.fill", text: "Track your dog's health")
            }
            .padding()
            
            Spacer()
            
            VStack(spacing: 12) {
                SubscriptionPlanButton(
                    plan: .annual,
                    isSelected: selectedPlan == .annual,
                    action: { selectedPlan = .annual }
                )
                
                SubscriptionPlanButton(
                    plan: .monthly,
                    isSelected: selectedPlan == .monthly,
                    action: { selectedPlan = .monthly }
                )
            }
            .padding(.horizontal)
            
            Button(action: {
                appState.hasActiveSubscription = true
            }) {
                Text("Subscribe Now")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Button(action: {
                appState.hasActiveSubscription = true
            }) {
                Text("Continue Without Subscription (Demo)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 5)
            
            Text("Cancel anytime. Terms apply.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom)
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

struct SubscriptionPlanButton: View {
    let plan: PaywallView.SubscriptionPlan
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(plan.title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(plan.price)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                }
                
                Spacer()
                
                if let savings = plan.savings {
                    Text(savings)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isSelected ? Color.white.opacity(0.2) : Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(AppState())
}
