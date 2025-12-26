import Foundation
import SwiftData

enum ReminderType: String, Codable, CaseIterable {
    case vaccination = "Vaccination"
    case medication = "Medication"
    case fleaTick = "Flea & Tick"
    case heartworm = "Heartworm"
    case grooming = "Grooming"
    case vetAppointment = "Vet Appointment"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .vaccination: return "syringe.fill"
        case .medication: return "pills.fill"
        case .fleaTick: return "ant.fill"
        case .heartworm: return "heart.fill"
        case .grooming: return "scissors"
        case .vetAppointment: return "stethoscope"
        case .other: return "bell.fill"
        }
    }
    
    var color: String {
        switch self {
        case .vaccination: return "blue"
        case .medication: return "purple"
        case .fleaTick: return "orange"
        case .heartworm: return "red"
        case .grooming: return "teal"
        case .vetAppointment: return "green"
        case .other: return "gray"
        }
    }
}

enum ReminderFrequency: String, Codable, CaseIterable {
    case once = "Once"
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Every 2 Weeks"
    case monthly = "Monthly"
    case quarterly = "Every 3 Months"
    case biannually = "Every 6 Months"
    case annually = "Yearly"
    
    var calendarComponent: Calendar.Component? {
        switch self {
        case .once: return nil
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .biweekly: return .weekOfYear
        case .monthly: return .month
        case .quarterly: return .month
        case .biannually: return .month
        case .annually: return .year
        }
    }
    
    var intervalValue: Int {
        switch self {
        case .once: return 0
        case .daily: return 1
        case .weekly: return 1
        case .biweekly: return 2
        case .monthly: return 1
        case .quarterly: return 3
        case .biannually: return 6
        case .annually: return 1
        }
    }
}

@Model
final class PetReminder {
    var id: String
    var dogId: String
    var title: String
    var reminderType: String
    var frequency: String
    var nextDueDate: Date
    var lastCompletedDate: Date?
    var notes: String?
    var isEnabled: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Sync tracking fields
    var isSynced: Bool = false
    var serverReminderId: String? = nil
    var needsSync: Bool = true
    
    init(
        id: String = UUID().uuidString,
        dogId: String,
        title: String,
        reminderType: ReminderType,
        frequency: ReminderFrequency,
        nextDueDate: Date,
        notes: String? = nil
    ) {
        self.id = id
        self.dogId = dogId
        self.title = title
        self.reminderType = reminderType.rawValue
        self.frequency = frequency.rawValue
        self.nextDueDate = nextDueDate
        self.notes = notes
        self.isEnabled = true
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isSynced = false
        self.serverReminderId = nil
        self.needsSync = true
    }
    
    var type: ReminderType {
        ReminderType(rawValue: reminderType) ?? .other
    }
    
    var frequencyType: ReminderFrequency {
        ReminderFrequency(rawValue: frequency) ?? .once
    }
    
    var isDue: Bool {
        nextDueDate <= Date()
    }
    
    var daysUntilDue: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: nextDueDate)
        return components.day ?? 0
    }
    
    func markCompleted() {
        lastCompletedDate = Date()
        updatedAt = Date()
        needsSync = true
        
        // Calculate next due date based on frequency
        if let component = frequencyType.calendarComponent {
            let interval = frequencyType.intervalValue
            if let newDate = Calendar.current.date(byAdding: component, value: interval, to: Date()) {
                nextDueDate = newDate
            }
        }
    }
}
