import SwiftUI
import StoreKit

struct NewPaywallView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var storeKit = StoreKitManager.shared
    @State private var selectedPlan: PlanType = .annual
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
    
    enum PlanType: String {
        case annual = "com.petly.premium.annual"
        case monthly = "com.petly.premium.monthly"
    }
    
    let features = [
        ("heart.fill", "Personalized Wellness"),
        ("stethoscope", "Vet-Backed Insights"),
        ("chart.line.uptrend.xyaxis", "Smart Care Tracking"),
        ("crown.fill", "Exclusive Member Perks")
    ]
    
    private var selectedProduct: Product? {
        switch selectedPlan {
        case .annual:
            return storeKit.annualProduct
        case .monthly:
            return storeKit.monthlyProduct
        }
    }
    
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        appState.hasActiveSubscription = true
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.petlyDarkGreen)
                            .padding(12)
                            .background(Color.petlyLightGreen)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 24) {
                        Text("PETLY PREMIUM")
                            .font(.petlyTitle(28))
                            .foregroundColor(.petlyDarkGreen)
                        
                        HStack(spacing: 4) {
                            Text("Try us")
                                .font(.petlyTitle(32))
                                .foregroundColor(.petlyDarkGreen)
                            Text("free")
                                .font(.petlyTitle(32))
                                .foregroundColor(.petlyDarkGreen)
                                .underline()
                            Text("for 1 week.")
                                .font(.petlyTitle(32))
                                .foregroundColor(.petlyDarkGreen)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(features, id: \.1) { icon, title in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color.petlyDarkGreen)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: icon)
                                                .font(.system(size: 18))
                                                .foregroundColor(.white)
                                        )
                                    
                                    Text(title)
                                        .font(.petlyBody(16))
                                        .foregroundColor(.petlyDarkGreen)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        
                        HStack(spacing: 12) {
                            PlanCard(
                                title: "Annual",
                                price: storeKit.annualProduct?.displayPrice ?? "$29.99",
                                originalPrice: "$35.99",
                                subtitle: "Per-year after a\n7 day free trial.",
                                badge: "SAVE 17%",
                                isSelected: selectedPlan == .annual
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedPlan = .annual
                                }
                            }
                            
                            PlanCard(
                                title: "Monthly",
                                price: storeKit.monthlyProduct?.displayPrice ?? "$3.99",
                                originalPrice: nil,
                                subtitle: "Per-month after\na 7 day free trial.",
                                badge: nil,
                                isSelected: selectedPlan == .monthly
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedPlan = .monthly
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Text("You'll be charged \(storeKit.monthlyProduct?.displayPrice ?? "$3.99") per-month after your 7 day free trial ends. You can cancel anytime.")
                            .font(.petlyBody(12))
                            .foregroundColor(.petlyFormIcon)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: startFreeTrial) {
                            Text("START YOUR FREE TRIAL")
                                .font(.petlyBodyMedium(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.petlyDarkGreen)
                                .cornerRadius(25)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        Button(action: restorePurchases) {
                            Text("Restore Purchases")
                                .font(.petlyBody(14))
                                .foregroundColor(.petlyDarkGreen)
                                .underline()
                        }
                        .padding(.top, 8)
                        
                        HStack(spacing: 20) {
                            Button(action: openPrivacyPolicy) {
                                Text("Privacy Policy")
                                    .font(.petlyBody(12))
                                    .foregroundColor(.petlyFormIcon)
                            }
                            
                            Text("|")
                                .font(.petlyBody(12))
                                .foregroundColor(.petlyFormIcon)
                            
                            Button(action: openTermsOfService) {
                                Text("Terms of Service")
                                    .font(.petlyBody(12))
                                    .foregroundColor(.petlyFormIcon)
                            }
                        }
                        .padding(.top, 12)
                        
                        HStack(spacing: 8) {
                            ForEach(0..<4) { index in
                                Circle()
                                    .fill(index == 2 ? Color.petlyDarkGreen : Color.petlyFormIcon.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            
            if isPurchasing || storeKit.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        .buttonStyle(.plain)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? storeKit.errorMessage ?? "An error occurred")
        }
        .disabled(isPurchasing)
        .onChange(of: storeKit.hasActiveSubscription) { _, hasSubscription in
            if hasSubscription {
                appState.hasActiveSubscription = true
                dismiss()
            }
        }
        .onAppear {
            Task {
                await storeKit.loadProducts()
            }
        }
    }
    
    private func startFreeTrial() {
        guard let product = selectedProduct else {
            // Fallback for testing when products aren't loaded (no StoreKit config)
            appState.hasActiveSubscription = true
            dismiss()
            return
        }
        
        isPurchasing = true
        
        Task {
            do {
                let success = try await storeKit.purchase(product)
                await MainActor.run {
                    isPurchasing = false
                    if success {
                        appState.hasActiveSubscription = true
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func restorePurchases() {
        isPurchasing = true
        
        Task {
            await storeKit.restorePurchases()
            await MainActor.run {
                isPurchasing = false
                if storeKit.hasActiveSubscription {
                    appState.hasActiveSubscription = true
                    dismiss()
                } else if let error = storeKit.errorMessage {
                    errorMessage = error
                    showError = true
                }
            }
        }
    }
    
    private func openPrivacyPolicy() {
        if let url = URL(string: "https://petlyapp.com/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openTermsOfService() {
        if let url = URL(string: "https://petlyapp.com/terms") {
            UIApplication.shared.open(url)
        }
    }
}

struct PlanCard: View {
    let title: String
    let price: String
    let originalPrice: String?
    let subtitle: String
    let badge: String?
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 12) {
                HStack {
                    Text(title)
                        .font(.petlyBodyMedium(18))
                        .foregroundColor(.petlyDarkGreen)
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .petlyDarkGreen : .petlyFormIcon)
                }
                
                if let originalPrice = originalPrice {
                    Text(originalPrice)
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyFormIcon)
                        .strikethrough()
                } else {
                    Text(" ")
                        .font(.petlyBody(14))
                }
                
                Text(price)
                    .font(.petlyTitle(36))
                    .foregroundColor(.petlyDarkGreen)
                
                Text(subtitle)
                    .font(.petlyBody(11))
                    .foregroundColor(.petlyFormIcon)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let badge = badge {
                    Text(badge)
                        .font(.petlyBodyMedium(12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.petlyDarkGreen)
                        .cornerRadius(16)
                } else {
                    Text(" ")
                        .font(.petlyBodyMedium(12))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .opacity(0)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.petlyLightGreen)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.petlyDarkGreen : Color.clear, lineWidth: 2)
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .buttonStyle(.plain)
    }
}

#Preview {
    NewPaywallView()
        .environmentObject(AppState())
}
