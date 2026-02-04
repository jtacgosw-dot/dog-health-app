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
        #if DEBUG
        print("=== AVAILABLE FONTS ===")
        for family in UIFont.familyNames.sorted() {
            print("Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  - \(name)")
            }
        }
        print("======================")
        #endif
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
                    
                    // Check StoreKit subscription status
                    Task {
                        await StoreKitManager.shared.updatePurchasedProducts()
                        await MainActor.run {
                            appState.hasActiveSubscription = StoreKitManager.shared.hasActiveSubscription
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
    @Published var currentDog: Dog? {
        didSet {
            // Load pet photo when current dog changes
            loadPetPhoto()
        }
    }
    @Published var dogs: [Dog] = []
    @Published var petPhotoData: Data?
    
    private let localDogsKey = "localDogs"
    
    init() {
        if APIService.shared.getAuthToken() != nil {
            isSignedIn = true
            hasCompletedOnboarding = true
            
            // Load local dogs immediately so currentDog is available for pet photo
            loadLocalDogs()
            // Load pet photo after dogs are loaded
            loadPetPhoto()
            print("[AppState] init: Loaded from existing auth token, currentDog: \(currentDog?.id ?? "nil")")
        }
        
        #if DEBUG
        // For testing: bypass sign-in and create a test dog/user if needed
        if !isSignedIn {
            setupDebugUserAndDog()
            print("[AppState] init: Set up debug user and dog, currentDog: \(currentDog?.id ?? "nil")")
        }
        
        Task {
            await APIService.shared.ensureDevAuthenticated()
            await MainActor.run {
                if APIService.shared.getAuthToken() != nil {
                    self.isSignedIn = true
                    self.hasCompletedOnboarding = true
                    // Load local dogs for dev mode too
                    self.loadLocalDogs()
                    // Load pet photo after dogs are loaded
                    self.loadPetPhoto()
                    print("[AppState] init Task: Loaded after dev auth, currentDog: \(self.currentDog?.id ?? "nil")")
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
        
            #if DEBUG
            // In DEBUG mode, re-setup test user and dog so the app remains functional
            // setupDebugUserAndDog will authenticate and then set isSignedIn = true
            setupDebugUserAndDog()
            #endif
        }
    
        #if DEBUG
        private func setupDebugUserAndDog() {
            hasCompletedOnboarding = true
            hasActiveSubscription = true
        
            let savedOwnerName = UserDefaults.standard.string(forKey: "ownerName") ?? "Pet Parent"
        
            currentUser = User(
                id: "test-user-debug",
                email: "test@petlyapp.com",
                fullName: savedOwnerName,
                subscriptionStatus: .active
            )
        
            loadLocalDogs()
        
            if currentDog == nil || dogs.isEmpty {
                let testDog = Dog(
                    id: "00000000-0000-4000-8000-000000000001",
                    name: "Arlo",
                    breed: "Mini Poodle",
                    age: 3.0,
                    weight: 15.0,
                    imageUrl: nil,
                    healthConcerns: [],
                    allergies: [],
                    createdAt: Date(),
                    updatedAt: Date()
                )
                saveDogLocally(testDog)
                print("[AppState] setupDebugUserAndDog: Created default test dog")
            }
        
            loadPetPhoto()
            print("[AppState] setupDebugUserAndDog: owner=\(savedOwnerName), dog=\(currentDog?.name ?? "nil"), dogs.count=\(dogs.count)")
        
            // Authenticate and THEN set isSignedIn to true
            Task {
                await APIService.shared.ensureDevAuthenticated()
                await MainActor.run {
                    // Only set isSignedIn after auth token is actually set
                    if APIService.shared.getAuthToken() != nil {
                        self.isSignedIn = true
                        print("[AppState] setupDebugUserAndDog: Auth complete, isSignedIn=true")
                    } else {
                        print("[AppState] setupDebugUserAndDog: Auth failed, isSignedIn remains false")
                    }
                }
            }
        }
        #endif
    
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
    
    // MARK: - Pet Photo Management
    // Using FileManager for robust photo storage (avoids UserDefaults size limits)
    private var petPhotoURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("petPhoto.jpg")
    }
    
    func loadPetPhoto() {
        do {
            if FileManager.default.fileExists(atPath: petPhotoURL.path) {
                let data = try Data(contentsOf: petPhotoURL)
                petPhotoData = data
                print("[AppState] loadPetPhoto: Loaded \(data.count) bytes from \(petPhotoURL.lastPathComponent)")
            } else {
                petPhotoData = nil
                print("[AppState] loadPetPhoto: No photo file exists")
            }
        } catch {
            print("[AppState] loadPetPhoto ERROR: \(error.localizedDescription)")
            petPhotoData = nil
        }
    }
    
    func savePetPhoto(_ data: Data?) {
        do {
            if let data = data {
                try data.write(to: petPhotoURL, options: .atomic)
                petPhotoData = data
                print("[AppState] savePetPhoto: Saved \(data.count) bytes to \(petPhotoURL.lastPathComponent)")
            } else {
                if FileManager.default.fileExists(atPath: petPhotoURL.path) {
                    try FileManager.default.removeItem(at: petPhotoURL)
                }
                petPhotoData = nil
                print("[AppState] savePetPhoto: Removed photo file")
            }
            NotificationCenter.default.post(name: .petPhotoDidChange, object: nil)
        } catch {
            print("[AppState] savePetPhoto ERROR: \(error.localizedDescription)")
        }
    }
}
