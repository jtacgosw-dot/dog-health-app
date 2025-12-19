import Foundation
import SwiftData

struct PetHealthScore {
    let overallScore: Int
    let activityScore: Int
    let nutritionScore: Int
    let wellnessScore: Int
    let consistencyScore: Int
    
    var scoreColor: String {
        switch overallScore {
        case 80...100: return "green"
        case 60..<80: return "yellow"
        default: return "red"
        }
    }
    
    var scoreLabel: String {
        switch overallScore {
        case 90...100: return "Excellent"
        case 80..<90: return "Great"
        case 70..<80: return "Good"
        case 60..<70: return "Fair"
        default: return "Needs Attention"
        }
    }
    
    static var empty: PetHealthScore {
        PetHealthScore(
            overallScore: 0,
            activityScore: 0,
            nutritionScore: 0,
            wellnessScore: 0,
            consistencyScore: 0
        )
    }
}

class PetHealthScoreCalculator {
    private let modelContext: ModelContext
    private let dogId: String
    
    init(modelContext: ModelContext, dogId: String) {
        self.modelContext = modelContext
        self.dogId = dogId
    }
    
    func calculateScore() -> PetHealthScore {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        let descriptor = FetchDescriptor<HealthLogEntry>(
            predicate: #Predicate { entry in
                entry.dogId == dogId && entry.timestamp >= weekAgo
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        guard let entries = try? modelContext.fetch(descriptor) else {
            return .empty
        }
        
        if entries.isEmpty {
            return PetHealthScore(
                overallScore: 50,
                activityScore: 50,
                nutritionScore: 50,
                wellnessScore: 50,
                consistencyScore: 50
            )
        }
        
        let activityScore = calculateActivityScore(entries: entries)
        let nutritionScore = calculateNutritionScore(entries: entries)
        let wellnessScore = calculateWellnessScore(entries: entries)
        let consistencyScore = calculateConsistencyScore(entries: entries)
        
        let overallScore = (activityScore + nutritionScore + wellnessScore + consistencyScore) / 4
        
        return PetHealthScore(
            overallScore: overallScore,
            activityScore: activityScore,
            nutritionScore: nutritionScore,
            wellnessScore: wellnessScore,
            consistencyScore: consistencyScore
        )
    }
    
    private func calculateActivityScore(entries: [HealthLogEntry]) -> Int {
        let activityEntries = entries.filter { 
            $0.logType == "walk" || $0.logType == "playtime" 
        }
        
        let daysWithActivity = Set(activityEntries.map { 
            Calendar.current.startOfDay(for: $0.timestamp) 
        }).count
        
        let baseScore = min(100, daysWithActivity * 15)
        
        var totalMinutes = 0
        for entry in activityEntries {
            if let duration = entry.duration, let mins = Int(duration) {
                totalMinutes += mins
            }
        }
        
        let minuteBonus = min(20, totalMinutes / 10)
        
        return min(100, baseScore + minuteBonus)
    }
    
    private func calculateNutritionScore(entries: [HealthLogEntry]) -> Int {
        let mealEntries = entries.filter { $0.logType == "meals" }
        let waterEntries = entries.filter { $0.logType == "water" }
        
        let daysWithMeals = Set(mealEntries.map { 
            Calendar.current.startOfDay(for: $0.timestamp) 
        }).count
        
        let mealScore = min(70, daysWithMeals * 10)
        let waterScore = min(30, waterEntries.count * 5)
        
        return mealScore + waterScore
    }
    
    private func calculateWellnessScore(entries: [HealthLogEntry]) -> Int {
        let symptomEntries = entries.filter { $0.logType == "symptom" }
        let moodEntries = entries.filter { $0.logType == "mood" }
        
        var score = 100
        
        for symptom in symptomEntries {
            if let severity = symptom.severityLevel {
                score -= severity * 5
            } else {
                score -= 10
            }
        }
        
        if !moodEntries.isEmpty {
            let avgMood = moodEntries.compactMap { $0.moodLevel }.reduce(0, +) / max(1, moodEntries.count)
            score += (avgMood - 2) * 5
        }
        
        return max(0, min(100, score))
    }
    
    private func calculateConsistencyScore(entries: [HealthLogEntry]) -> Int {
        let calendar = Calendar.current
        var daysWithLogs = Set<Date>()
        
        for entry in entries {
            daysWithLogs.insert(calendar.startOfDay(for: entry.timestamp))
        }
        
        return min(100, daysWithLogs.count * 15)
    }
}
