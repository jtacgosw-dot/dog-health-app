import SwiftUI
import SwiftData

struct DailyHealthReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @Query private var checkIns: [DailyCheckIn]
    @Query private var todayLogs: [HealthLogEntry]
    
    @State private var currentStep = 0
    @State private var hasSymptoms = false
    @State private var symptomsNotes = ""
    @State private var overallMood: Int = 3
    @State private var additionalNotes = ""
    @State private var showingCompletion = false
    
    private let totalSteps = 4
    
    private var dogId: String {
        appState.currentDog?.id ?? ""
    }
    
    private var dogName: String {
        appState.currentDog?.name ?? "your pet"
    }
    
    private var todaysMeals: [HealthLogEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return todayLogs.filter { log in
            log.dogId == dogId &&
            log.logType == "meals" &&
            calendar.isDate(log.timestamp, inSameDayAs: today)
        }
    }
    
    private var todaysActivity: [HealthLogEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return todayLogs.filter { log in
            log.dogId == dogId &&
            (log.logType == "walk" || log.logType == "playtime") &&
            calendar.isDate(log.timestamp, inSameDayAs: today)
        }
    }
    
    private var todaysWater: [HealthLogEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return todayLogs.filter { log in
            log.dogId == dogId &&
            log.logType == "water" &&
            calendar.isDate(log.timestamp, inSameDayAs: today)
        }
    }
    
    private var hasCompletedTodayReview: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return checkIns.contains { checkIn in
            checkIn.dogId == dogId &&
            calendar.isDate(checkIn.date, inSameDayAs: today)
        }
    }
    
    private var careConsistency: CareConsistency {
        calculateCareConsistency()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if showingCompletion {
                    completionView
                } else {
                    progressHeader
                    
                    TabView(selection: $currentStep) {
                        symptomsStep.tag(0)
                        mealsStep.tag(1)
                        activityStep.tag(2)
                        moodStep.tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                    
                    navigationButtons
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Daily Health Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .preferredColorScheme(.light)
    }
    
    private var progressHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(step <= currentStep ? Color.petlyDarkGreen : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal)
            
            Text("Step \(currentStep + 1) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }
    
    private var symptomsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Any symptoms today?")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Note any changes in \(dogName)'s health or behavior")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 16) {
                    symptomButton(title: "No Symptoms", isSelected: !hasSymptoms) {
                        hasSymptoms = false
                    }
                    
                    symptomButton(title: "Yes, Some", isSelected: hasSymptoms) {
                        hasSymptoms = true
                    }
                }
                
                if hasSymptoms {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What did you notice?")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $symptomsNotes)
                            .scrollContentBackground(.hidden)
                            .foregroundColor(.primary)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func symptomButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundColor(isSelected ? .petlyDarkGreen : .gray)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .petlyDarkGreen : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.petlyLightGreen : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.petlyDarkGreen : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var mealsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meals today")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Review \(dogName)'s eating today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if todaysMeals.isEmpty {
                    emptyStateCard(
                        icon: "fork.knife",
                        title: "No meals logged yet",
                        subtitle: "Log meals to track nutrition patterns"
                    )
                } else {
                    VStack(spacing: 12) {
                        ForEach(todaysMeals, id: \.id) { meal in
                            loggedItemRow(
                                icon: "fork.knife",
                                title: meal.displayTitle,
                                subtitle: meal.displaySubtitle,
                                time: meal.timestamp
                            )
                        }
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(todaysMeals.count) meal\(todaysMeals.count == 1 ? "" : "s") logged today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var activityStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activity today")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Review \(dogName)'s exercise and playtime")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if todaysActivity.isEmpty {
                    emptyStateCard(
                        icon: "figure.walk",
                        title: "No activity logged yet",
                        subtitle: "Log walks and playtime to track fitness"
                    )
                } else {
                    VStack(spacing: 12) {
                        ForEach(todaysActivity, id: \.id) { activity in
                            loggedItemRow(
                                icon: activity.logType == "walk" ? "figure.walk" : "sportscourt",
                                title: activity.displayTitle,
                                subtitle: activity.displaySubtitle,
                                time: activity.timestamp
                            )
                        }
                    }
                    
                    let totalMinutes = todaysActivity.compactMap { Int($0.duration ?? "0") }.reduce(0, +)
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(totalMinutes) minutes of activity today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var moodStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overall mood")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("How is \(dogName) doing overall today?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { level in
                            moodButton(level: level)
                        }
                    }
                    
                    Text(moodDescription(for: overallMood))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Any additional notes?")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextEditor(text: $additionalNotes)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(.primary)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func moodButton(level: Int) -> some View {
        let icons = ["😟", "😕", "😐", "🙂", "😊"]
        let isSelected = overallMood == level
        
        return Button {
            overallMood = level
        } label: {
            VStack(spacing: 4) {
                Text(icons[level - 1])
                    .font(.title)
                
                Text("\(level)")
                    .font(.caption)
                    .foregroundColor(isSelected ? .petlyDarkGreen : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.petlyLightGreen : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.petlyDarkGreen : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func moodDescription(for level: Int) -> String {
        switch level {
        case 1: return "Not feeling well - may need attention"
        case 2: return "A bit off today"
        case 3: return "Normal day"
        case 4: return "Good energy and mood"
        case 5: return "Excellent - happy and healthy!"
        default: return ""
        }
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button {
                    withAnimation {
                        currentStep -= 1
                    }
                } label: {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(.petlyDarkGreen)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.petlyLightGreen)
                        .cornerRadius(12)
                }
            }
            
            Button {
                if currentStep < totalSteps - 1 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    completeReview()
                }
            } label: {
                Text(currentStep < totalSteps - 1 ? "Next" : "Complete Review")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.petlyDarkGreen)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.petlyDarkGreen)
            
            VStack(spacing: 8) {
                Text("Health Review Complete")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Great job keeping track of \(dogName)'s health!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Care Consistency")
                    .font(.headline)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(careConsistency.consistencyDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(careConsistency.consistencyLevel)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.petlyDarkGreen)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: careConsistency.weeklyPercentage / 100)
                            .stroke(Color.petlyDarkGreen, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(careConsistency.weeklyPercentage))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .padding(.horizontal)
            
            Text("Consistency helps you spot health changes early")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.petlyDarkGreen)
                    .cornerRadius(12)
            }
            .padding()
        }
    }
    
    private func emptyStateCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text(title)
                .font(.headline)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private func loggedItemRow(icon: String, title: String, subtitle: String, time: Date) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.petlyDarkGreen)
                .frame(width: 40, height: 40)
                .background(Color.petlyLightGreen)
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(time, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func completeReview() {
        let checkIn = DailyCheckIn(
            dogId: dogId,
            hasSymptoms: hasSymptoms,
            symptomsNotes: hasSymptoms ? symptomsNotes : nil,
            mealsLogged: !todaysMeals.isEmpty,
            activityLogged: !todaysActivity.isEmpty,
            waterLogged: !todaysWater.isEmpty,
            overallMood: overallMood,
            additionalNotes: additionalNotes.isEmpty ? nil : additionalNotes
        )
        
        modelContext.insert(checkIn)
        
        withAnimation {
            showingCompletion = true
        }
    }
    
    private func calculateCareConsistency() -> CareConsistency {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!
        let monthStart = calendar.date(byAdding: .day, value: -29, to: today)!
        
        let dogCheckIns = checkIns.filter { $0.dogId == dogId }
        
        let weekCheckIns = dogCheckIns.filter { checkIn in
            checkIn.date >= weekStart && checkIn.date <= today
        }
        
        let monthCheckIns = dogCheckIns.filter { checkIn in
            checkIn.date >= monthStart && checkIn.date <= today
        }
        
        var currentStreak = 0
        var checkDate = today
        while true {
            let hasCheckIn = dogCheckIns.contains { calendar.isDate($0.date, inSameDayAs: checkDate) }
            if hasCheckIn {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        return CareConsistency(
            checkInsThisWeek: weekCheckIns.count + 1,
            totalDaysThisWeek: 7,
            checkInsThisMonth: monthCheckIns.count + 1,
            totalDaysThisMonth: 30,
            currentStreak: currentStreak + 1,
            longestStreak: currentStreak + 1
        )
    }
}

#Preview {
    DailyHealthReviewView()
        .environmentObject(AppState())
}
