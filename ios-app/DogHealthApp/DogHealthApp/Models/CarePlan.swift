import Foundation
import SwiftData
import SwiftUI

@Model
final class CarePlan {
    var id: UUID
    var dogId: String
    var title: String
    var goalTypeRaw: String
    var startDate: Date
    var endDate: Date
    var planDescription: String
    var isActive: Bool
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade) var tasks: [CarePlanTask]
    @Relationship(deleteRule: .cascade) var milestones: [CarePlanMilestone]
    
    var goalType: CarePlanGoalType {
        get { CarePlanGoalType(rawValue: goalTypeRaw) ?? .custom }
        set { goalTypeRaw = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        dogId: String,
        title: String,
        goalType: CarePlanGoalType,
        startDate: Date = Date(),
        endDate: Date,
        planDescription: String = "",
        isActive: Bool = true
    ) {
        self.id = id
        self.dogId = dogId
        self.title = title
        self.goalTypeRaw = goalType.rawValue
        self.startDate = startDate
        self.endDate = endDate
        self.planDescription = planDescription
        self.isActive = isActive
        self.createdAt = Date()
        self.tasks = []
        self.milestones = []
    }
}

@Model
final class CarePlanTask {
    var id: UUID
    var title: String
    var taskDescription: String?
    var isDaily: Bool
    var isCompleted: Bool
    var completedDate: Date?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        taskDescription: String? = nil,
        isDaily: Bool = true,
        isCompleted: Bool = false,
        completedDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.isDaily = isDaily
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.createdAt = Date()
    }
}

@Model
final class CarePlanMilestone {
    var id: UUID
    var day: Int
    var milestoneDescription: String
    var targetDate: Date
    var isAchieved: Bool
    var achievedDate: Date?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        day: Int,
        milestoneDescription: String,
        targetDate: Date,
        isAchieved: Bool = false,
        achievedDate: Date? = nil
    ) {
        self.id = id
        self.day = day
        self.milestoneDescription = milestoneDescription
        self.targetDate = targetDate
        self.isAchieved = isAchieved
        self.achievedDate = achievedDate
        self.createdAt = Date()
    }
}

enum CarePlanGoalType: String, CaseIterable {
    case weightLoss = "Weight Loss"
    case weightGain = "Weight Gain"
    case allergyManagement = "Allergy Management"
    case digestiveHealth = "Digestive Health"
    case anxietyReduction = "Anxiety Reduction"
    case postSurgeryRecovery = "Post-Surgery Recovery"
    case seniorCare = "Senior Care"
    case puppyDevelopment = "Puppy Development"
    case skinCoatHealth = "Skin & Coat Health"
    case dentalHealth = "Dental Health"
    case activityIncrease = "Increase Activity"
    case custom = "Custom Goal"
    
    var icon: String {
        switch self {
        case .weightLoss: return "arrow.down.circle.fill"
        case .weightGain: return "arrow.up.circle.fill"
        case .allergyManagement: return "allergens"
        case .digestiveHealth: return "stomach"
        case .anxietyReduction: return "heart.circle.fill"
        case .postSurgeryRecovery: return "bandage.fill"
        case .seniorCare: return "figure.walk.circle.fill"
        case .puppyDevelopment: return "pawprint.fill"
        case .skinCoatHealth: return "sparkles"
        case .dentalHealth: return "mouth.fill"
        case .activityIncrease: return "figure.run"
        case .custom: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .weightLoss: return .orange
        case .weightGain: return .green
        case .allergyManagement: return .purple
        case .digestiveHealth: return .brown
        case .anxietyReduction: return .pink
        case .postSurgeryRecovery: return .red
        case .seniorCare: return .gray
        case .puppyDevelopment: return .yellow
        case .skinCoatHealth: return .cyan
        case .dentalHealth: return .mint
        case .activityIncrease: return .blue
        case .custom: return .indigo
        }
    }
}
