import SwiftUI
import SwiftData

struct SmartInsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @Query(sort: \HealthLogEntry.timestamp, order: .reverse) private var allLogs: [HealthLogEntry]
    @Query private var checkIns: [DailyCheckIn]
    
    private var dogId: String {
        appState.currentDog?.id ?? ""
    }
    
    private var dogName: String {
        appState.currentDog?.name ?? "your pet"
    }
    
    private var dogLogs: [HealthLogEntry] {
        allLogs.filter { $0.dogId == dogId }
    }
    
    private var insights: [HealthInsight] {
        generateInsights()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    
                    if insights.isEmpty {
                        emptyStateSection
                    } else {
                        insightsSection
                    }
                    
                    dataQualitySection
                }
                .padding()
            }
            .background(Color.petlyBackground)
            .navigationTitle("Health Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .preferredColorScheme(.light)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Insights for \(dogName)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Patterns detected from your logged data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.petlyLightGreen)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundColor(.petlyDarkGreen)
                }
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
    
    private var emptyStateSection:some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Not enough data yet")
                .font(.headline)
            
            Text("Keep logging \(dogName)'s health data to unlock personalized insights. We need at least 7 days of data to detect patterns.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Log meals, activity, symptoms, and mood daily")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.petlyLightGreen)
            .cornerRadius(10)
        }
        .padding(.vertical, 32)
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Insights")
                .font(.headline)
            
            ForEach(insights) { insight in
                HealthInsightCard(insight: insight)
            }
        }
    }
    
    private var dataQualitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Quality")
                .font(.headline)
            
            let stats = calculateDataStats()
            
            VStack(spacing: 12) {
                DataStatRow(
                    icon: "calendar",
                    title: "Days tracked",
                    value: "\(stats.daysTracked)",
                    subtitle: stats.daysTracked >= 7 ? "Great for insights!" : "Need 7+ days"
                )
                
                DataStatRow(
                    icon: "fork.knife",
                    title: "Meals logged",
                    value: "\(stats.mealsLogged)",
                    subtitle: "This month"
                )
                
                DataStatRow(
                    icon: "figure.walk",
                    title: "Activities logged",
                    value: "\(stats.activitiesLogged)",
                    subtitle: "This month"
                )
                
                DataStatRow(
                    icon: "heart.text.square",
                    title: "Symptoms recorded",
                    value: "\(stats.symptomsLogged)",
                    subtitle: "This month"
                )
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.petlyLightGreen.opacity(0.8), Color.petlyLightGreen.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }
    
    private func generateInsights()-> [HealthInsight] {
        var insights: [HealthInsight] = []
        let calendar = Calendar.current
        let now = Date()
        
        let last7Days = dogLogs.filter { log in
            guard let daysAgo = calendar.dateComponents([.day], from: log.timestamp, to: now).day else { return false }
            return daysAgo <= 7
        }
        
        let last14Days = dogLogs.filter { log in
            guard let daysAgo = calendar.dateComponents([.day], from: log.timestamp, to: now).day else { return false }
            return daysAgo <= 14
        }
        
        let thisWeekActivity = last7Days.filter { $0.logType == "Walk" || $0.logType == "Playtime" }
        let lastWeekActivity = last14Days.filter { log in
            guard let daysAgo = calendar.dateComponents([.day], from: log.timestamp, to: now).day else { return false }
            return daysAgo > 7 && daysAgo <= 14 && (log.logType == "Walk" || log.logType == "Playtime")
        }
        
        if !thisWeekActivity.isEmpty && !lastWeekActivity.isEmpty {
            let thisWeekMinutes = thisWeekActivity.compactMap { Int($0.duration ?? "0") }.reduce(0, +)
            let lastWeekMinutes = lastWeekActivity.compactMap { Int($0.duration ?? "0") }.reduce(0, +)
            
            if lastWeekMinutes > 0 {
                let percentChange = Double(thisWeekMinutes - lastWeekMinutes) / Double(lastWeekMinutes) * 100
                
                if abs(percentChange) >= 15 {
                    let isUp = percentChange > 0
                    insights.append(HealthInsight(
                        id: "activity_trend",
                        type: isUp ? .positive : .attention,
                        title: "Activity \(isUp ? "Up" : "Down") \(Int(abs(percentChange)))%",
                        description: "\(dogName)'s activity is \(isUp ? "higher" : "lower") than last week. \(isUp ? "Great job keeping active!" : "Consider adding more walks or playtime.")",
                        icon: "figure.walk",
                        actionText: isUp ? nil : "Log Activity"
                    ))
                }
            }
        }
        
        let symptoms = last7Days.filter { $0.logType == "Symptom" }
        if symptoms.count >= 2 {
            let symptomTypes = Dictionary(grouping: symptoms, by: { $0.symptomType ?? "Unknown" })
            if let mostCommon = symptomTypes.max(by: { $0.value.count < $1.value.count }) {
                if mostCommon.value.count >= 2 {
                    insights.append(HealthInsight(
                        id: "recurring_symptom",
                        type: .attention,
                        title: "Recurring: \(mostCommon.key)",
                        description: "\(mostCommon.key) has been logged \(mostCommon.value.count) times this week. Consider discussing with your vet if it persists.",
                        icon: "exclamationmark.triangle",
                        actionText: "View Timeline"
                    ))
                }
            }
        }
        
        let meals = last7Days.filter { $0.logType == "Meals" }
        let mealsByDay = Dictionary(grouping: meals) { meal in
            calendar.startOfDay(for: meal.timestamp)
        }
        
        let daysWithMeals = mealsByDay.count
        if daysWithMeals >= 5 {
            let avgMealsPerDay = Double(meals.count) / Double(daysWithMeals)
            
            if avgMealsPerDay >= 2 && avgMealsPerDay <= 3 {
                insights.append(HealthInsight(
                    id: "consistent_feeding",
                    type: .positive,
                    title: "Consistent Feeding Schedule",
                    description: "\(dogName) is eating regularly with an average of \(String(format: "%.1f", avgMealsPerDay)) meals per day. Consistency is great for digestion!",
                    icon: "fork.knife",
                    actionText: nil
                ))
            }
        }
        
        let dogCheckIns = checkIns.filter { $0.dogId == dogId }
        let recentCheckIns = dogCheckIns.filter { checkIn in
            guard let daysAgo = calendar.dateComponents([.day], from: checkIn.date, to: now).day else { return false }
            return daysAgo <= 7
        }
        
        if recentCheckIns.count >= 5 {
            let avgMood = recentCheckIns.compactMap { $0.overallMood }.reduce(0, +) / max(recentCheckIns.compactMap { $0.overallMood }.count, 1)
            
            if avgMood >= 4 {
                insights.append(HealthInsight(
                    id: "good_mood",
                    type: .positive,
                    title: "Happy Pet!",
                    description: "\(dogName)'s mood has been consistently good this week. Keep up the great care!",
                    icon: "face.smiling",
                    actionText: nil
                ))
            } else if avgMood <= 2 {
                insights.append(HealthInsight(
                    id: "low_mood",
                    type: .attention,
                    title: "Mood Needs Attention",
                    description: "\(dogName)'s mood has been lower than usual. Consider if there have been any changes in routine or environment.",
                    icon: "heart.fill",
                    actionText: "Log Symptoms"
                ))
            }
        }
        
        if dogLogs.count < 10 {
            insights.append(HealthInsight(
                id: "keep_logging",
                type: .info,
                title: "Keep Logging!",
                description: "More data means better insights. Try to log meals, activity, and mood daily for the most accurate health picture.",
                icon: "chart.bar.fill",
                actionText: "Daily Review"
            ))
        }
        
        return insights
    }
    
    private func calculateDataStats() -> DataStats {
        let calendar = Calendar.current
        let now = Date()
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
        
        let monthLogs = dogLogs.filter { $0.timestamp >= monthAgo }
        
        let uniqueDays = Set(monthLogs.map { calendar.startOfDay(for: $0.timestamp) })
        
        return DataStats(
            daysTracked: uniqueDays.count,
            mealsLogged: monthLogs.filter { $0.logType == "Meals" }.count,
            activitiesLogged: monthLogs.filter { $0.logType == "Walk" || $0.logType == "Playtime" }.count,
            symptomsLogged: monthLogs.filter { $0.logType == "Symptom" }.count
        )
    }
}

