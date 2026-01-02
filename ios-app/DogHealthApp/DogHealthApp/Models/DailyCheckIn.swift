import Foundation
import SwiftData

@Model
final class DailyCheckIn {
    var id: UUID
    var dogId: String
    var date: Date
    var completedAt: Date
    
    var hasSymptoms: Bool
    var symptomsNotes: String?
    var mealsLogged: Bool
    var activityLogged: Bool
    var waterLogged: Bool
    var overallMood: Int?
    var additionalNotes: String?
    
    init(
        id: UUID = UUID(),
        dogId: String,
        date: Date = Date(),
        completedAt: Date = Date(),
        hasSymptoms: Bool = false,
        symptomsNotes: String? = nil,
        mealsLogged: Bool = false,
        activityLogged: Bool = false,
        waterLogged: Bool = false,
        overallMood: Int? = nil,
        additionalNotes: String? = nil
    ) {
        self.id = id
        self.dogId = dogId
        self.date = Calendar.current.startOfDay(for: date)
        self.completedAt = completedAt
        self.hasSymptoms = hasSymptoms
        self.symptomsNotes = symptomsNotes
        self.mealsLogged = mealsLogged
        self.activityLogged = activityLogged
        self.waterLogged = waterLogged
        self.overallMood = overallMood
        self.additionalNotes = additionalNotes
    }
    
    var isComplete: Bool {
        return true
    }
    
    var completionScore: Int {
        var score = 0
        if mealsLogged { score += 1 }
        if activityLogged { score += 1 }
        if waterLogged { score += 1 }
        if overallMood != nil { score += 1 }
        return score
    }
}

struct CareConsistency {
    let checkInsThisWeek: Int
    let totalDaysThisWeek: Int
    let checkInsThisMonth: Int
    let totalDaysThisMonth: Int
    let currentStreak: Int
    let longestStreak: Int
    
    var weeklyPercentage: Double {
        guard totalDaysThisWeek > 0 else { return 0 }
        return Double(checkInsThisWeek) / Double(totalDaysThisWeek) * 100
    }
    
    var monthlyPercentage: Double {
        guard totalDaysThisMonth > 0 else { return 0 }
        return Double(checkInsThisMonth) / Double(totalDaysThisMonth) * 100
    }
    
    var consistencyLevel: String {
        let percentage = weeklyPercentage
        if percentage >= 85 { return "Excellent" }
        if percentage >= 70 { return "Good" }
        if percentage >= 50 { return "Building" }
        return "Getting Started"
    }
    
    var consistencyDescription: String {
        if checkInsThisWeek == 0 {
            return "Start your first daily health review"
        }
        return "\(checkInsThisWeek) of \(totalDaysThisWeek) days this week"
    }
}

struct HealthMilestone: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let isAchieved: Bool
    let achievedDate: Date?
    let progress: Double
    
    static let allMilestones: [HealthMilestone] = [
        HealthMilestone(
            id: "first_checkin",
            title: "First Health Review",
            description: "Complete your first daily health review",
            icon: "checkmark.circle.fill",
            isAchieved: false,
            achievedDate: nil,
            progress: 0
        ),
        HealthMilestone(
            id: "week_complete",
            title: "Full Week Tracked",
            description: "Complete 7 consecutive days of health reviews",
            icon: "calendar.badge.checkmark",
            isAchieved: false,
            achievedDate: nil,
            progress: 0
        ),
        HealthMilestone(
            id: "month_complete",
            title: "30-Day Trend Unlocked",
            description: "Track for 30 days to unlock monthly health trends",
            icon: "chart.line.uptrend.xyaxis",
            isAchieved: false,
            achievedDate: nil,
            progress: 0
        ),
        HealthMilestone(
            id: "care_calendar_setup",
            title: "Preventative Care Set",
            description: "Set up your pet's preventative care schedule",
            icon: "calendar.badge.plus",
            isAchieved: false,
            achievedDate: nil,
            progress: 0
        ),
        HealthMilestone(
            id: "insights_unlocked",
            title: "Insights Unlocked",
            description: "Log enough data to generate personalized insights",
            icon: "lightbulb.fill",
            isAchieved: false,
            achievedDate: nil,
            progress: 0
        )
    ]
}
