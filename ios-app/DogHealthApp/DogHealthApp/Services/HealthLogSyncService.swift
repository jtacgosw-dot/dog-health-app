import Foundation
import SwiftData
import Network

@MainActor
class HealthLogSyncService: ObservableObject {
    static let shared = HealthLogSyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncError: String?
    @Published var isOnline = true
    
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var modelContext: ModelContext?
    
    private let lastSyncKey = "lastHealthLogSyncAt"
    private let maxRetryAttempts = 3
    private let baseRetryDelay: UInt64 = 1_000_000_000 // 1 second in nanoseconds
    
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
                    await self?.syncPendingLogs()
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
    
    func syncPendingLogs() async {
        guard !isSyncing else { return }
        guard isOnline else { return }
        guard APIService.shared.getAuthToken() != nil else { return }
        guard let context = modelContext else { return }
        
        isSyncing = true
        lastSyncError = nil
        
        do {
            // Get all unsynced logs
            let descriptor = FetchDescriptor<HealthLogEntry>(
                predicate: #Predicate { $0.needsSync == true }
            )
            let unsyncedLogs = try context.fetch(descriptor)
            
            // Group by dogId for efficient syncing
            let logsByDog = Dictionary(grouping: unsyncedLogs) { $0.dogId }
            
            for (dogId, logs) in logsByDog {
                let logRequests = logs.map { HealthLogRequest(from: $0) }
                
                do {
                    let response = try await APIService.shared.syncHealthLogs(
                        dogId: dogId,
                        lastSyncAt: lastSyncAt,
                        localLogs: logRequests
                    )
                    
                    // Mark uploaded logs as synced
                    for log in logs {
                        if response.duplicateClientIds.contains(log.id.uuidString) {
                            // Already on server
                            log.isSynced = true
                            log.needsSync = false
                            log.lastSyncedAt = Date()
                        } else {
                            // Find the server log that matches this client log
                            if let serverLog = response.serverLogs.first(where: { $0.clientId == log.id.uuidString }) {
                                log.serverLogId = serverLog.id
                                log.isSynced = true
                                log.needsSync = false
                                log.lastSyncedAt = Date()
                            }
                        }
                    }
                    
                    // Import any new logs from server that we don't have locally
                    for serverLog in response.serverLogs {
                        if serverLog.isDeleted == true {
                            // Handle deleted logs - remove from local if exists
                            if let clientId = serverLog.clientId,
                               let uuid = UUID(uuidString: clientId) {
                                let deleteDescriptor = FetchDescriptor<HealthLogEntry>(
                                    predicate: #Predicate { $0.id == uuid }
                                )
                                if let localLog = try? context.fetch(deleteDescriptor).first {
                                    context.delete(localLog)
                                }
                            }
                            continue
                        }
                        
                        // Check if we already have this log locally
                        var existsLocally = false
                        if let clientId = serverLog.clientId,
                           let uuid = UUID(uuidString: clientId) {
                            let checkDescriptor = FetchDescriptor<HealthLogEntry>(
                                predicate: #Predicate { $0.id == uuid }
                            )
                            existsLocally = (try? context.fetch(checkDescriptor).first) != nil
                        }
                        
                        if !existsLocally {
                            // Check by serverLogId - fetch all and filter manually due to #Predicate limitations with optional String
                            let serverLogId = serverLog.id
                            let allLogsDescriptor = FetchDescriptor<HealthLogEntry>()
                            if let allLogs = try? context.fetch(allLogsDescriptor) {
                                existsLocally = allLogs.contains { $0.serverLogId == serverLogId }
                            }
                        }
                        
                        if !existsLocally {
                            // Create new local entry from server log
                            let newEntry = createLocalEntry(from: serverLog)
                            context.insert(newEntry)
                        }
                    }
                    
                    // Update last sync time
                    if let syncedAt = ISO8601DateFormatter().date(from: response.syncedAt) {
                        lastSyncAt = syncedAt
                    } else {
                        lastSyncAt = Date()
                    }
                    
                    try context.save()
                    
                } catch {
                    print("Sync error for dog \(dogId): \(error)")
                    lastSyncError = error.localizedDescription
                }
            }
            
        } catch {
            print("Failed to fetch unsynced logs: \(error)")
            lastSyncError = error.localizedDescription
        }
        
        isSyncing = false
    }
    
