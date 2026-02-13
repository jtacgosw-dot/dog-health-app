import SwiftUI
import SwiftData

struct AIInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: InsightCategory
    let priority: InsightPriority
    let actionText: String?
    let icon: String
    
    enum InsightCategory: String {
        case health = "Health"
        case activity = "Activity"
        case nutrition = "Nutrition"
        case behavior = "Behavior"
        case reminder = "Reminder"
    }
    
    enum InsightPriority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .blue
            }
        }
    }
}

struct AIInsightsDashboardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allLogs: [HealthLogEntry]
    
    @State private var isAnalyzing = false
    @State private var insights: [AIInsight] = []
    @State private var lastAnalyzedAt: Date?
    
    private var dogLogs: [HealthLogEntry] {
        guard let dogId = appState.currentDog?.id else { return [] }
        return allLogs.filter { $0.dogId == dogId }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        
                        if isAnalyzing {
                            analyzingView
                        } else if insights.isEmpty {
                            emptyStateView
                        } else {
                            insightsListSection
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: analyzeData) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.petlyDarkGreen)
                    }
                    .disabled(isAnalyzing)
                }
            }
            .onAppear {
                if insights.isEmpty {
                    analyzeData()
                }
            }
        }
        .buttonStyle(.plain)
        .preferredColorScheme(.light)
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundColor(.petlyDarkGreen)
            
            Text("AI Health Insights")
                .font(.petlyTitle(24))
                .foregroundColor(.petlyDarkGreen)
            
            if let dogName = appState.currentDog?.name {
                Text("Personalized insights for \(dogName)")
                    .font(.petlyBody(14))
                    .foregroundColor(.secondary)
            }
            
            if let lastAnalyzed = lastAnalyzedAt {
                Text("Last updated: \(lastAnalyzed, style: .relative) ago")
                    .font(.petlyBody(12))
                    .foregroundColor(.petlyFormIcon)
            }
        }
        .padding(.vertical)
    }
    
    private var analyzingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.petlyDarkGreen)
            
            Text("Analyzing health data...")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Looking for patterns and insights")
                .font(.petlyBody(14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.petlyLightGreen)
        .cornerRadius(16)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.petlyFormIcon)
            
            Text("Not Enough Data")
                .font(.petlyBodyMedium(18))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Log more health entries to receive personalized AI insights about your pet's health patterns.")
                .font(.petlyBody(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(Color.petlyLightGreen)
        .cornerRadius(16)
    }
    
    private var insightsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Insights")
                    .font(.petlyBodyMedium(16))
                    .foregroundColor(.petlyDarkGreen)
                
                Spacer()
                
                Text("\(insights.count) insights")
                    .font(.petlyBody(12))
                    .foregroundColor(.petlyFormIcon)
            }
            
            ForEach(insights) { insight in
                AIInsightCard(insight: insight)
            }
        }
    }
    
    private func analyzeData() {
        isAnalyzing = true
        insights = []
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            generateInsights()
            lastAnalyzedAt = Date()
            isAnalyzing = false
        }
    }
    
    private func generateInsights() {
        var newInsights: [AIInsight] = []
        let calendar = Calendar.current
        let now = Date()
        
        // Get logs from last 7 days
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let recentLogs = dogLogs.filter { $0.timestamp >= weekAgo }
        
        // Get logs from last 30 days
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let monthLogs = dogLogs.filter { $0.timestamp >= monthAgo }
        
        // Activity Analysis
        let walkLogs = recentLogs.filter { $0.logType == "Walk" }
        let totalWalkMinutes = walkLogs.compactMap { Int($0.duration ?? "0") }.reduce(0, +)
        let avgDailyWalk = totalWalkMinutes / 7
        
        if avgDailyWalk < 20 && !walkLogs.isEmpty {
            newInsights.append(AIInsight(
                title: "Low Activity Detected",
                description: "Your pet averaged only \(avgDailyWalk) minutes of walks per day this week. Most dogs need 30-60 minutes of daily exercise for optimal health.",
                category: .activity,
                priority: .medium,
                actionText: "Schedule more walks",
                icon: "figure.walk"
            ))
        } else if avgDailyWalk >= 45 {
            newInsights.append(AIInsight(
                title: "Great Exercise Routine!",
                description: "Your pet is getting excellent exercise with an average of \(avgDailyWalk) minutes of walks per day. Keep up the great work!",
                category: .activity,
                priority: .low,
                actionText: nil,
                icon: "star.fill"
            ))
        }
        
        // Meal Pattern Analysis
        let mealLogs = recentLogs.filter { $0.logType == "Meals" }
        let mealsPerDay = Double(mealLogs.count) / 7.0
        
        if mealsPerDay < 1.5 && !mealLogs.isEmpty {
            newInsights.append(AIInsight(
                title: "Inconsistent Feeding",
                description: "You've logged fewer meals than expected this week. Regular feeding schedules help maintain healthy digestion and energy levels.",
                category: .nutrition,
                priority: .medium,
                actionText: "Set meal reminders",
                icon: "fork.knife"
            ))
        }
        
        // Symptom Analysis
        let symptomLogs = monthLogs.filter { $0.logType == "Symptom" }
        if symptomLogs.count >= 3 {
            let symptomTypes = Dictionary(grouping: symptomLogs) { $0.symptomType ?? "Unknown" }
            if let mostCommon = symptomTypes.max(by: { $0.value.count < $1.value.count }) {
                if mostCommon.value.count >= 2 {
                    newInsights.append(AIInsight(
                        title: "Recurring Symptom Pattern",
                        description: "\(mostCommon.key) has been logged \(mostCommon.value.count) times in the past month. Consider discussing this pattern with your veterinarian.",
                        category: .health,
                        priority: .high,
                        actionText: "Schedule vet visit",
                        icon: "stethoscope"
                    ))
                }
            }
        }
        
        // Mood Analysis
        let moodLogs = recentLogs.filter { $0.logType == "Mood" }
        if !moodLogs.isEmpty {
            let avgMood = Double(moodLogs.compactMap { $0.moodLevel }.reduce(0, +)) / Double(moodLogs.count)
            
            if avgMood < 2.5 {
                newInsights.append(AIInsight(
                    title: "Low Mood Trend",
                    description: "Your pet's mood has been lower than usual this week. Consider extra playtime, enrichment activities, or a vet check if this continues.",
                    category: .behavior,
                    priority: .medium,
                    actionText: "Try enrichment activities",
                    icon: "heart.fill"
                ))
            } else if avgMood >= 4 {
                newInsights.append(AIInsight(
                    title: "Happy Pet!",
                    description: "Your pet has been in great spirits! The average mood score this week is \(String(format: "%.1f", avgMood))/5.",
                    category: .behavior,
                    priority: .low,
                    actionText: nil,
                    icon: "face.smiling.fill"
                ))
            }
        }
        
        // Digestion Analysis
        let digestionLogs = recentLogs.filter { $0.logType == "Digestion" }
        let abnormalDigestion = digestionLogs.filter { 
            let quality = $0.digestionQuality?.lowercased() ?? ""
            return quality.contains("diarrhea") || quality.contains("constipated") || quality.contains("soft")
        }
        
        if abnormalDigestion.count >= 2 {
            newInsights.append(AIInsight(
                title: "Digestive Issues Noted",
                description: "You've logged \(abnormalDigestion.count) instances of digestive issues this week. Monitor food intake and consider a bland diet if symptoms persist.",
                category: .health,
                priority: .high,
                actionText: "Review diet",
                icon: "exclamationmark.triangle.fill"
            ))
        }
        
        // Water Intake
        let waterLogs = recentLogs.filter { $0.logType == "Water" }
        if waterLogs.isEmpty && !recentLogs.isEmpty {
            newInsights.append(AIInsight(
                title: "Track Water Intake",
                description: "You haven't logged any water intake this week. Monitoring hydration is important, especially in warm weather or after exercise.",
                category: .reminder,
                priority: .low,
                actionText: "Log water intake",
                icon: "drop.fill"
            ))
        }
        
        // Supplement Consistency
        let supplementLogs = monthLogs.filter { $0.logType == "Supplements" }
        if !supplementLogs.isEmpty {
            let supplementNames = Set(supplementLogs.compactMap { $0.supplementName })
            for supplement in supplementNames {
                let count = supplementLogs.filter { $0.supplementName == supplement }.count
                if count < 20 { // Less than ~daily for a month
                    newInsights.append(AIInsight(
                        title: "Supplement Reminder",
                        description: "\(supplement) has only been logged \(count) times this month. For best results, maintain a consistent supplement schedule.",
                        category: .reminder,
                        priority: .low,
                        actionText: "Set daily reminder",
                        icon: "pills.fill"
                    ))
                    break // Only show one supplement reminder
                }
            }
        }
        
        // No data insight
        if recentLogs.isEmpty {
            newInsights.append(AIInsight(
                title: "Start Logging",
                description: "Begin tracking your pet's health to receive personalized insights. Log meals, walks, symptoms, and more to help us understand your pet's patterns.",
                category: .reminder,
                priority: .low,
                actionText: "Add first log",
                icon: "plus.circle.fill"
            ))
        }
        
        // Sort by priority
        insights = newInsights.sorted { 
            let priorityOrder: [AIInsight.InsightPriority] = [.high, .medium, .low]
            return priorityOrder.firstIndex(of: $0.priority)! < priorityOrder.firstIndex(of: $1.priority)!
        }
    }
}

struct AIInsightCard: View {
    let insight: AIInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(insight.priority.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: insight.icon)
                            .font(.system(size: 20))
                            .foregroundColor(insight.priority.color)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.petlyBodyMedium(16))
                        .foregroundColor(.petlyDarkGreen)
                    
                    Text(insight.category.rawValue)
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                }
                
                Spacer()
                
                Circle()
                    .fill(insight.priority.color)
                    .frame(width: 10, height: 10)
            }
            
            Text(insight.description)
                .font(.petlyBody(14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if let actionText = insight.actionText {
                HStack {
                    Spacer()
                    
                    Text(actionText)
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.petlyDarkGreen)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.petlyDarkGreen)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    AIInsightsDashboardView()
        .environmentObject(AppState())
}