struct HealthInsight: Identifiable {
    let id: String
    let type: InsightType
    let title: String
    let description: String
    let icon: String
    let actionText: String?
    
    enum InsightType {
        case positive
        case attention
        case info
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .attention: return .orange
            case .info: return .blue
            }
        }
    }
}

struct DataStats {
    let daysTracked: Int
    let mealsLogged: Int
    let activitiesLogged: Int
    let symptomsLogged: Int
}

struct HealthInsightCard: View {
    let insight: HealthInsight
    @State private var showDailyReview = false
    @State private var showTimeline = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(insight.type.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: insight.icon)
                    .font(.title3)
                    .foregroundColor(insight.type.color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let actionText = insight.actionText {
                    Button {
                        handleAction(actionText)
                    } label: {
                        Text(actionText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(insight.type.color)
                    }
                    .padding(.top, 4)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.petlyLightGreen.opacity(0.8), Color.petlyLightGreen.opacity(0.4)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showDailyReview) {
            DailyHealthReviewView()
        }
        .sheet(isPresented: $showTimeline) {
            HealthTimelineView()
        }
    }
    
    private func handleAction(_ action: String) {
        switch action {
        case "Daily Review":
            showDailyReview = true
        case "View Timeline":
            showTimeline = true
        case "Log Activity", "Log Symptoms":
            showDailyReview = true
        default:
            break
        }
    }
}

struct DataStatRow:View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.petlyDarkGreen)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SmartInsightsCard: View {
    @EnvironmentObject var appState: AppState
    @Query(sort: \HealthLogEntry.timestamp, order: .reverse) private var allLogs: [HealthLogEntry]
    
