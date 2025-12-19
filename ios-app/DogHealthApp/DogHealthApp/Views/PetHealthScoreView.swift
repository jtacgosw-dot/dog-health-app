import SwiftUI
import SwiftData

struct PetHealthScoreView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @State private var score: PetHealthScore = .empty
    @State private var animatedProgress: Double = 0
    
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
                            
                            ScoreFactorRow(
                                icon: "figure.walk",
                                title: "Activity",
                                score: score.activityScore,
                                description: "Based on walks and playtime logged"
                            )
                            
                            ScoreFactorRow(
                                icon: "fork.knife",
                                title: "Nutrition",
                                score: score.nutritionScore,
                                description: "Based on meals and water logged"
                            )
                            
                            ScoreFactorRow(
                                icon: "heart.fill",
                                title: "Wellness",
                                score: score.wellnessScore,
                                description: "Based on symptoms and mood"
                            )
                            
                            ScoreFactorRow(
                                icon: "calendar",
                                title: "Consistency",
                                score: score.consistencyScore,
                                description: "Based on logging frequency"
                            )
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
        .onAppear {
            calculateScore()
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
                .stroke(Color.petlyDarkGreen.opacity(0.15), lineWidth: 20)
                .frame(width: 200, height: 200)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [ringColor.opacity(0.6), ringColor]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: 200, height: 200)
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
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(score.overallScore)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.petlyDarkGreen)
                            .contentTransition(.numericText())
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(score.scoreLabel)
                        .font(.petlyTitle(20))
                        .foregroundColor(.petlyDarkGreen)
                    
                    Text("Based on 7-day activity")
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                    
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

#Preview {
    PetHealthScoreView()
        .environmentObject(AppState())
}
