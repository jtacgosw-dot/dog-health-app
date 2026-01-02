import SwiftUI
import SwiftData

struct HomeDashboardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var allLogs: [HealthLogEntry]
    
    @State private var showDailyLog = false
    @State private var selectedLogType: LogType?
    @State private var initialMealType: Int?
    @State private var showHealthTimeline = false
    @State private var showHealthScore = false
    @State private var showNutritionDetail = false
    @State private var showScheduleDetail = false
    @State private var showPetSwitcher = false
    @State private var showHealthDigest = false
    @State private var showSymptomTriage = false
    @State private var showCarePlans = false
    @State private var showVetVisitPack = false
    @State private var showDailyHealthReview = false
    @State private var showPreventativeCare = false
    @State private var showSmartInsights = false
    
    private let activityGoal = 60
    private let mealsTotal = 3
    
    private var todayLogs: [HealthLogEntry] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let dogId = appState.currentDog?.id ?? "default"
        return allLogs.filter { $0.dogId == dogId && $0.timestamp >= startOfDay }
    }
    
    private var mealsLogged: Int {
        todayLogs.filter { $0.logType == "Meals" }.count
    }
    
    private var activityMinutes: Int {
        let walkMinutes = todayLogs
            .filter { $0.logType == "Walk" }
            .compactMap { Int($0.duration ?? "0") }
            .reduce(0, +)
        let playtimeMinutes = todayLogs
            .filter { $0.logType == "Playtime" }
            .compactMap { Int($0.duration ?? "0") }
            .reduce(0, +)
        return walkMinutes + playtimeMinutes
    }
    
    private var waterOnTrack: Bool {
        todayLogs.filter { $0.logType == "Water" }.count >= 1
    }
    
    private var hasSymptoms: Bool {
        !todayLogs.filter { $0.logType == "Symptom" }.isEmpty
    }
    
    private var nextAppointment: HealthLogEntry? {
        let now = Date()
        let dogId = appState.currentDog?.id ?? "default"
        return allLogs
            .filter { $0.dogId == dogId && $0.logType == "Upcoming Appointments" && $0.timestamp > now }
            .sorted { $0.timestamp < $1.timestamp }
            .first
    }
    
    private var todayMeals: [(type: String, time: Date?)] {
        let mealLogs = todayLogs.filter { $0.logType == "Meals" }
        var meals: [(type: String, time: Date?)] = [
            ("Breakfast", nil),
            ("Lunch", nil),
            ("Dinner", nil)
        ]
        for log in mealLogs {
            if let mealType = log.mealType {
                if mealType == "Breakfast" { meals[0].time = log.timestamp }
                else if mealType == "Lunch" { meals[1].time = log.timestamp }
                else if mealType == "Dinner" { meals[2].time = log.timestamp }
            }
        }
        return meals
    }
    
    private var userName: String {
        if let fullName = appState.currentUser?.fullName, !fullName.isEmpty {
            return fullName.components(separatedBy: " ").first ?? fullName
        }
        return "there"
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }
    
    private var dogName: String {
        appState.currentDog?.name ?? "your pet"
    }
    
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        if appState.dogs.count > 1 {
                            PetSwitcherButton(showPetSwitcher: $showPetSwitcher)
                        }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(greeting), \(userName).")
                                        .font(.petlyTitle(28))
                                        .foregroundColor(.petlyDarkGreen)
                                    
                                    HStack(spacing: 4) {
                                        Text("Here's how \(dogName)'s doing today")
                                            .font(.petlyBody(16))
                                            .foregroundColor(.petlyDarkGreen)
                                        Image(systemName: "pawprint.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.petlyDarkGreen)
                                    }
                                }
                                
                                Spacer()
                                
                                if appState.currentDog != nil {
                                    Button(action: { showPetSwitcher = true }) {
                                        Circle()
                                            .fill(Color.petlyLightGreen)
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Image(systemName: "dog.fill")
                                                    .font(.system(size: 28))
                                                    .foregroundColor(.petlyDarkGreen)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        DailyHealthReviewCard(onStartReview: { showDailyHealthReview = true })
                        .padding(.horizontal)
                        .appearAnimation(delay: 0.08)
                        
                        TodaysOverviewCard(
                            mealsLogged: mealsLogged,
                            mealsTotal: mealsTotal,
                            activityMinutes: activityMinutes,
                            activityGoal: activityGoal,
                            waterOnTrack: waterOnTrack,
                            onLogMore: { showDailyLog = true }
                        )
                        .padding(.horizontal)
                        .appearAnimation(delay: 0.1)
                        
                        PetHealthScoreCard(
                            onViewDetails: { showHealthScore = true }
                        )
                        .padding(.horizontal)
                        .appearAnimation(delay: 0.15)
                        
                        HealthTimelineCard(
                            onViewTimeline: { showHealthTimeline = true }
                        )
                        .padding(.horizontal)
                        .appearAnimation(delay: 0.2)
                        
                        HStack(spacing: 12) {
                            HealthDigestCard(onViewDigest: { showHealthDigest = true })
                            CarePlansCard(onViewPlans: { showCarePlans = true })
                        }
                        .padding(.horizontal)
                        .appearAnimation(delay: 0.22)
                        
                        HStack(spacing: 12) {
                            SmartInsightsCard(onViewInsights: { showSmartInsights = true })
                            PreventativeCareCard(onViewCare: { showPreventativeCare = true })
                        }
                        .padding(.horizontal)
                        .appearAnimation(delay: 0.24)
                        
                        HStack(spacing: 12) {
                            DailyActivityRingCard(
                                activityMinutes: activityMinutes,
                                activityGoal: activityGoal,
                                onViewSchedule: { showScheduleDetail = true }
                            )
                            
                            WellnessTrackerCard(
                                hasSymptoms: hasSymptoms,
                                onLogSymptom: { showSymptomTriage = true },
                                onAddNote: { selectedLogType = .notes }
                            )
                        }
                        .padding(.horizontal)
                        .appearAnimation(delay: 0.25)
                        
                        UpcomingCareCard(
                            appointment: nextAppointment,
                            onUpdateInfo: { selectedLogType = .appointments },
                            onAddNote: { selectedLogType = .notes }
                        )
                        .padding(.horizontal)
                        .appearAnimation(delay: 0.3)
                        
                        VetVisitPackCard(onViewPack: { showVetVisitPack = true })
                        .padding(.horizontal)
                        .appearAnimation(delay: 0.32)
                        
                        MealsAndTreatsCard(
                            meals: todayMeals,
                            onLogDinner: {
                                initialMealType = 2
                                selectedLogType = .meals
                            },
                            onViewNutrition: { showNutritionDetail = true }
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                        .appearAnimation(delay: 0.35)
                    }
                }
            .sheet(isPresented: $showDailyLog) {
                DailyLogEntryView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedLogType) { logType in
                LogDetailView(logType: logType, initialMealType: initialMealType)
                    .environmentObject(appState)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .onDisappear {
                        initialMealType = nil
                    }
            }
            .fullScreenCover(isPresented: $showHealthTimeline) {
                HealthTimelineView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showHealthScore) {
                PetHealthScoreView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showNutritionDetail) {
                NutritionDetailView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showScheduleDetail) {
                ScheduleDetailView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showPetSwitcher) {
                PetSwitcherView()
                    .environmentObject(appState)
            }
            .fullScreenCover(isPresented: $showHealthDigest) {
                HealthDigestView()
                    .environmentObject(appState)
            }
            .fullScreenCover(isPresented: $showSymptomTriage) {
                SymptomTriageView()
                    .environmentObject(appState)
            }
            .fullScreenCover(isPresented: $showCarePlans) {
                CarePlanView()
                    .environmentObject(appState)
            }
            .fullScreenCover(isPresented: $showVetVisitPack) {
                VetVisitPackView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showDailyHealthReview) {
                DailyHealthReviewView()
                    .environmentObject(appState)
            }
            .fullScreenCover(isPresented: $showPreventativeCare) {
                PreventativeCareView()
                    .environmentObject(appState)
            }
            .fullScreenCover(isPresented: $showSmartInsights) {
                SmartInsightsView()
                    .environmentObject(appState)
            }
        }
    }
}

