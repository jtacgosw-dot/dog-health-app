import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var userName = "Kate"
    @State private var mealsLogged = 2
    @State private var mealsTotal = 2
    @State private var activityMinutes = 45
    @State private var activityGoal = 60
    @State private var waterOnTrack = true
    @State private var hasSymptoms = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Good afternoon, \(userName).")
                                    .font(.petlyTitle(28))
                                    .foregroundColor(.petlyDarkGreen)
                                
                                HStack(spacing: 4) {
                                    Text("Here's how \(appState.currentDog?.name ?? "Arlo")'s doing today")
                                        .font(.petlyBody(16))
                                        .foregroundColor(.petlyDarkGreen)
                                    Text("🐾")
                                }
                            }
                            
                            Spacer()
                            
                            if let dog = appState.currentDog {
                                Circle()
                                    .fill(Color.petlyLightGreen)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Text("🐕")
                                            .font(.system(size: 30))
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
                            waterOnTrack: waterOnTrack
                        )
                        .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            DailyActivityRingCard(
                                activityMinutes: activityMinutes,
                                activityGoal: activityGoal
                            )
                            
                            WellnessTrackerCard(hasSymptoms: hasSymptoms)
                        }
                        .padding(.horizontal)
                        
                        UpcomingCareCard()
                            .padding(.horizontal)
                        
                        MealsAndTreatsCard()
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct TodaysOverviewCard: View {
    let mealsLogged: Int
    let mealsTotal: Int
    let activityMinutes: Int
    let activityGoal: Int
    let waterOnTrack: Bool
    
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
                
                Button(action: {}) {
                    Text("+ Log More")
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.petlyDarkGreen)
                        .cornerRadius(20)
                }
            }
            
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Meals")
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.petlyDarkGreen)
                    Text("\(mealsLogged) / \(mealsTotal) Logged")
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
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
                    .trim(from: 0, to: progress)
                    .stroke(Color.petlyDarkGreen, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("Activity")
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyDarkGreen)
                    Text("\(activityMinutes) / \(activityGoal) min")
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.petlyDarkGreen)
                }
            }
            .padding(.vertical, 8)
            
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
            
            Button(action: {}) {
                Text("+ Log Symptom")
                    .font(.petlyBodyMedium(12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.petlyDarkGreen)
                    .cornerRadius(16)
            }
            
            Button(action: {}) {
                Text("+ Add Note")
                    .font(.petlyBodyMedium(12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.petlyDarkGreen)
                    .cornerRadius(16)
            }
            
            HStack(spacing: 4) {
                ForEach(["S", "M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.petlyDarkGreen)
                            .frame(width: 8, height: CGFloat.random(in: 20...40))
                        Text(day)
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
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Care")
                    .font(.petlyBodyMedium(18))
                    .foregroundColor(.petlyDarkGreen)
                
                Spacer()
                
                Button(action: {}) {
                    Text("Update Info ›")
                        .font(.petlyBodyMedium(12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.petlyDarkGreen)
                        .cornerRadius(16)
                }
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
            
            Button(action: {}) {
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
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Meals & Treats")
                    .font(.petlyBodyMedium(18))
                    .foregroundColor(.petlyDarkGreen)
                
                Spacer()
                
                Button(action: {}) {
                    Text("Log Dinner ›")
                        .font(.petlyBodyMedium(12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.petlyDarkGreen)
                        .cornerRadius(16)
                }
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
