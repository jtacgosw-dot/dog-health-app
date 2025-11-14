import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedPlan: SubscriptionPlan = .annual
    @State private var isLoading = false
    
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
        ZStack {
            Color.petlyCream
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                Spacer()
                
                Image(systemName: "pawprint.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.petlyDarkGreen)
                
                Text("Petly")
                    .font(.system(size: 42, weight: .bold, design: .serif))
                    .foregroundColor(.petlyDarkGreen)
                
                Text("Premium")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.petlySageGreen)
                
                Text("Get personalized AI-powered care for your pet")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                VStack(spacing: 15) {
                    FeatureRow(icon: "message.fill", text: "Unlimited AI chat with Petly")
                    FeatureRow(icon: "fork.knife", text: "Custom nutrition plans")
                    FeatureRow(icon: "heart.text.square", text: "Personalized care plans")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Health & wellness tracking")
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                
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
                
                Button(action: subscribe) {
                    Text("Start Free Trial")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.petlyDarkGreen)
                        .cornerRadius(PetlyTheme.buttonCornerRadius)
                }
                .disabled(isLoading)
                .padding(.horizontal)
                
                Button(action: {
                    appState.hasActiveSubscription = true
                }) {
                    Text("Continue as Guest")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 5)
                
                Text("7-day free trial • Cancel anytime")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            .padding()
            
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
    }
    
    private func subscribe() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            appState.hasActiveSubscription = true
            isLoading = false
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.petlyDarkGreen)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
                .foregroundColor(.black)
            
            Spacer()
            
            Image(systemName: "checkmark")
                .foregroundColor(.petlySageGreen)
                .fontWeight(.semibold)
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
                        .foregroundColor(isSelected ? .white : .petlyDarkGreen)
                    
                    Text(plan.price)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                }
                
                Spacer()
                
                if let savings = plan.savings {
                    Text(savings)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .petlyDarkGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isSelected ? Color.white.opacity(0.2) : Color.petlySageGreen.opacity(0.3))
                        .cornerRadius(8)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .padding()
            .background(isSelected ? Color.petlySageGreen : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.petlySageGreen.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(AppState())
}