    func syncSingleLog(_ entry: HealthLogEntry) async {
        guard isOnline else { return }
        guard APIService.shared.getAuthToken() != nil else { return }
        
        var lastError: Error?
        
        for attempt in 0..<maxRetryAttempts {
            do {
                let request = HealthLogRequest(from: entry)
                let response = try await APIService.shared.createHealthLog(log: request)
                
                entry.serverLogId = response.log.id
                entry.isSynced = true
                entry.needsSync = false
                entry.lastSyncedAt = Date()
                
                try modelContext?.save()
                return // Success, exit the retry loop
            } catch {
                lastError = error
                print("Sync attempt \(attempt + 1) failed: \(error)")
                
                if attempt < maxRetryAttempts - 1 {
                    // Exponential backoff: 1s, 2s, 4s
                    let delay = baseRetryDelay * UInt64(1 << attempt)
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
        }
        
        if let error = lastError {
            print("Failed to sync single log after \(maxRetryAttempts) attempts: \(error)")
            lastSyncError = error.localizedDescription
            // Log will be synced later when syncPendingLogs runs
        }
    }
    
    func pullLogsFromServer(dogId: String) async {
        guard isOnline else { return }
        guard APIService.shared.getAuthToken() != nil else { return }
        guard let context = modelContext else { return }
        
        do {
            let response = try await APIService.shared.getHealthLogs(dogId: dogId, since: lastSyncAt)
            
            for serverLog in response.logs {
                if serverLog.isDeleted == true {
                    // Handle deleted logs
                    if let clientId = serverLog.clientId,
                       let uuid = UUID(uuidString: clientId) {
                        let deleteDescriptor = FetchDescriptor<HealthLogEntry>(
                            predicate: #Predicate { $0.id == uuid }
                        )
                        if let localLog = try? context.fetch(deleteDescriptor).first {
                            context.delete(localLog)
                        }
                    }
                    continue
                }
                
                // Check if we already have this log
                var existsLocally = false
                if let clientId = serverLog.clientId,
                   let uuid = UUID(uuidString: clientId) {
                    let checkDescriptor = FetchDescriptor<HealthLogEntry>(
                        predicate: #Predicate { $0.id == uuid }
                    )
                    existsLocally = (try? context.fetch(checkDescriptor).first) != nil
                }
                
                if !existsLocally {
                    // Check by serverLogId - fetch all and filter manually due to #Predicate limitations with optional String
                    let serverLogId = serverLog.id
                    let allLogsDescriptor = FetchDescriptor<HealthLogEntry>()
                    if let allLogs = try? context.fetch(allLogsDescriptor) {
                        existsLocally = allLogs.contains { $0.serverLogId == serverLogId }
                    }
                }
                
                if !existsLocally {
                    let newEntry = createLocalEntry(from: serverLog)
                    context.insert(newEntry)
                }
            }
            
            if let syncedAt = ISO8601DateFormatter().date(from: response.syncedAt) {
                lastSyncAt = syncedAt
            }
            
            try context.save()
            
        } catch {
            print("Failed to pull logs from server: \(error)")
            lastSyncError = error.localizedDescription
        }
    }
    
    private func createLocalEntry(from serverLog: ServerHealthLog) -> HealthLogEntry {
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.date(from: serverLog.timestamp) ?? Date()
        
        let entry = HealthLogEntry(
            id: UUID(uuidString: serverLog.clientId ?? "") ?? UUID(),
            dogId: serverLog.dogId,
            logType: serverLog.logType,
            timestamp: timestamp,
            notes: serverLog.notes ?? "",
            mealType: serverLog.mealType,
            amount: serverLog.amount,
            duration: serverLog.duration,
            moodLevel: serverLog.moodLevel,
            symptomType: serverLog.symptomType,
            severityLevel: serverLog.severityLevel,
            digestionQuality: serverLog.digestionQuality,
            activityType: serverLog.activityType,
            supplementName: serverLog.supplementName,
            dosage: serverLog.dosage,
            appointmentType: serverLog.appointmentType,
            location: serverLog.location,
            groomingType: serverLog.groomingType,
            treatName: serverLog.treatName,
            waterAmount: serverLog.waterAmount,
            isSynced: true,
            serverLogId: serverLog.id,
            lastSyncedAt: Date(),
            needsSync: false
        )
        
        return entry
    }
}
