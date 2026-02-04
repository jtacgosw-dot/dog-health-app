import SwiftUI
import SwiftData

struct PetHealthScoreView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @State private var score: PetHealthScore = .empty
    @State private var animatedProgress: Double = 0
    @State private var showActivityDetail = false
    @State private var showNutritionDetail = false
    @State private var showWellnessDetail = false
    @State private var showConsistencyDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        ScoreRingView(
                            score: score.overallScore,
                            animatedProgress: animatedProgress,
                            label: score.scoreLabel
                        )
                        .padding(.top, 20)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Score Breakdown")
                                .font(.petlyTitle(20))
                                .foregroundColor(.petlyDarkGreen)
                            
                            Button(action: { showActivityDetail = true }) {
                                ScoreFactorRow(
                                    icon: "figure.walk",
                                    title: "Activity",
                                    score: score.activityScore,
                                    description: "Based on walks and playtime logged"
                                )
                            }
                            
                            Button(action: { showNutritionDetail = true }) {
                                ScoreFactorRow(
                                    icon: "fork.knife",
                                    title: "Nutrition",
                                    score: score.nutritionScore,
                                    description: "Based on meals and water logged"
                                )
                            }
                            
                            Button(action: { showWellnessDetail = true }) {
                                ScoreFactorRow(
                                    icon: "heart.fill",
                                    title: "Wellness",
                                    score: score.wellnessScore,
                                    description: "Based on symptoms and mood"
                                )
                            }
                            
                            Button(action: { showConsistencyDetail = true }) {
                                ScoreFactorRow(
                                    icon: "calendar",
                                    title: "Consistency",
                                    score: score.consistencyScore,
                                    description: "Based on logging frequency"
                                )
                            }
                        }
                        .padding()
                        .background(Color.petlyLightGreen)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tips to Improve")
                                .font(.petlyTitle(20))
                                .foregroundColor(.petlyDarkGreen)
                            
                            if score.activityScore < 70 {
                                TipCard(
                                    icon: "figure.walk",
                                    tip: "Try logging more walks and playtime to boost your activity score!"
                                )
                            }
                            
                            if score.nutritionScore < 70 {
                                TipCard(
                                    icon: "fork.knife",
                                    tip: "Log meals consistently to improve your nutrition score."
                                )
                            }
                            
                            if score.consistencyScore < 70 {
                                TipCard(
                                    icon: "calendar",
                                    tip: "Log something every day to build consistency!"
                                )
                            }
                            
                            if score.overallScore >= 70 {
                                TipCard(
                                    icon: "star.fill",
                                    tip: "Great job! Keep up the consistent care for \(appState.currentDog?.name ?? "your pet")!"
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Pet Health Score")
                        .font(.petlyTitle(18))
                        .foregroundColor(.petlyDarkGreen)
                }
            }
        }
        .buttonStyle(.plain)
        .preferredColorScheme(.light)
        .onAppear {
            calculateScore()
        }
        .sheet(isPresented: $showActivityDetail) {
            ScoreDetailSheet(
                title: "Activity",
                icon: "figure.walk",
                score: score.activityScore,
                description: "Your activity score is based on walks and playtime logged over the past 7 days.",
                tips: [
                    "Log daily walks to boost your score",
                    "Include playtime sessions",
                    "Aim for at least 30 minutes of activity daily"
                ],
                logType: .walk
            )
            .environmentObject(appState)
        }
        .sheet(isPresented: $showNutritionDetail) {
            ScoreDetailSheet(
                title: "Nutrition",
                icon: "fork.knife",
                score: score.nutritionScore,
                description: "Your nutrition score is based on meals and water intake logged over the past 7 days.",
                tips: [
                    "Log all meals consistently",
                    "Track water intake daily",
                    "Note any dietary changes"
                ],
                logType: .meals
            )
            .environmentObject(appState)
        }
        .sheet(isPresented: $showWellnessDetail) {
            ScoreDetailSheet(
                title: "Wellness",
                icon: "heart.fill",
                score: score.wellnessScore,
                description: "Your wellness score is based on symptoms reported and overall mood tracking.",
                tips: [
                    "Log any symptoms promptly",
                    "Track daily mood",
                    "Note behavioral changes"
                ],
                logType: .symptom
            )
            .environmentObject(appState)
        }
        .sheet(isPresented: $showConsistencyDetail) {
            ScoreDetailSheet(
                title: "Consistency",
                icon: "calendar",
                score: score.consistencyScore,
                description: "Your consistency score is based on how regularly you log activities for your pet.",
                tips: [
                    "Log something every day",
                    "Set reminders to log activities",
                    "Build a daily logging habit"
                ],
                logType: nil
            )
            .environmentObject(appState)
        }
    }
    
    private func calculateScore() {
        let dogId = appState.currentDog?.id ?? "default"
        let calculator = PetHealthScoreCalculator(modelContext: modelContext, dogId: dogId)
        score = calculator.calculateScore()
        
        withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
            animatedProgress = Double(score.overallScore) / 100.0
        }
    }
}

