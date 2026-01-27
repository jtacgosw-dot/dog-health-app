import SwiftUI
import SwiftData
import UIKit

@main
struct DogHealthAppApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    
    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return .light // Default to light mode since app uses hardcoded light colors
        }
    }
    
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
                .preferredColorScheme(colorScheme) // Respects user's appearance mode setting (System/Light/Dark)
                .buttonStyle(.plain) // Remove default button highlighting that causes gray blobs
                .dynamicTypeSize(.large) // Force default text size to ensure consistent layout regardless of user's text size and display zoom settings
                .onAppear {
                    // Initialize sync service with model context
                    let context = sharedModelContainer.mainContext
                    HealthLogSyncService.shared.setModelContext(context)
                    
                    // Load user data and trigger sync if signed in
                    if appState.isSignedIn {
                        Task {
                            // Load dogs so currentDog is available for pet photo display
                            await appState.loadUserData()
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
    
    private let localDogsKey = "localDogs"
    
    init() {
        if APIService.shared.getAuthToken() != nil {
            isSignedIn = true
            hasCompletedOnboarding = true
            
            // Load local dogs immediately so currentDog is available for pet photo
            loadLocalDogs()
        }
        
        #if DEBUG
        Task {
            await APIService.shared.ensureDevAuthenticated()
            await MainActor.run {
                if APIService.shared.getAuthToken() != nil {
                    self.isSignedIn = true
                    self.hasCompletedOnboarding = true
                    // Load local dogs for dev mode too
                    self.loadLocalDogs()
                }
            }
        }
        #endif
    }
    
    func loadUserData() async {
        // First, load local dogs as immediate fallback
        await MainActor.run {
            loadLocalDogs()
        }
        
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
                // Save dogs locally for offline access and photo persistence
                saveLocalDogs(dogs)
            }
        } catch {
            print("Failed to load user data: \(error)")
            // Local dogs already loaded above as fallback
        }
    }
    
    func signOut() {
        APIService.shared.clearAuthToken()
        isSignedIn = false
        hasActiveSubscription = false
        currentUser = nil
        currentDog = nil
        dogs = []
        UserDefaults.standard.removeObject(forKey: localDogsKey)
    }
    
    // MARK: - Local Dog Storage (for offline access and photo persistence)
    
    private func saveLocalDogs(_ dogs: [Dog]) {
        if let encoded = try? JSONEncoder().encode(dogs) {
            UserDefaults.standard.set(encoded, forKey: localDogsKey)
        }
    }
    
    private func loadLocalDogs() {
        if let data = UserDefaults.standard.data(forKey: localDogsKey),
           let decoded = try? JSONDecoder().decode([Dog].self, from: data) {
            if self.dogs.isEmpty {
                self.dogs = decoded
            }
            if self.currentDog == nil, let firstDog = decoded.first {
                self.currentDog = firstDog
            }
        }
    }
    
    func saveDogLocally(_ dog: Dog) {
        var localDogs = dogs
        if let index = localDogs.firstIndex(where: { $0.id == dog.id }) {
            localDogs[index] = dog
        } else {
            localDogs.append(dog)
        }
        saveLocalDogs(localDogs)
        dogs = localDogs
        currentDog = dog
    }
}
