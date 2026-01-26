import SwiftUI
import SwiftData
import UIKit
import Security

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
    @Published var isGuestUser: Bool = false
    @Published var currentUser: User?
    @Published var currentDog: Dog?
    @Published var dogs: [Dog] = []
    @Published var lastError: String?
    
    private let localDogsKey = "localDogs"
    private let isGuestKey = "isGuestUser"
    
    init() {
        // Load guest status from UserDefaults
        isGuestUser = UserDefaults.standard.bool(forKey: isGuestKey)
        
        // If guest user, automatically grant subscription access for testing
        if isGuestUser {
            hasActiveSubscription = true
        }
        
        if APIService.shared.getAuthToken() != nil {
            isSignedIn = true
            hasCompletedOnboarding = true
            
            // Load local dogs as fallback (in case backend is unavailable)
            loadLocalDogs()
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
        // First, load local dogs as immediate fallback
        await MainActor.run {
            loadLocalDogs()
        }
        
        do {
            let entitlements = try await APIService.shared.checkEntitlements()
            await MainActor.run {
                // Guest users always have subscription access for testing
                if isGuestUser {
                    hasActiveSubscription = true
                } else {
                    hasActiveSubscription = entitlements.hasActiveSubscription
                }
            }
            
            let dogs = try await APIService.shared.getDogs()
            await MainActor.run {
                self.dogs = dogs
                if let firstDog = dogs.first {
                    self.currentDog = firstDog
                }
                // Save dogs locally for offline access
                saveLocalDogs(dogs)
                lastError = nil
            }
        } catch {
            print("Failed to load user data: \(error)")
            await MainActor.run {
                lastError = "Unable to connect to server. Using offline data."
                // Local dogs already loaded above as fallback
            }
        }
    }
    
    func setGuestUser(_ isGuest: Bool) {
        isGuestUser = isGuest
        UserDefaults.standard.set(isGuest, forKey: isGuestKey)
        if isGuest {
            hasActiveSubscription = true
        }
    }
    
    func signOut() {
        APIService.shared.clearAuthToken()
        isSignedIn = false
        hasActiveSubscription = false
        isGuestUser = false
        currentUser = nil
        currentDog = nil
        dogs = []
        lastError = nil
        UserDefaults.standard.removeObject(forKey: isGuestKey)
        UserDefaults.standard.removeObject(forKey: localDogsKey)
    }
    
    // MARK: - Local Dog Storage (for offline access)
    
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
    
    func deleteDog(_ dog: Dog) async throws {
        // Delete from backend
        try await APIService.shared.deleteDog(dogId: dog.id)
        
        await MainActor.run {
            // Remove from local storage
            dogs.removeAll { $0.id == dog.id }
            saveLocalDogs(dogs)
            
            // Update current dog if needed
            if currentDog?.id == dog.id {
                currentDog = dogs.first
            }
        }
    }
}