struct ScoreRingView: View {
    let score: Int
    let animatedProgress: Double
    let label: String
    
    @ScaledMetric(relativeTo: .body) private var ringSize: CGFloat = 200
    @ScaledMetric(relativeTo: .body) private var ringStroke: CGFloat = 20
    
    private var cappedRingSize: CGFloat { min(ringSize, 280) }
    private var cappedRingStroke: CGFloat { min(ringStroke, 28) }
    
    private var ringColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        default: return .red
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.petlyDarkGreen.opacity(0.15), lineWidth: cappedRingStroke)
                .frame(width: cappedRingSize, height: cappedRingSize)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [ringColor.opacity(0.6), ringColor]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: cappedRingStroke, lineCap: .round)
                )
                .frame(width: cappedRingSize, height: cappedRingSize)
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.petlyDarkGreen)
                    .contentTransition(.numericText())
                
                Text(label)
                    .font(.petlyBodyMedium(16))
                    .foregroundColor(.petlyFormIcon)
            }
        }
    }
}

struct ScoreFactorRow: View {
    let icon: String
    let title: String
    let score: Int
    let description: String
    
    private var scoreColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        default: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.petlyDarkGreen)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.petlyBodyMedium(16))
                        .foregroundColor(.petlyDarkGreen)
                    
                    Spacer()
                    
                    Text("\(score)")
                        .font(.petlyTitle(18))
                        .foregroundColor(scoreColor)
                }
                
                Text(description)
                    .font(.petlyBody(12))
                    .foregroundColor(.petlyFormIcon)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.petlyDarkGreen.opacity(0.15))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(scoreColor)
                            .frame(width: geometry.size.width * CGFloat(score) / 100, height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.vertical, 8)
    }
}

struct TipCard: View {
    let icon: String
    let tip: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.petlyDarkGreen)
                .frame(width: 32)
            
            Text(tip)
                .font(.petlyBody(14))
                .foregroundColor(.petlyDarkGreen)
            
            Spacer()
        }
        .padding()
        .background(Color.petlyLightGreen)
        .cornerRadius(12)
    }
}

struct PetHealthScoreCard: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @State private var score: PetHealthScore = .empty
    @State private var animatedProgress: Double = 0
    var onViewDetails: () -> Void = {}
    
    @ScaledMetric(relativeTo: .body) private var cardRingSize: CGFloat = 80
    private var cappedCardRingSize: CGFloat { min(cardRingSize, 120) }
    
    private var ringColor: Color {
        switch score.overallScore {
        case 80...100: return .green
        case 60..<80: return .yellow
        default: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pet Health Score")
                    .font(.petlyBodyMedium(18))
                    .foregroundColor(.petlyDarkGreen)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                Button(action: onViewDetails) {
                    Text("Details ›")
                        .font(.petlyBodyMedium(12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.petlyDarkGreen)
                        .cornerRadius(16)
                }
                .buttonStyle(PetlyButtonStyle())
            }
            
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.petlyDarkGreen.opacity(0.15), lineWidth: 8)
                        .frame(width: cappedCardRingSize, height: cappedCardRingSize)
                    
                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: cappedCardRingSize, height: cappedCardRingSize)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(score.overallScore)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.petlyDarkGreen)
                            .contentTransition(.numericText())
                            .minimumScaleFactor(0.7)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(score.scoreLabel)
                        .font(.petlyTitle(20))
                        .foregroundColor(.petlyDarkGreen)
                        .minimumScaleFactor(0.8)
                    
                    Text("Based on 7-day activity")
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                        .minimumScaleFactor(0.8)
                    
                    HStack(spacing: 12) {
                        MiniScoreIndicator(label: "Activity", score: score.activityScore)
                        MiniScoreIndicator(label: "Nutrition", score: score.nutritionScore)
                        MiniScoreIndicator(label: "Wellness", score: score.wellnessScore)
                    }
                }
            }
        }
        .padding()
        .background(Color.petlyLightGreen)
        .cornerRadius(16)
        .onAppear {
            calculateScore()
        }
    }
    
    private func calculateScore() {
        let dogId = appState.currentDog?.id ?? "default"
        let calculator = PetHealthScoreCalculator(modelContext: modelContext, dogId: dogId)
        score = calculator.calculateScore()
        
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            animatedProgress = Double(score.overallScore) / 100.0
        }
    }
}

struct MiniScoreIndicator: View {
    let label: String
    let score: Int
    
    private var color: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        default: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.petlyBody(10))
                .foregroundColor(.petlyFormIcon)
        }
    }
}

