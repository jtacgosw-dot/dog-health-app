import SwiftUI
import SwiftData
import Charts

struct HealthInsightsDashboardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allLogs: [HealthLogEntry]
    
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case twoWeeks = "14 Days"
        case month = "30 Days"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .twoWeeks: return 14
            case .month: return 30
            }
        }
    }
    
    private var filteredLogs: [HealthLogEntry] {
        guard let dogId = appState.currentDog?.id else { return [] }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        return allLogs.filter { $0.dogId == dogId && $0.timestamp >= cutoffDate }
    }
    
    private var activityData: [DailyActivityData] {
        var data: [DailyActivityData] = []
        let calendar = Calendar.current
        
        for dayOffset in (0..<selectedTimeRange.days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
            
            let dayLogs = filteredLogs.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }
            let walkMinutes = dayLogs
                .filter { $0.logType == "Walk" }
                .compactMap { Int($0.duration ?? "0") }
                .reduce(0, +)
            let playtimeMinutes = dayLogs
                .filter { $0.logType == "Playtime" }
                .compactMap { Int($0.duration ?? "0") }
                .reduce(0, +)
            
            data.append(DailyActivityData(date: startOfDay, minutes: walkMinutes + playtimeMinutes))
        }
        
        return data
    }
    
    private var mealData: [DailyMealData] {
        var data: [DailyMealData] = []
        let calendar = Calendar.current
        
        for dayOffset in (0..<selectedTimeRange.days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
            
            let dayLogs = filteredLogs.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }
            let mealCount = dayLogs.filter { $0.logType == "Meals" }.count
            
            data.append(DailyMealData(date: startOfDay, count: mealCount))
        }
        
        return data
    }
    
    private var symptomSummary: [(type: String, count: Int)] {
        let symptoms = filteredLogs.filter { $0.logType == "Symptom" }
        var counts: [String: Int] = [:]
        
        for symptom in symptoms {
            let type = symptom.symptomType ?? "Other"
            counts[type, default: 0] += 1
        }
        
        return counts.map { (type: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    private var moodTrend: Double {
        let moodLogs = filteredLogs.filter { $0.logType == "Mood" }
        guard !moodLogs.isEmpty else { return 0 }
        
        let totalMood = moodLogs.compactMap { $0.moodLevel }.reduce(0, +)
        return Double(totalMood) / Double(moodLogs.count)
    }
    
    private var averageActivityMinutes: Int {
        let totalMinutes = activityData.map { $0.minutes }.reduce(0, +)
        let daysWithActivity = activityData.filter { $0.minutes > 0 }.count
        return daysWithActivity > 0 ? totalMinutes / daysWithActivity : 0
    }
    
    private var totalLogsCount: Int {
        filteredLogs.count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        timeRangePicker
                        
                        summaryCards
                        
                        activityChart
                        
                        mealChart
                        
                        if !symptomSummary.isEmpty {
                            symptomBreakdown
                        }
                        
                        insightsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Health Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .preferredColorScheme(.light)
    }
    
    private var timeRangePicker: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }
    
    private var summaryCards: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "Total Logs",
                value: "\(totalLogsCount)",
                icon: "list.bullet.clipboard",
                color: .blue
            )
            
            SummaryCard(
                title: "Avg Activity",
                value: "\(averageActivityMinutes) min",
                icon: "figure.walk",
                color: .green
            )
            
            SummaryCard(
                title: "Mood",
                value: moodTrend > 0 ? String(format: "%.1f/5", moodTrend) : "N/A",
                icon: "face.smiling",
                color: .orange
            )
        }
    }
    
    private var activityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Trend")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            if activityData.isEmpty || activityData.allSatisfy({ $0.minutes == 0 }) {
                emptyChartPlaceholder(message: "No activity data for this period")
            } else {
                Chart(activityData) { data in
                    BarMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Minutes", data.minutes)
                    )
                    .foregroundStyle(Color.petlyDarkGreen.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: selectedTimeRange == .month ? 7 : 1)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.day())
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private var mealChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meals Logged")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            if mealData.isEmpty || mealData.allSatisfy({ $0.count == 0 }) {
                emptyChartPlaceholder(message: "No meal data for this period")
            } else {
                Chart(mealData) { data in
                    LineMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Meals", data.count)
                    )
                    .foregroundStyle(Color.orange)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Meals", data.count)
                    )
                    .foregroundStyle(Color.orange)
                }
                .frame(height: 150)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: selectedTimeRange == .month ? 7 : 1)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.day())
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private var symptomBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Symptom Breakdown")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            ForEach(symptomSummary.prefix(5), id: \.type) { symptom in
                HStack {
                    Text(symptom.type)
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyDarkGreen)
                    
                    Spacer()
                    
                    Text("\(symptom.count) occurrence\(symptom.count == 1 ? "" : "s")")
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                    
                    Circle()
                        .fill(symptomColor(for: symptom.count))
                        .frame(width: 12, height: 12)
                }
                .padding(.vertical, 8)
                
                if symptom.type != symptomSummary.prefix(5).last?.type {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            VStack(spacing: 12) {
                if averageActivityMinutes < 30 {
                    InsightRow(
                        icon: "exclamationmark.triangle.fill",
                        message: "Activity is below recommended levels. Try to aim for at least 30 minutes daily.",
                        color: .orange
                    )
                } else if averageActivityMinutes >= 60 {
                    InsightRow(
                        icon: "checkmark.circle.fill",
                        message: "Great job! Your pet is getting excellent exercise.",
                        color: .green
                    )
                }
                
                if moodTrend > 0 && moodTrend < 3 {
                    InsightRow(
                        icon: "heart.fill",
                        message: "Mood has been lower than usual. Consider extra playtime or enrichment activities.",
                        color: .red
                    )
                }
                
                if !symptomSummary.isEmpty {
                    InsightRow(
                        icon: "stethoscope",
                        message: "You've logged \(symptomSummary.map { $0.count }.reduce(0, +)) symptom(s). Consider discussing with your vet if symptoms persist.",
                        color: .blue
                    )
                }
                
                if totalLogsCount == 0 {
                    InsightRow(
                        icon: "info.circle.fill",
                        message: "Start logging your pet's activities to see personalized insights here.",
                        color: .gray
                    )
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private func emptyChartPlaceholder(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(.petlyFormIcon)
            Text(message)
                .font(.petlyBody(14))
                .foregroundColor(.petlyFormIcon)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }
    
    private func symptomColor(for count: Int) -> Color {
        switch count {
        case 1...2: return .yellow
        case 3...5: return .orange
        default: return .red
        }
    }
}

struct DailyActivityData: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Int
}

struct DailyMealData: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.petlyBodyMedium(18))
                .foregroundColor(.petlyDarkGreen)
            
            Text(title)
                .font(.petlyBody(12))
                .foregroundColor(.petlyFormIcon)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct InsightRow: View {
    let icon: String
    let message: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(message)
                .font(.petlyBody(14))
                .foregroundColor(.petlyDarkGreen)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    HealthInsightsDashboardView()
        .environmentObject(AppState())
}
