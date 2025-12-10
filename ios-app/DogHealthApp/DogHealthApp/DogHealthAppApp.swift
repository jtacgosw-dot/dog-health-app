import SwiftUI
import UIKit

@main
struct DogHealthAppApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        print("=== AVAILABLE FONTS ===")
        for family in UIFont.familyNames.sorted() {
            print("Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  - \(name)")
            }
        }
        print("======================")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool = false
    @Published var isSignedIn: Bool = false
    @Published var hasActiveSubscription: Bool = false
    @Published var currentUser: User?
    @Published var currentDog: Dog?
    @Published var dogs: [Dog] = []
    
    init() {
        if APIService.shared.getAuthToken() != nil {
            isSignedIn = true
            hasCompletedOnboarding = true
        }
    }
    
    func loadUserData() async {
        do {
            let entitlements = try await APIService.shared.checkEntitlements()
            await MainActor.run {
                hasActiveSubscription = entitlements.hasActiveSubscription
            }
            
            let dogs = try await APIService.shared.getDogs()
            await MainActor.run {
                self.dogs = dogs
                if let firstDog = dogs.first {
                    self.currentDog = firstDog
                }
            }
        } catch {
            print("Failed to load user data: \(error)")
        }
    }
    
    func signOut() {
        APIService.shared.clearAuthToken()
        isSignedIn = false
        hasActiveSubscription = false
        currentUser = nil
        currentDog = nil
        dogs = []
    }
}
