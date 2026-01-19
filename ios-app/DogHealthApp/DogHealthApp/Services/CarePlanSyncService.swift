import Foundation
import SwiftData
import Network

@MainActor
class CarePlanSyncService: ObservableObject {
    static let shared = CarePlanSyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncError: String?
    @Published var isOnline = true
    
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "CarePlanNetworkMonitor")
    private var modelContext: ModelContext?
    
    private let lastSyncKey = "lastCarePlanSyncAt"
    private let maxRetryAttempts = 3
    private let baseRetryDelay: UInt64 = 1_000_000_000
    
    private init() {
        setupNetworkMonitoring()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = path.status == .satisfied
                if path.status == .satisfied {
                    await self?.syncPendingCarePlans()
                }
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    var lastSyncAt: Date? {
        get {
            UserDefaults.standard.object(forKey: lastSyncKey) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: lastSyncKey)
        }
    }
    
    func syncPendingCarePlans() async {
        guard !isSyncing else { return }
        guard isOnline else { return }
        guard APIService.shared.getAuthToken() != nil else { return }
        guard let context = modelContext else { return }
        
        isSyncing = true
        lastSyncError = nil
        
        do {
            let descriptor = FetchDescriptor<CarePlan>(
                predicate: #Predicate { $0.needsSync == true }
            )
            let unsyncedPlans = try context.fetch(descriptor)
            
            for plan in unsyncedPlans {
                // TODO: When backend endpoint is available, sync care plan here
                // For now, mark as synced locally to prevent repeated sync attempts
                // This will be replaced with actual API call when backend supports care plans
                
                // Simulating successful sync for local-only operation
                plan.isSynced = true
                plan.needsSync = false
            }
            
            try context.save()
            lastSyncAt = Date()
            
        } catch {
            print("Failed to sync care plans: \(error)")
            lastSyncError = error.localizedDescription
        }
        
        isSyncing = false
    }
    
    func syncSingleCarePlan(_ plan: CarePlan) async {
        guard isOnline else { return }
        guard APIService.shared.getAuthToken() != nil else { return }
        
        var lastError: Error?
        
        for attempt in 0..<maxRetryAttempts {
            do {
                // TODO: When backend endpoint is available, sync care plan here
                // For now, mark as synced locally
                plan.isSynced = true
                plan.needsSync = false
                
                try modelContext?.save()
                return
            } catch {
                lastError = error
                print("Care plan sync attempt \(attempt + 1) failed: \(error)")
                
                if attempt < maxRetryAttempts - 1 {
                    let delay = baseRetryDelay * UInt64(1 << attempt)
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
        }
        
        if let error = lastError {
            print("Failed to sync care plan after \(maxRetryAttempts) attempts: \(error)")
            lastSyncError = error.localizedDescription
        }
    }
}
