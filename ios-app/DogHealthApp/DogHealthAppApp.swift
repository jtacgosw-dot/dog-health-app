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
    
    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        hasAcceptedDisclaimer = UserDefaults.standard.bool(forKey: "hasAcceptedDisclaimer")
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    func acceptDisclaimer() {
        hasAcceptedDisclaimer = true
        UserDefaults.standard.set(true, forKey: "hasAcceptedDisclaimer")
    }
}