struct NutritionDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var allLogs: [HealthLogEntry]
    
    private var mealLogs: [HealthLogEntry] {
        let dogId = appState.currentDog?.id ?? "default"
        return allLogs
            .filter { $0.dogId == dogId && $0.logType == "Meals" }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if mealLogs.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 50))
                                    .foregroundColor(.petlyFormIcon)
                                Text("No meals logged yet")
                                    .font(.petlyBodyMedium(16))
                                    .foregroundColor(.petlyDarkGreen)
                                Text("Start logging meals to track your pet's nutrition")
                                    .font(.petlyBody(14))
                                    .foregroundColor(.petlyFormIcon)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 60)
                        } else {
                            ForEach(mealLogs, id: \.id) { log in
                                MealLogRow(log: log)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Nutrition")
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
    }
}

struct MealLogRow: View {
    let log: HealthLogEntry
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: log.timestamp)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.mealType ?? "Meal")
                    .font(.petlyBodyMedium(16))
                    .foregroundColor(.petlyDarkGreen)
                Text(timeString)
                    .font(.petlyBody(12))
                    .foregroundColor(.petlyFormIcon)
                if let amount = log.amount, !amount.isEmpty {
                    Text(amount)
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyDarkGreen)
                }
            }
            Spacer()
            Image(systemName: "fork.knife")
                .foregroundColor(.petlyDarkGreen)
        }
        .padding()
        .background(Color.petlyLightGreen)
        .cornerRadius(12)
    }
}

