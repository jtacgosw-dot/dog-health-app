import SwiftUI
import SwiftData

struct HealthDigestView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allLogs: [HealthLogEntry]
    
    @State private var isGeneratingDigest = false
    @State private var aiDigest: String?
    @State private var errorMessage: String?
    
    private var dogName: String {
        appState.currentDog?.name ?? "your pet"
    }
    
    private var weeklyLogs: [HealthLogEntry] {
        guard let dogId = appState.currentDog?.id else { return [] }
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return allLogs.filter { $0.dogId == dogId && $0.timestamp >= sevenDaysAgo }
    }
    
    private var digestData: DigestData {
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: now) ?? now
        
        guard let dogId = appState.currentDog?.id else {
            return DigestData.empty
        }
        
        let thisWeekLogs = allLogs.filter { $0.dogId == dogId && $0.timestamp >= sevenDaysAgo }
        let lastWeekLogs = allLogs.filter { $0.dogId == dogId && $0.timestamp >= fourteenDaysAgo && $0.timestamp < sevenDaysAgo }
        
                let thisWeekMeals = thisWeekLogs.filter { $0.logType == "Meals" }.count
                let _ = lastWeekLogs.filter { $0.logType == "Meals" }.count
        
        let thisWeekActivity = thisWeekLogs
            .filter { $0.logType == "Walk" || $0.logType == "Playtime" }
            .compactMap { Int($0.duration ?? "0") }
            .reduce(0, +)
        let lastWeekActivity = lastWeekLogs
            .filter { $0.logType == "Walk" || $0.logType == "Playtime" }
            .compactMap { Int($0.duration ?? "0") }
            .reduce(0, +)
        
                let thisWeekSymptoms = thisWeekLogs.filter { $0.logType == "Symptom" }
                let _ = lastWeekLogs.filter { $0.logType == "Symptom" }
        
        let thisWeekMoods = thisWeekLogs.filter { $0.logType == "Mood" }.compactMap { $0.moodLevel }
        let avgMood = thisWeekMoods.isEmpty ? nil : Double(thisWeekMoods.reduce(0, +)) / Double(thisWeekMoods.count)
        
        let thisWeekDigestion = thisWeekLogs.filter { $0.logType == "Digestion" }
        let poorDigestion = thisWeekDigestion.filter {
            ($0.digestionQuality ?? "").lowercased().contains("poor") ||
            ($0.digestionQuality ?? "").lowercased().contains("bad") ||
            ($0.notes).lowercased().contains("diarrhea") ||
            ($0.notes).lowercased().contains("vomit")
        }
        
        var patterns: [DigestPattern] = []
        
        if thisWeekActivity < lastWeekActivity && lastWeekActivity > 0 {
            let decrease = Int(Double(lastWeekActivity - thisWeekActivity) / Double(lastWeekActivity) * 100)
            if decrease >= 20 {
                patterns.append(DigestPattern(
                    type: .warning,
                    title: "Activity Decreased",
                    description: "Activity is down \(decrease)% from last week (\(thisWeekActivity) min vs \(lastWeekActivity) min)",
                    recommendation: "Try to increase walks or playtime to maintain \(dogName)'s fitness"
                ))
            }
        } else if thisWeekActivity > lastWeekActivity && thisWeekActivity > 0 {
            let increase = lastWeekActivity > 0 ? Int(Double(thisWeekActivity - lastWeekActivity) / Double(lastWeekActivity) * 100) : 100
            if increase >= 20 {
                patterns.append(DigestPattern(
                    type: .positive,
                    title: "Activity Increased",
                    description: "Great job! Activity is up \(increase)% from last week",
                    recommendation: "Keep up the good work with regular exercise"
                ))
            }
        }
        
        if thisWeekSymptoms.count >= 2 {
            let symptomTypes = Dictionary(grouping: thisWeekSymptoms, by: { $0.symptomType ?? "Unknown" })
            for (type, symptoms) in symptomTypes where symptoms.count >= 2 {
                patterns.append(DigestPattern(
                    type: .alert,
                    title: "Recurring Symptom",
                    description: "\(type) occurred \(symptoms.count) times this week",
                    recommendation: "Consider consulting your vet if this continues"
                ))
            }
        }
        
        if poorDigestion.count >= 2 {
            patterns.append(DigestPattern(
                type: .alert,
                title: "Digestive Issues",
                description: "\(poorDigestion.count) instances of digestive problems this week",
                recommendation: "Review recent diet changes or new foods that might be causing issues"
            ))
        }
        
        if let mood = avgMood, mood < 3.0 {
            patterns.append(DigestPattern(
                type: .warning,
                title: "Low Mood Trend",
                description: "Average mood this week is \(String(format: "%.1f", mood))/5",
                recommendation: "Consider extra enrichment activities or check for underlying health issues"
            ))
        }
        
        if thisWeekMeals < 14 {
            patterns.append(DigestPattern(
                type: .info,
                title: "Meal Logging",
                description: "Only \(thisWeekMeals) meals logged this week",
                recommendation: "Try to log all meals for better nutrition tracking"
            ))
        }
        
        let mealLogs = thisWeekLogs.filter { $0.logType == "Meals" }
        let symptomDates = Set(thisWeekSymptoms.map { calendar.startOfDay(for: $0.timestamp) })
        let digestionDates = Set(poorDigestion.map { calendar.startOfDay(for: $0.timestamp) })
        let problemDates = symptomDates.union(digestionDates)
        
        if !problemDates.isEmpty {
            let mealsOnProblemDays = mealLogs.filter { problemDates.contains(calendar.startOfDay(for: $0.timestamp)) }
            let mealTypes = Set(mealsOnProblemDays.compactMap { $0.mealType }.filter { !$0.isEmpty })
            if !mealTypes.isEmpty {
                patterns.append(DigestPattern(
                    type: .info,
                    title: "Possible Food Correlation",
                    description: "Symptoms occurred on days with: \(mealTypes.prefix(3).joined(separator: ", "))",
                    recommendation: "Consider tracking specific ingredients to identify potential triggers"
                ))
            }
        }
        
        return DigestData(
            totalLogs: thisWeekLogs.count,
            mealsLogged: thisWeekMeals,
            activityMinutes: thisWeekActivity,
            symptomsCount: thisWeekSymptoms.count,
            averageMood: avgMood,
            patterns: patterns,
            weekOverWeekChange: lastWeekLogs.isEmpty ? nil : Double(thisWeekLogs.count - lastWeekLogs.count) / Double(max(lastWeekLogs.count, 1)) * 100
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        
                        weeklyStatsSection
                        
                        if !digestData.patterns.isEmpty {
                            patternsSection
                        }
                        
                        aiInsightsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Weekly Health Digest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
            .onAppear {
                if aiDigest == nil && !weeklyLogs.isEmpty {
                    generateAIDigest()
                }
            }
        }
        .buttonStyle(.plain)
        .preferredColorScheme(.light)
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 50))
                .foregroundColor(.petlyDarkGreen)
            
            Text("\(dogName)'s Weekly Summary")
                .font(.petlyTitle(24))
                .foregroundColor(.petlyDarkGreen)
            
            Text(dateRangeString)
                .font(.petlyBody(14))
                .foregroundColor(.petlyFormIcon)
        }
        .padding()
    }
    
    private var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    private var weeklyStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week at a Glance")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            HStack(spacing: 12) {
                StatBox(title: "Logs", value: "\(digestData.totalLogs)", icon: "list.bullet", color: .blue)
                StatBox(title: "Meals", value: "\(digestData.mealsLogged)", icon: "fork.knife", color: .orange)
                StatBox(title: "Activity", value: "\(digestData.activityMinutes)m", icon: "figure.walk", color: .green)
                StatBox(title: "Symptoms", value: "\(digestData.symptomsCount)", icon: "stethoscope", color: digestData.symptomsCount > 0 ? .red : .gray)
            }
            
            if let change = digestData.weekOverWeekChange {
                HStack {
                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .foregroundColor(change >= 0 ? .green : .orange)
                    Text("\(abs(Int(change)))% \(change >= 0 ? "more" : "fewer") logs than last week")
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.petlyLightGreen.opacity(0.8), Color.petlyLightGreen.opacity(0.4)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    private var patternsSection:some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Patterns & Trends")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            ForEach(digestData.patterns) { pattern in
                PatternCard(pattern: pattern)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.petlyLightGreen.opacity(0.8), Color.petlyLightGreen.opacity(0.4)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    private var aiInsightsSection:some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.petlyDarkGreen)
                Text("AI Health Insights")
                    .font(.petlyBodyMedium(16))
                    .foregroundColor(.petlyDarkGreen)
                
                Spacer()
                
                if !isGeneratingDigest && aiDigest != nil {
                    Button(action: generateAIDigest) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
            
            if isGeneratingDigest {
                HStack {
                    ProgressView()
                        .tint(.petlyDarkGreen)
                    Text("Analyzing health data...")
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyFormIcon)
                }
                .padding()
            } else if let digest = aiDigest {
                Text(digest)
                    .font(.petlyBody(14))
                    .foregroundColor(.petlyDarkGreen)
                    .padding()
                    .background(Color.petlyLightGreen.opacity(0.5))
                    .cornerRadius(12)
                
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.petlyFormIcon)
                        Text("Disclaimer")
                            .font(.petlyBody(10))
                            .foregroundColor(.petlyFormIcon)
                    }
                    
                    Text("AI insights are for informational purposes only and do not constitute veterinary advice. Consult your vet for health concerns.")
                        .font(.petlyBody(10))
                        .foregroundColor(.petlyFormIcon)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
            } else if let error = errorMessage {
                Text(error)
                    .font(.petlyBody(14))
                    .foregroundColor(.red)
                    .padding()
            } else if weeklyLogs.isEmpty {
                Text("Start logging health data to receive personalized AI insights about \(dogName)'s health patterns.")
                    .font(.petlyBody(14))
                    .foregroundColor(.petlyFormIcon)
                    .padding()
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.petlyLightGreen.opacity(0.8), Color.petlyLightGreen.opacity(0.4)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    private func generateAIDigest(){
        guard !weeklyLogs.isEmpty else { return }
        
        isGeneratingDigest = true
        errorMessage = nil
        
        Task {
            do {
                let prompt = buildDigestPrompt()
                let dogProfile = buildDogProfile()
                let healthLogs = buildHealthLogs()
                
                let response = try await APIService.shared.sendChatMessage(
                    message: prompt,
                    conversationId: nil,
                    dogId: appState.currentDog?.id,
                    dogProfile: dogProfile,
                    healthLogs: healthLogs
                )
                
                await MainActor.run {
                    aiDigest = response.message.content
                    isGeneratingDigest = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Unable to generate insights. Please try again later."
                    isGeneratingDigest = false
                }
            }
        }
    }
    
    private func buildDigestPrompt() -> String {
        return """
        Please provide a brief weekly health digest summary for \(dogName). Focus on:
        1. Overall health status this week
        2. Any concerning patterns you notice
        3. One specific actionable recommendation
        
        Keep it concise (2-3 short paragraphs) and encouraging. Don't repeat data I can already see - give me insights and recommendations.
        """
    }
    
    private func buildDogProfile() -> ChatDogProfile? {
        guard let dog = appState.currentDog else { return nil }
        return ChatDogProfile(
            name: dog.name,
            breed: dog.breed,
            age: dog.age,
            weight: dog.weight,
            healthConcerns: dog.healthConcerns.isEmpty ? nil : dog.healthConcerns,
            allergies: dog.allergies.isEmpty ? nil : dog.allergies,
            energyLevel: dog.energyLevel,
            friendliness: dog.friendliness,
            trainability: dog.trainability,
            personalityTraits: dog.personalityTraits?.isEmpty == true ? nil : dog.personalityTraits,
            feedingSchedule: dog.feedingSchedule,
            foodType: dog.foodType,
            portionSize: dog.portionSize,
            foodAllergies: dog.foodAllergies,
            sex: dog.sex,
            isNeutered: dog.isNeutered,
            medicalHistory: dog.medicalHistory,
            currentMedications: dog.currentMedications
        )
    }
    
    private func buildHealthLogs() -> [ChatHealthLog]? {
        guard !weeklyLogs.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        return weeklyLogs.map { log in
            ChatHealthLog(
                logType: log.logType,
                timestamp: formatter.string(from: log.timestamp),
                notes: log.notes.isEmpty ? nil : log.notes,
                mealType: log.mealType,
                amount: log.amount,
                duration: log.duration,
                moodLevel: log.moodLevel,
                symptomType: log.symptomType,
                severityLevel: log.severityLevel,
                digestionQuality: log.digestionQuality,
                activityType: log.activityType,
                supplementName: log.supplementName,
                dosage: log.dosage,
                appointmentType: log.appointmentType,
                location: log.location,
                groomingType: log.groomingType,
                treatName: log.treatName,
                waterAmount: log.waterAmount
            )
        }
    }
}

