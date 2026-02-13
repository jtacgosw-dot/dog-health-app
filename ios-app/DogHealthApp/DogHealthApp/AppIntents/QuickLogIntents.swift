import AppIntents
import SwiftUI

struct LogMealIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Meal"
    static var description = IntentDescription("Log a meal for your pet")
    
    @Parameter(title: "Meal Type")
    var mealType: MealTypeEnum
    
    @Parameter(title: "Amount", default: "")
    var amount: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$mealType) meal") {
            \.$amount
        }
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let sharedDefaults = UserDefaults(suiteName: "group.com.petly.doghealthapp")
        
        let logData: [String: Any] = [
            "type": "Meals",
            "mealType": mealType.rawValue,
            "amount": amount,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let encoded = try? JSONSerialization.data(withJSONObject: logData) {
            sharedDefaults?.set(encoded, forKey: "pendingQuickLog")
        }
        
        sharedDefaults?.set("Meals", forKey: "lastLogType")
        sharedDefaults?.set(Date(), forKey: "lastLogTime")
        
        return .result(dialog: "Logged \(mealType.rawValue) meal for your pet!")
    }
}

struct LogWalkIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Walk"
    static var description = IntentDescription("Log a walk for your pet")
    
    @Parameter(title: "Duration (minutes)")
    var duration: Int
    
    static var parameterSummary: some ParameterSummary {
        Summary("Log a \(\.$duration) minute walk")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let sharedDefaults = UserDefaults(suiteName: "group.com.petly.doghealthapp")
        
        let logData: [String: Any] = [
            "type": "Walk",
            "duration": "\(duration)",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let encoded = try? JSONSerialization.data(withJSONObject: logData) {
            sharedDefaults?.set(encoded, forKey: "pendingQuickLog")
        }
        
        sharedDefaults?.set("Walk", forKey: "lastLogType")
        sharedDefaults?.set(Date(), forKey: "lastLogTime")
        
        return .result(dialog: "Logged a \(duration) minute walk!")
    }
}

struct LogWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Water"
    static var description = IntentDescription("Log water intake for your pet")
    
    @Parameter(title: "Amount", default: "Full bowl")
    var amount: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Log water intake: \(\.$amount)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let sharedDefaults = UserDefaults(suiteName: "group.com.petly.doghealthapp")
        
        let logData: [String: Any] = [
            "type": "Water",
            "amount": amount,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let encoded = try? JSONSerialization.data(withJSONObject: logData) {
            sharedDefaults?.set(encoded, forKey: "pendingQuickLog")
        }
        
        sharedDefaults?.set("Water", forKey: "lastLogType")
        sharedDefaults?.set(Date(), forKey: "lastLogTime")
        
        return .result(dialog: "Logged water intake for your pet!")
    }
}

struct LogTreatIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Treat"
    static var description = IntentDescription("Log a treat for your pet")
    
    @Parameter(title: "Treat Name", default: "Treat")
    var treatName: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Log treat: \(\.$treatName)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let sharedDefaults = UserDefaults(suiteName: "group.com.petly.doghealthapp")
        
        let logData: [String: Any] = [
            "type": "Treat",
            "treatName": treatName,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let encoded = try? JSONSerialization.data(withJSONObject: logData) {
            sharedDefaults?.set(encoded, forKey: "pendingQuickLog")
        }
        
        sharedDefaults?.set("Treat", forKey: "lastLogType")
        sharedDefaults?.set(Date(), forKey: "lastLogTime")
        
        return .result(dialog: "Logged treat for your pet!")
    }
}

struct LogMedicationIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Medication"
    static var description = IntentDescription("Log medication given to your pet")
    
    @Parameter(title: "Medication Name")
    var medicationName: String
    
    @Parameter(title: "Dosage", default: "")
    var dosage: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Log medication: \(\.$medicationName)") {
            \.$dosage
        }
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let sharedDefaults = UserDefaults(suiteName: "group.com.petly.doghealthapp")
        
        let logData: [String: Any] = [
            "type": "Supplements",
            "supplementName": medicationName,
            "dosage": dosage,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let encoded = try? JSONSerialization.data(withJSONObject: logData) {
            sharedDefaults?.set(encoded, forKey: "pendingQuickLog")
        }
        
        sharedDefaults?.set("Supplements", forKey: "lastLogType")
        sharedDefaults?.set(Date(), forKey: "lastLogTime")
        
        return .result(dialog: "Logged \(medicationName) for your pet!")
    }
}

enum MealTypeEnum: String, AppEnum {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Meal Type"
    
    static var caseDisplayRepresentations: [MealTypeEnum: DisplayRepresentation] = [
        .breakfast: "Breakfast",
        .lunch: "Lunch",
        .dinner: "Dinner",
        .snack: "Snack"
    ]
}

struct DogHealthAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogMealIntent(),
            phrases: [
                "Log meal in \(.applicationName)",
                "Log \(\.$mealType) in \(.applicationName)",
                "Record meal for my pet in \(.applicationName)"
            ],
            shortTitle: "Log Meal",
            systemImageName: "fork.knife"
        )
        
        AppShortcut(
            intent: LogWalkIntent(),
            phrases: [
                "Log walk in \(.applicationName)",
                "Record walk in \(.applicationName)",
                "Log a walk in \(.applicationName)"
            ],
            shortTitle: "Log Walk",
            systemImageName: "figure.walk"
        )
        
        AppShortcut(
            intent: LogWaterIntent(),
            phrases: [
                "Log water in \(.applicationName)",
                "Record water intake in \(.applicationName)"
            ],
            shortTitle: "Log Water",
            systemImageName: "drop.fill"
        )
        
        AppShortcut(
            intent: LogTreatIntent(),
            phrases: [
                "Log treat in \(.applicationName)",
                "Record treat in \(.applicationName)"
            ],
            shortTitle: "Log Treat",
            systemImageName: "gift.fill"
        )
        
        AppShortcut(
            intent: LogMedicationIntent(),
            phrases: [
                "Log medication in \(.applicationName)",
                "Record medication in \(.applicationName)",
                "Log a medication in \(.applicationName)"
            ],
            shortTitle: "Log Medication",
            systemImageName: "pills.fill"
        )
    }
}