    var onViewInsights: () -> Void
    
    @ScaledMetric(relativeTo: .body) private var cardMinHeight: CGFloat = 130
    private var cappedCardMinHeight: CGFloat { min(cardMinHeight, 180) }
    
    private var dogId: String {
        appState.currentDog?.id ?? ""
    }
    
    private var dogLogs: [HealthLogEntry] {
        allLogs.filter { $0.dogId == dogId }
    }
    
    private var topInsight: String {
        let calendar = Calendar.current
        let now = Date()
        
        let last7Days = dogLogs.filter { log in
            guard let daysAgo = calendar.dateComponents([.day], from: log.timestamp, to: now).day else { return false }
            return daysAgo <= 7
        }
        
        let activities = last7Days.filter { $0.logType == "Walk" || $0.logType == "Playtime" }
        let totalMinutes = activities.compactMap { Int($0.duration ?? "0") }.reduce(0, +)
        
        if totalMinutes > 0 {
            return "\(totalMinutes) min activity this week"
        }
        
        let meals = last7Days.filter { $0.logType == "Meals" }
        if !meals.isEmpty {
            return "\(meals.count) meals logged this week"
        }
        
        return "Start logging to see insights"
    }
    
    var body: some View {
        Button(action: onViewInsights) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundColor(.petlyDarkGreen)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer(minLength: 0)
                
                Text("Smart Insights")
                    .font(.headline)
                    .foregroundColor(.petlyDarkGreen)
                    .minimumScaleFactor(0.8)
                
                Text(topInsight)
                    .font(.caption)
                    .foregroundColor(.petlyFormIcon)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .frame(minHeight: cappedCardMinHeight)
            .background(Color.petlyLightGreen)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SmartInsightsView()
        .environmentObject(AppState())
}
