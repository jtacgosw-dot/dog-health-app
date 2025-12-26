import Foundation
import SwiftData

@Model
final class HealthLogEntry {
    var id: UUID
    var dogId: String
    var logType: String
    var timestamp: Date
    var notes: String
    
    var mealType: String?
    var amount: String?
    var duration: String?
    var moodLevel: Int?
    var symptomType: String?
    var severityLevel: Int?
    var digestionQuality: String?
    var activityType: String?
    var supplementName: String?
    var dosage: String?
    var appointmentType: String?
    var location: String?
    var groomingType: String?
    var treatName: String?
    var waterAmount: String?
    
    // Sync tracking fields
    var isSynced: Bool
    var serverLogId: String?
    var lastSyncedAt: Date?
    var needsSync: Bool
    
    init(
        id: UUID = UUID(),
        dogId: String,
        logType: String,
        timestamp: Date = Date(),
        notes: String = "",
        mealType: String? = nil,
        amount: String? = nil,
        duration: String? = nil,
        moodLevel: Int? = nil,
        symptomType: String? = nil,
        severityLevel: Int? = nil,
        digestionQuality: String? = nil,
        activityType: String? = nil,
        supplementName: String? = nil,
        dosage: String? = nil,
        appointmentType: String? = nil,
        location: String? = nil,
        groomingType: String? = nil,
        treatName: String? = nil,
        waterAmount: String? = nil,
        isSynced: Bool = false,
        serverLogId: String? = nil,
        lastSyncedAt: Date? = nil,
        needsSync: Bool = true
    ) {
        self.id = id
        self.dogId = dogId
        self.logType = logType
        self.timestamp = timestamp
        self.notes = notes
        self.mealType = mealType
        self.amount = amount
        self.duration = duration
        self.moodLevel = moodLevel
        self.symptomType = symptomType
        self.severityLevel = severityLevel
        self.digestionQuality = digestionQuality
        self.activityType = activityType
        self.supplementName = supplementName
        self.dosage = dosage
        self.appointmentType = appointmentType
        self.location = location
        self.groomingType = groomingType
        self.treatName = treatName
        self.waterAmount = waterAmount
        self.isSynced = isSynced
        self.serverLogId = serverLogId
        self.lastSyncedAt = lastSyncedAt
        self.needsSync = needsSync
    }
    
    var logTypeEnum: LogType? {
        LogType(rawValue: logType)
    }
    
    var displayTitle: String {
        switch logTypeEnum {
        case .meals:
            return mealType ?? "Meal"
        case .walk:
            if let dur = duration {
                return "\(dur) min walk"
            }
            return "Walk"
        case .treat:
            return treatName ?? "Treat"
        case .symptom:
            return symptomType ?? "Symptom"
        case .water:
            return waterAmount ?? "Water"
        case .playtime:
            return activityType ?? "Playtime"
        case .digestion:
            return digestionQuality ?? "Digestion"
        case .grooming:
            return groomingType ?? "Grooming"
        case .mood:
            if let level = moodLevel {
                let moods = ["Sad", "Down", "Okay", "Good", "Great"]
                return moods[min(level, moods.count - 1)]
            }
            return "Mood"
        case .supplements:
            return supplementName ?? "Supplement"
        case .appointments:
            return appointmentType ?? "Appointment"
        case .notes:
            return "Note"
        case .none:
            return logType
        }
    }
    
    var displaySubtitle: String {
        switch logTypeEnum {
        case .meals:
            return amount ?? ""
        case .walk:
            return amount ?? ""
        case .symptom:
            if let severity = severityLevel {
                return "Severity: \(severity)/5"
            }
            return ""
        case .supplements:
            return dosage ?? ""
        case .appointments:
            return location ?? ""
        default:
            return notes.isEmpty ? "" : notes
        }
    }
}