enum ScoreLogType {
    case walk
    case meals
    case symptom
}

struct ScoreDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    let title: String
    let icon: String
    let score: Int
    let description: String
    let tips: [String]
    let logType: ScoreLogType?
    
    @State private var showLogSheet = false
    
    private var scoreColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        default: return .red
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(scoreColor.opacity(0.15))
                                .frame(width: 120, height: 120)
                            
                            VStack(spacing: 4) {
                                Image(systemName: icon)
                                    .font(.system(size: 32))
                                    .foregroundColor(scoreColor)
                                
                                Text("\(score)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(scoreColor)
                            }
                        }
                        .padding(.top, 20)
                        
                        Text(description)
                            .font(.petlyBody(14))
                            .foregroundColor(.petlyFormIcon)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Tips to Improve")
                                .font(.petlyTitle(18))
                                .foregroundColor(.petlyDarkGreen)
                            
                            ForEach(tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.petlyDarkGreen)
                                        .font(.system(size: 16))
                                    
                                    Text(tip)
                                        .font(.petlyBody(14))
                                        .foregroundColor(.petlyDarkGreen)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.petlyLightGreen)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        if logType != nil {
                            Button(action: { showLogSheet = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Log \(title)")
                                }
                                .font(.petlyBodyMedium(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.petlyDarkGreen)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.petlyTitle(18))
                        .foregroundColor(.petlyDarkGreen)
                }
            }
        }
        .buttonStyle(.plain)
        .preferredColorScheme(.light)
        .sheet(isPresented: $showLogSheet) {
            if let logType = logType {
                LogEntrySheet(logType: logType)
                    .environmentObject(appState)
            }
        }
    }
}

struct LogEntrySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    let logType: ScoreLogType
    
    @State private var duration: String = ""
    @State private var notes: String = ""
    @State private var mealType: String = "Breakfast"
    @State private var symptomType: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    switch logType {
                    case .walk:
                        walkForm
                    case .meals:
                        mealsForm
                    case .symptom:
                        symptomForm
                    }
                    
                    Button(action: saveLog) {
                        Text("Save")
                            .font(.petlyBodyMedium(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.petlyDarkGreen)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(logTypeTitle)
                        .font(.petlyTitle(18))
                        .foregroundColor(.petlyDarkGreen)
                }
            }
        }
        .buttonStyle(.plain)
        .preferredColorScheme(.light)
    }
    
    private var logTypeTitle: String {
        switch logType {
        case .walk: return "Log Activity"
        case .meals: return "Log Meal"
        case .symptom: return "Log Symptom"
        }
    }
    
    private var walkForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Duration (minutes)")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            TextField("30", text: $duration)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.petlyLightGreen, lineWidth: 1)
                )
            
            Text("Notes (optional)")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            TextEditor(text: $notes)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.petlyLightGreen, lineWidth: 1)
                )
        }
        .padding(.horizontal)
    }
    
    private var mealsForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meal Type")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            Picker("Meal Type", selection: $mealType) {
                Text("Breakfast").tag("Breakfast")
                Text("Lunch").tag("Lunch")
                Text("Dinner").tag("Dinner")
                Text("Snack").tag("Snack")
            }
            .pickerStyle(.segmented)
            
            Text("Notes (optional)")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            TextEditor(text: $notes)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.petlyLightGreen, lineWidth: 1)
                )
        }
        .padding(.horizontal)
    }
    
    private var symptomForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Symptom")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            TextField("e.g., Lethargy, Loss of appetite", text: $symptomType)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.petlyLightGreen, lineWidth: 1)
                )
            
            Text("Notes (optional)")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            TextEditor(text: $notes)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.petlyLightGreen, lineWidth: 1)
                )
        }
        .padding(.horizontal)
    }
    
    private func saveLog() {
        let dogId = appState.currentDog?.id ?? "default"
        
        switch logType {
        case .walk:
            let log = HealthLogEntry(
                id: UUID().uuidString,
                dogId: dogId,
                type: .walk,
                notes: notes.isEmpty ? nil : notes,
                timestamp: Date(),
                duration: duration.isEmpty ? nil : duration
            )
            modelContext.insert(log)
        case .meals:
            let log = HealthLogEntry(
                id: UUID().uuidString,
                dogId: dogId,
                type: .meals,
                notes: notes.isEmpty ? "\(mealType)" : "\(mealType): \(notes)",
                timestamp: Date()
            )
            modelContext.insert(log)
        case .symptom:
            let log = HealthLogEntry(
                id: UUID().uuidString,
                dogId: dogId,
                type: .symptom,
                notes: symptomType.isEmpty ? notes : "\(symptomType): \(notes)",
                timestamp: Date()
            )
            modelContext.insert(log)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    PetHealthScoreView()
        .environmentObject(AppState())
}