struct ScheduleDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var allLogs: [HealthLogEntry]
    
    private var activityLogs: [HealthLogEntry] {
        let dogId = appState.currentDog?.id ?? "default"
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return allLogs
            .filter { $0.dogId == dogId && ($0.logType == "Walk" || $0.logType == "Playtime") && $0.timestamp >= sevenDaysAgo }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    private var totalMinutesThisWeek: Int {
        activityLogs.compactMap { Int($0.duration ?? "0") }.reduce(0, +)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("This Week")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyFormIcon)
                            Text("\(totalMinutesThisWeek) min")
                                .font(.petlyTitle(36))
                                .foregroundColor(.petlyDarkGreen)
                            Text("of activity")
                                .font(.petlyBody(14))
                                .foregroundColor(.petlyFormIcon)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.petlyLightGreen)
                        .cornerRadius(16)
                        
                        if activityLogs.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 50))
                                    .foregroundColor(.petlyFormIcon)
                                Text("No activities logged yet")
                                    .font(.petlyBodyMedium(16))
                                    .foregroundColor(.petlyDarkGreen)
                                Text("Start logging walks and playtime")
                                    .font(.petlyBody(14))
                                    .foregroundColor(.petlyFormIcon)
                            }
                            .padding(.top, 40)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Recent Activity")
                                    .font(.petlyBodyMedium(16))
                                    .foregroundColor(.petlyDarkGreen)
                                
                                ForEach(activityLogs, id: \.id) { log in
                                    ActivityLogRow(log: log)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Activity Schedule")
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
    }
}

struct ActivityLogRow: View {
    let log: HealthLogEntry
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d 'at' h:mm a"
        return formatter.string(from: log.timestamp)
    }
    
    var body: some View {
        HStack {
            Image(systemName: log.logType == "Walk" ? "figure.walk" : "sportscourt.fill")
                .foregroundColor(.petlyDarkGreen)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(log.logType)
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.petlyDarkGreen)
                Text(timeString)
                    .font(.petlyBody(12))
                    .foregroundColor(.petlyFormIcon)
            }
            
            Spacer()
            
            if let duration = log.duration {
                Text("\(duration) min")
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.petlyDarkGreen)
            }
        }
        .padding()
        .background(Color.petlyLightGreen)
        .cornerRadius(12)
    }
}

struct PetlyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .sensoryFeedback(.selection, trigger: configuration.isPressed)
    }
}

struct WavyLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let amplitude: CGFloat = 3
        let wavelength: CGFloat = 8
        
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        
        var y = rect.maxY
        while y > rect.minY {
            let x = rect.midX + amplitude * sin((rect.maxY - y) / wavelength * .pi * 2)
            path.addLine(to: CGPoint(x: x, y: y))
            y -= 1
        }
        
        return path
    }
}

