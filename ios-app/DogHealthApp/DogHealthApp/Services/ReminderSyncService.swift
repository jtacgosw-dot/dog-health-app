import Foundation
import SwiftData
import Network

@MainActor
class ReminderSyncService: ObservableObject {
    static let shared = ReminderSyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncError: String?
    @Published var isOnline = true
    
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "ReminderNetworkMonitor")
    private var modelContext: ModelContext?
    
    private let lastSyncKey = "lastReminderSyncAt"
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
                    await self?.syncPendingReminders()
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
    
    func syncPendingReminders() async {
        guard !isSyncing else { return }
        guard isOnline else { return }
        guard APIService.shared.getAuthToken() != nil else { return }
        guard let context = modelContext else { return }
        
        isSyncing = true
        lastSyncError = nil
        
        do {
            let descriptor = FetchDescriptor<PetReminder>(
                predicate: #Predicate { $0.needsSync == true }
            )
            let unsyncedReminders = try context.fetch(descriptor)
            
            for reminder in unsyncedReminders {
                // TODO: When backend endpoint is available, sync reminder here
                // For now, mark as synced locally to prevent repeated sync attempts
                // This will be replaced with actual API call when backend supports reminders
                
                // Simulating successful sync for local-only operation
                reminder.isSynced = true
                reminder.needsSync = false
            }
            
            try context.save()
            lastSyncAt = Date()
            
        } catch {
            print("Failed to sync reminders: \(error)")
            lastSyncError = error.localizedDescription
        }
        
        isSyncing = false
    }
    
    func syncSingleReminder(_ reminder: PetReminder) async {
        guard isOnline else { return }
        guard APIService.shared.getAuthToken() != nil else { return }
        
        var lastError: Error?
        
        for attempt in 0..<maxRetryAttempts {
            do {
                // TODO: When backend endpoint is available, sync reminder here
                // For now, mark as synced locally
                reminder.isSynced = true
                reminder.needsSync = false
                
                try modelContext?.save()
                return
            } catch {
                lastError = error
                print("Reminder sync attempt \(attempt + 1) failed: \(error)")
                
                if attempt < maxRetryAttempts - 1 {
                    let delay = baseRetryDelay * UInt64(1 << attempt)
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
        }
        
        if let error = lastError {
            print("Failed to sync reminder after \(maxRetryAttempts) attempts: \(error)")
            lastSyncError = error.localizedDescription
        }
    }
}
