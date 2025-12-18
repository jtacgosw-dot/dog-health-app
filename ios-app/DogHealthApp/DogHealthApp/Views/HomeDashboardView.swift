import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var mealsLogged = 2
    @State private var mealsTotal = 2
    @State private var activityMinutes = 45
    @State private var activityGoal = 60
    @State private var waterOnTrack = true
    @State private var hasSymptoms = false
    @State private var showDailyLog = false
    
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
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
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
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        TodaysOverviewCard(
                            mealsLogged: mealsLogged,
                            mealsTotal: mealsTotal,
                            activityMinutes: activityMinutes,
                            activityGoal: activityGoal,
                            waterOnTrack: waterOnTrack,
                            onLogMore: { showDailyLog = true }
                        )
                        .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            DailyActivityRingCard(
                                activityMinutes: activityMinutes,
                                activityGoal: activityGoal
                            )
                            
                            WellnessTrackerCard(
                                hasSymptoms: hasSymptoms,
                                onLogSymptom: { showDailyLog = true },
                                onAddNote: { showDailyLog = true }
                            )
                        }
                        .padding(.horizontal)
                        
                        UpcomingCareCard(
                            onUpdateInfo: { showDailyLog = true },
                            onAddNote: { showDailyLog = true }
                        )
                        .padding(.horizontal)
                        
                        MealsAndTreatsCard(
                            onLogDinner: { showDailyLog = true }
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showDailyLog) {
                DailyLogEntryView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
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
    }
}

struct DailyActivityRingCard: View {
    let activityMinutes: Int
    let activityGoal: Int
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
            
            Button(action: {}) {
                Text("View Schedule ›")
                    .font(.petlyBodyMedium(12))
                    .foregroundColor(.petlyDarkGreen)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.petlyLightGreen)
        .cornerRadius(16)
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
            
            HStack(spacing: 4) {
                ForEach(Array(weekData.enumerated()), id: \.offset) { _, data in
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.petlyDarkGreen)
                            .frame(width: 8, height: data.height)
                        Text(data.day)
                            .font(.petlyBody(10))
                            .foregroundColor(.petlyFormIcon)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.petlyLightGreen)
        .cornerRadius(16)
    }
}

struct UpcomingCareCard: View {
    var onUpdateInfo: () -> Void = {}
    var onAddNote: () -> Void = {}
    
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
            
            Text("Vet Appointment: in 12 days")
                .font(.petlyBody(14))
                .foregroundColor(.petlyDarkGreen)
            
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle")
                    .foregroundColor(.petlyDarkGreen)
                Text("Dr.Lee Animal Clinic on 12/3/25")
                    .font(.petlyBody(12))
                    .foregroundColor(.petlyFormIcon)
            }
            
            Button(action: onAddNote) {
                Text("Add Note ›")
                    .font(.petlyBodyMedium(12))
                    .foregroundColor(.petlyDarkGreen)
            }
        }
        .padding()
        .background(Color.petlyLightGreen)
        .cornerRadius(16)
    }
}

struct MealsAndTreatsCard: View {
    var onLogDinner: () -> Void = {}
    
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
            
            HStack {
                Text("Breakfast")
                    .font(.petlyBody(14))
                    .foregroundColor(.petlyDarkGreen)
                Text("-")
                    .foregroundColor(.petlyFormIcon)
                Text("at 8am")
                    .font(.petlyBody(14))
                    .foregroundColor(.petlyFormIcon)
            }
            
            HStack {
                Text("Dinner")
                    .font(.petlyBody(14))
                    .foregroundColor(.petlyDarkGreen)
                Text("-")
                    .foregroundColor(.petlyFormIcon)
                Text("Not logged yet")
                    .font(.petlyBody(14))
                    .foregroundColor(.petlyFormIcon)
            }
            
            Button(action: {}) {
                Text("View Nutrition ›")
                    .font(.petlyBodyMedium(12))
                    .foregroundColor(.petlyDarkGreen)
            }
        }
        .padding()
        .background(Color.petlyLightGreen)
        .cornerRadius(16)
    }
}

#Preview {
    HomeDashboardView()
        .environmentObject(AppState())
}
