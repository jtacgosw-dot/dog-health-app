import SwiftUI

@main
struct DogHealthAppApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

class AppState: ObservableObject {
    @Published var hasCompletedOnboarding = false
    @Published var hasAcceptedDisclaimer = false
    @Published var isAuthenticated = false
    @Published var hasActiveSubscription = false
    @Published var userToken: String?
    @Published var isLoading = false
    
    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        hasAcceptedDisclaimer = UserDefaults.standard.bool(forKey: "hasAcceptedDisclaimer")
        userToken = UserDefaults.standard.string(forKey: "userToken")
        isAuthenticated = userToken != nil
        
        if isAuthenticated {
            checkSubscriptionStatus()
        }
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    func acceptDisclaimer() {
        hasAcceptedDisclaimer = true
        UserDefaults.standard.set(true, forKey: "hasAcceptedDisclaimer")
    }
    
    func setAuthenticated(token: String) {
        userToken = token
        isAuthenticated = true
        UserDefaults.standard.set(token, forKey: "userToken")
        hasActiveSubscription = true
        checkSubscriptionStatus()
    }
    
    func logout() {
        userToken = nil
        isAuthenticated = false
        hasActiveSubscription = false
        UserDefaults.standard.removeObject(forKey: "userToken")
    }
    
    func checkSubscriptionStatus() {
        guard let token = userToken else { return }
        
        isLoading = true
        
        Task {
            do {
                let hasSubscription = try await EntitlementsService.shared.checkEntitlements(token: token)
                DispatchQueue.main.async {
                    self.hasActiveSubscription = hasSubscription
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.hasActiveSubscription = false
                    self.isLoading = false
                }
            }
        }
    }
}