struct TodaysOverviewCard: View {
    let mealsLogged: Int
    let mealsTotal: Int
    let activityMinutes: Int
    let activityGoal: Int
    let waterOnTrack: Bool
    var onLogMore: () -> Void = {}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Overview")
                .font(.petlyBodyMedium(18))
                .foregroundColor(.petlyDarkGreen)
            
            HStack {
                Text("Overall: Stable")
                    .font(.petlyBody(14))
                    .foregroundColor(.petlyDarkGreen)
                
                Spacer()
                
                Button(action: onLogMore) {
                    Text("+ Log More")
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.petlyDarkGreen)
                        .cornerRadius(20)
                }
                .buttonStyle(PetlyButtonStyle())
            }
            
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Meals")
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.petlyDarkGreen)
                    Text("\(mealsLogged) / \(mealsTotal) Logged")
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Rectangle()
                    .fill(Color.petlyDarkGreen.opacity(0.2))
                    .frame(width: 1, height: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity")
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.petlyDarkGreen)
                    Text("\(activityMinutes) Min / \(activityGoal) Min Goal")
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 12)
                
                Rectangle()
                    .fill(Color.petlyDarkGreen.opacity(0.2))
                    .frame(width: 1, height: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Water")
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.petlyDarkGreen)
                    Text(waterOnTrack ? "On Track" : "Behind")
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                        .contentTransition(.opacity)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 12)
            }
        }
        .padding()
        .background(Color.petlyLightGreen)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct DailyActivityRingCard: View {
    let activityMinutes: Int
    let activityGoal: Int
    var onViewSchedule: () -> Void = {}
    @State private var animatedProgress: Double = 0
    
    var progress: Double {
        Double(activityMinutes) / Double(activityGoal)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Activity Ring")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            ZStack {
                Circle()
                    .stroke(Color.petlyDarkGreen.opacity(0.2), lineWidth: 12)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(Color.petlyDarkGreen, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: animatedProgress)
                
                VStack(spacing: 2) {
                    Text("Activity")
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyDarkGreen)
                    Text("\(activityMinutes) / \(activityGoal) min")
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.petlyDarkGreen)
                        .contentTransition(.numericText())
                }
            }
            .padding(.vertical, 8)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                    animatedProgress = progress
                }
            }
            
            Text("Close activity ring 4 days in a row to earn a badge!")
                .font(.petlyBody(11))
                .foregroundColor(.petlyFormIcon)
                .fixedSize(horizontal: false, vertical: true)
            
            Button(action: onViewSchedule) {
                Text("View Schedule ›")
                    .font(.petlyBodyMedium(12))
                    .foregroundColor(.petlyDarkGreen)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 320)
        .background(Color.petlyLightGreen)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct WellnessTrackerCard: View {
    let hasSymptoms: Bool
    var onLogSymptom: () -> Void = {}
    var onAddNote: () -> Void = {}
    
    private let weekData: [(day: String, height: CGFloat)] = [
        ("S", 25), ("M", 35), ("T", 28), ("W", 40),
        ("T", 32), ("F", 22), ("S", 38), ("S", 30)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wellness Tracker")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Today:")
                .font(.petlyBody(14))
                .foregroundColor(.petlyDarkGreen)
            
            Text(hasSymptoms ? "Symptoms Logged" : "No Symptoms")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            Button(action: onLogSymptom) {
                Text("+ Log Symptom")
                    .font(.petlyBodyMedium(12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.petlyDarkGreen)
                    .cornerRadius(16)
            }
            .buttonStyle(PetlyButtonStyle())
            
            Button(action: onAddNote) {
                Text("+ Add Note")
                    .font(.petlyBodyMedium(12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.petlyDarkGreen)
                    .cornerRadius(16)
            }
            .buttonStyle(PetlyButtonStyle())
            
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(weekData.enumerated()), id: \.offset) { index, data in
                    VStack(spacing: 2) {
                        if index >= 5 {
                            WavyLine()
                                .stroke(Color.petlyDarkGreen, lineWidth: 2)
                                .frame(width: 16, height: data.height)
                        } else {
                            Rectangle()
                                .fill(Color.petlyDarkGreen)
                                .frame(width: 8, height: data.height)
                        }
                        Text(data.day)
                            .font(.petlyBody(10))
                            .foregroundColor(.petlyFormIcon)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 320)
        .background(Color.petlyLightGreen)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct UpcomingCareCard: View {
    var appointment: HealthLogEntry?
    var onUpdateInfo: () -> Void = {}
    var onAddNote: () -> Void = {}
    
    private var daysUntilAppointment: Int? {
        guard let appointment = appointment else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: appointment.timestamp)
        return components.day
    }
    
    private var appointmentDateString: String {
        guard let appointment = appointment else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy"
        return formatter.string(from: appointment.timestamp)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Care")
                    .font(.petlyBodyMedium(18))
                    .foregroundColor(.petlyDarkGreen)
                
                Spacer()
                
                Button(action: onUpdateInfo) {
                    Text("Update Info ›")
                        .font(.petlyBodyMedium(12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.petlyDarkGreen)
                        .cornerRadius(16)
                }
                .buttonStyle(PetlyButtonStyle())
            }
            
            if let appointment = appointment, let days = daysUntilAppointment {
                Text("\(appointment.appointmentType ?? "Appointment"): in \(days) days")
                    .font(.petlyBody(14))
                    .foregroundColor(.petlyDarkGreen)
                
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle")
                        .foregroundColor(.petlyDarkGreen)
                    Text("\(appointment.location ?? "Location TBD") on \(appointmentDateString)")
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                }
            } else {
                Text("No upcoming appointments")
                    .font(.petlyBody(14))
                    .foregroundColor(.petlyDarkGreen)
                
                Text("Schedule your pet's next checkup")
                    .font(.petlyBody(12))
                    .foregroundColor(.petlyFormIcon)
            }
            
            Button(action: onAddNote) {
                Text(appointment == nil ? "Add Appointment ›" : "Add Note ›")
                    .font(.petlyBodyMedium(12))
                    .foregroundColor(.petlyDarkGreen)
            }
        }
        .padding()
        .background(Color.petlyLightGreen)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct MealsAndTreatsCard: View {
    var meals: [(type: String, time: Date?)] = []
    var onLogDinner: () -> Void = {}
    var onViewNutrition: () -> Void = {}
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: date).lowercased()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Meals & Treats")
                    .font(.petlyBodyMedium(18))
                    .foregroundColor(.petlyDarkGreen)
                
                Spacer()
                
                Button(action: onLogDinner) {
                    Text("Log Dinner ›")
                        .font(.petlyBodyMedium(12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.petlyDarkGreen)
                        .cornerRadius(16)
                }
                .buttonStyle(PetlyButtonStyle())
            }
            
            ForEach(meals, id: \.type) { meal in
                HStack {
                    Text(meal.type)
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyDarkGreen)
                    Text("-")
                        .foregroundColor(.petlyFormIcon)
                    if let time = meal.time {
                        Text("at \(formatTime(time))")
                            .font(.petlyBody(14))
                            .foregroundColor(.petlyFormIcon)
                    } else {
                        Text("Not logged yet")
                            .font(.petlyBody(14))
                            .foregroundColor(.petlyFormIcon)
                    }
                }
            }
            
            Button(action: onViewNutrition) {
                Text("View Nutrition ›")
                    .font(.petlyBodyMedium(12))
                    .foregroundColor(.petlyDarkGreen)
            }
        }
        .padding()
        .background(Color.petlyLightGreen)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct HealthTimelineCard: View {
    var onViewTimeline: () -> Void = {}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Health Timeline")
                        .font(.petlyBodyMedium(18))
                        .foregroundColor(.petlyDarkGreen)
                    
                    Text("Track your pet's health journey")
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyFormIcon)
                }
                
                Spacer()
                
                Button(action: onViewTimeline) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 14))
                        Text("View All")
                            .font(.petlyBodyMedium(12))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.petlyDarkGreen)
                    .cornerRadius(16)
                }
                .buttonStyle(PetlyButtonStyle())
            }
            
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 20))
                        .foregroundColor(.petlyDarkGreen)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("All Logs")
                            .font(.petlyBody(12))
                            .foregroundColor(.petlyFormIcon)
                        Text("Persisted")
                            .font(.petlyBodyMedium(14))
                            .foregroundColor(.petlyDarkGreen)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 20))
                        .foregroundColor(.petlyDarkGreen)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("History")
                            .font(.petlyBody(12))
                            .foregroundColor(.petlyFormIcon)
                        Text("Available")
                            .font(.petlyBodyMedium(14))
                            .foregroundColor(.petlyDarkGreen)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(.petlyDarkGreen)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Insights")
                            .font(.petlyBody(12))
                            .foregroundColor(.petlyFormIcon)
                        Text("Ready")
                            .font(.petlyBodyMedium(14))
                            .foregroundColor(.petlyDarkGreen)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.petlyLightGreen, Color.petlyLightGreen.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct HealthDigestCard: View {
    var onViewDigest: () -> Void
    
    var body: some View {
        Button(action: onViewDigest) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.title2)
                        .foregroundColor(.petlyDarkGreen)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text("Health Digest")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Weekly AI summary")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.petlyLightGreen.opacity(0.5), Color.petlyLightGreen.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CarePlansCard: View {
    var onViewPlans: () -> Void
    
    var body: some View {
        Button(action: onViewPlans) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "list.clipboard")
                        .font(.title2)
                        .foregroundColor(.petlyDarkGreen)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text("Care Plans")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("AI-powered goals")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.25), Color.blue.opacity(0.15)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VetVisitPackCard: View {
    var onViewPack: () -> Void
    
    var body: some View {
        Button(action: onViewPack) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "suitcase.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.red)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vet Visit Pack")
                        .font(.petlyBodyMedium(16))
                        .foregroundColor(.primary)
                    
                    Text("Share health records with your vet")
                        .font(.petlyBody(12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.red.opacity(0.08), Color.orange.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DailyHealthReviewCard: View {
    @EnvironmentObject var appState: AppState
    @Query private var checkIns: [DailyCheckIn]
    
    var onStartReview: () -> Void
    
    private var dogId: String {
        appState.currentDog?.id ?? ""
    }
    
    private var hasCompletedToday: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return checkIns.contains { checkIn in
            checkIn.dogId == dogId &&
            calendar.isDate(checkIn.date, inSameDayAs: today)
        }
    }
    
    private var checkInsThisWeek: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!
        return checkIns.filter { checkIn in
            checkIn.dogId == dogId &&
            checkIn.date >= weekStart && checkIn.date <= today
        }.count
    }
    
    var body: some View {
        Button(action: onStartReview) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(hasCompletedToday ? Color.green.opacity(0.15) : Color.petlyLightGreen)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: hasCompletedToday ? "checkmark.circle.fill" : "heart.text.square")
                        .font(.system(size: 22))
                        .foregroundColor(hasCompletedToday ? .green : .petlyDarkGreen)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Health Review")
                        .font(.petlyBodyMedium(16))
                        .foregroundColor(.primary)
                    
                    if hasCompletedToday {
                        Text("Completed today")
                            .font(.petlyBody(12))
                            .foregroundColor(.green)
                    } else {
                        Text("\(checkInsThisWeek) of 7 days this week")
                            .font(.petlyBody(12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if !hasCompletedToday {
                    Text("Start")
                        .font(.petlyBodyMedium(12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.petlyDarkGreen)
                        .cornerRadius(16)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PreventativeCareCard: View {
    @EnvironmentObject var appState: AppState
    @Query(sort: \PetReminder.nextDueDate) private var reminders: [PetReminder]
    
    var onViewCare: () -> Void
    
    private var dogId: String {
        appState.currentDog?.id ?? ""
    }
    
    private var dueCount: Int {
        reminders.filter { $0.dogId == dogId && $0.isEnabled && $0.isDue }.count
    }
    
    private var nextReminder: PetReminder? {
        reminders.filter { $0.dogId == dogId && $0.isEnabled && !$0.isDue }.first
    }
    
    var body: some View {
        Button(action: onViewCare) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.title2)
                        .foregroundColor(.teal)
                    Spacer()
                    if dueCount > 0 {
                        Text("\(dueCount) due")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(8)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Text("Preventative Care")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let next = nextReminder {
                    Text("Next: \(next.title)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Set up care schedule")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 130)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.teal.opacity(0.15), Color.teal.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HomeDashboardView()
        .environmentObject(AppState())
}
