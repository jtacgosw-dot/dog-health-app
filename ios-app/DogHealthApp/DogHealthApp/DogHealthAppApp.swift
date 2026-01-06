import SwiftUI
import SwiftData
import UIKit

@main
struct DogHealthAppApp: App {
    @StateObject private var appState = AppState()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            HealthLogEntry.self,
            PetReminder.self,
            CarePlan.self,
            CarePlanTask.self,
            CarePlanMilestone.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
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
                .modelContainer(sharedModelContainer)
                .preferredColorScheme(.light) // Force light mode - app uses light backgrounds throughout
                .onAppear {
                    // Initialize sync service with model context
                    let context = sharedModelContainer.mainContext
                    HealthLogSyncService.shared.setModelContext(context)
                    
                    // Trigger initial sync if signed in
                    if appState.isSignedIn {
                        Task {
                            await HealthLogSyncService.shared.syncPendingLogs()
                        }
                    }
                }
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
        
            #if DEBUG
            Task {
                await APIService.shared.ensureDevAuthenticated()
                await MainActor.run {
                    if APIService.shared.getAuthToken() != nil {
                        self.isSignedIn = true
                        self.hasCompletedOnboarding = true
                    }
                }
            }
            #endif
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