struct DigestData {
    let totalLogs: Int
    let mealsLogged: Int
    let activityMinutes: Int
    let symptomsCount: Int
    let averageMood: Double?
    let patterns: [DigestPattern]
    let weekOverWeekChange: Double?
    
    static var empty: DigestData {
        DigestData(totalLogs: 0, mealsLogged: 0, activityMinutes: 0, symptomsCount: 0, averageMood: nil, patterns: [], weekOverWeekChange: nil)
    }
}

struct DigestPattern: Identifiable {
    let id = UUID()
    let type: PatternType
    let title: String
    let description: String
    let recommendation: String
    
    enum PatternType {
        case positive, warning, alert, info
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .warning: return .orange
            case .alert: return .red
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .positive: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .alert: return "exclamationmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            Text(title)
                .font(.petlyBody(10))
                .foregroundColor(.petlyFormIcon)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.petlyLightGreen.opacity(0.6))
        .cornerRadius(12)
    }
}

struct PatternCard:View {
    let pattern: DigestPattern
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: pattern.type.icon)
                .font(.system(size: 24))
                .foregroundColor(pattern.type.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.title)
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.petlyDarkGreen)
                Text(pattern.description)
                    .font(.petlyBody(12))
                    .foregroundColor(.petlyFormIcon)
                Text(pattern.recommendation)
                    .font(.petlyBody(12))
                    .foregroundColor(.petlyDarkGreen)
                    .italic()
                    .padding(.top, 2)
            }
            
            Spacer()
        }
        .padding()
        .background(pattern.type.color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    HealthDigestView()
        .environmentObject(AppState())
}
