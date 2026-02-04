import SwiftUI
import SwiftData

struct SymptomTriageView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var symptomType: String = ""
    @State private var severity: Int = 3
    @State private var duration: String = ""
    @State private var appetiteChange: String = ""
    @State private var behaviorChange: String = ""
    @State private var additionalNotes: String = ""
    @State private var currentStep: TriageStep = .symptomType
    @State private var isAnalyzing = false
    @State private var triageResult: TriageResult?
    @State private var errorMessage: String?
    
    let symptomTypes = [
        "Vomiting",
        "Diarrhea",
        "Lethargy",
        "Loss of appetite",
        "Excessive thirst",
        "Coughing",
        "Sneezing",
        "Limping",
        "Scratching/Itching",
        "Eye discharge",
        "Ear problems",
        "Skin issues",
        "Breathing difficulty",
        "Other"
    ]
    
    let durationOptions = [
        "Just started (< 1 hour)",
        "A few hours",
        "Since yesterday",
        "2-3 days",
        "More than 3 days",
        "On and off for a week+"
    ]
    
    let appetiteOptions = [
        "Eating normally",
        "Eating less than usual",
        "Refusing food completely",
        "Eating more than usual",
        "Not sure"
    ]
    
    let behaviorOptions = [
        "Acting normal",
        "Less active than usual",
        "Hiding or withdrawn",
        "More clingy than usual",
        "Restless or pacing",
        "Aggressive or irritable"
    ]
    
    private var dogName: String {
        appState.currentDog?.name ?? "your pet"
    }
    
    enum TriageStep: Int, CaseIterable {
        case symptomType = 0
        case severity = 1
        case duration = 2
        case appetite = 3
        case behavior = 4
        case notes = 5
        case analyzing = 6
        case result = 7
        
        var title: String {
            switch self {
            case .symptomType: return "What symptom are you seeing?"
            case .severity: return "How severe is it?"
            case .duration: return "How long has this been going on?"
            case .appetite: return "Any changes in appetite?"
            case .behavior: return "Any behavior changes?"
            case .notes: return "Anything else to add?"
            case .analyzing: return "Analyzing..."
            case .result: return "Triage Assessment"
            }
        }
        
        var progress: Double {
            return Double(self.rawValue) / Double(TriageStep.allCases.count - 1)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    progressBar
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            stepContent
                        }
                        .padding()
                    }
                    
                    if currentStep != .analyzing && currentStep != .result {
                        navigationButtons
                    }
                }
            }
            .navigationTitle("Symptom Triage")
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
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.petlyLightGreen)
                    .frame(height: 4)
                
                Rectangle()
                    .fill(Color.petlyDarkGreen)
                    .frame(width: geometry.size.width * currentStep.progress, height: 4)
                    .animation(.easeInOut, value: currentStep)
            }
        }
        .frame(height: 4)
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .symptomType:
            symptomTypeStep
        case .severity:
            severityStep
        case .duration:
            durationStep
        case .appetite:
            appetiteStep
        case .behavior:
            behaviorStep
        case .notes:
            notesStep
        case .analyzing:
            analyzingStep
        case .result:
            resultStep
        }
    }
    
    private var symptomTypeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What symptom is \(dogName) experiencing?")
                .font(.petlyTitle(22))
                .foregroundColor(.petlyDarkGreen)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(symptomTypes, id: \.self) { type in
                    Button(action: { symptomType = type }) {
                        Text(type)
                            .font(.petlyBody(14))
                            .foregroundColor(symptomType == type ? .white : .petlyDarkGreen)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(symptomType == type ? Color.petlyDarkGreen : Color.petlyLightGreen)
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private var severityStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How severe is the \(symptomType.lowercased())?")
                .font(.petlyTitle(22))
                .foregroundColor(.petlyDarkGreen)
            
            VStack(spacing: 20) {
                HStack {
                    Text("Mild")
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyFormIcon)
                    Spacer()
                    Text("Severe")
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyFormIcon)
                }
                
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { level in
                        Button(action: { severity = level }) {
                            ZStack {
                                Circle()
                                    .fill(severity == level ? severityColor(level) : Color.petlyLightGreen)
                                    .frame(width: 50, height: 50)
                                Text("\(level)")
                                    .font(.petlyBodyMedium(18))
                                    .foregroundColor(severity == level ? .white : .petlyDarkGreen)
                            }
                        }
                    }
                }
                
                Text(severityDescription(severity))
                    .font(.petlyBody(14))
                    .foregroundColor(.petlyFormIcon)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.petlyLightGreen.opacity(0.5))
                    .cornerRadius(12)
            }
        }
    }
    
    private var durationStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How long has \(dogName) had this symptom?")
                .font(.petlyTitle(22))
                .foregroundColor(.petlyDarkGreen)
            
            VStack(spacing: 12) {
                ForEach(durationOptions, id: \.self) { option in
                    Button(action: { duration = option }) {
                        HStack {
                            Text(option)
                                .font(.petlyBody(14))
                                .foregroundColor(duration == option ? .white : .petlyDarkGreen)
                            Spacer()
                            if duration == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(duration == option ? Color.petlyDarkGreen : Color.petlyLightGreen)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private var appetiteStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Has \(dogName)'s appetite changed?")
                .font(.petlyTitle(22))
                .foregroundColor(.petlyDarkGreen)
            
            VStack(spacing: 12) {
                ForEach(appetiteOptions, id: \.self) { option in
                    Button(action: { appetiteChange = option }) {
                        HStack {
                            Text(option)
                                .font(.petlyBody(14))
                                .foregroundColor(appetiteChange == option ? .white : .petlyDarkGreen)
                            Spacer()
                            if appetiteChange == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(appetiteChange == option ? Color.petlyDarkGreen : Color.petlyLightGreen)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private var behaviorStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How is \(dogName) behaving?")
                .font(.petlyTitle(22))
                .foregroundColor(.petlyDarkGreen)
            
            VStack(spacing: 12) {
                ForEach(behaviorOptions, id: \.self) { option in
                    Button(action: { behaviorChange = option }) {
                        HStack {
                            Text(option)
                                .font(.petlyBody(14))
                                .foregroundColor(behaviorChange == option ? .white : .petlyDarkGreen)
                            Spacer()
                            if behaviorChange == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(behaviorChange == option ? Color.petlyDarkGreen : Color.petlyLightGreen)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private var notesStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Anything else we should know?")
                .font(.petlyTitle(22))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Add any additional details that might help with the assessment.")
                .font(.petlyBody(14))
                .foregroundColor(.petlyFormIcon)
            
            TextEditor(text: $additionalNotes)
                .scrollContentBackground(.hidden)
                .foregroundColor(.petlyDarkGreen)
                .font(.petlyBody(14))
                .frame(minHeight: 120)
                .padding()
                .background(Color.petlyLightGreen)
                .cornerRadius(12)
            
            Text("Examples: recent diet changes, exposure to other animals, travel history, etc.")
                .font(.petlyBody(12))
                .foregroundColor(.petlyFormIcon)
                .italic()
        }
    }
    
    private var analyzingStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ProgressView()
                .scaleEffect(2)
                .tint(.petlyDarkGreen)
            
            Text("Analyzing \(dogName)'s symptoms...")
                .font(.petlyBodyMedium(18))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Our AI is reviewing the information you provided along with \(dogName)'s health history.")
                .font(.petlyBody(14))
                .foregroundColor(.petlyFormIcon)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .onAppear {
            performTriage()
        }
    }
    
    private var resultStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let result = triageResult {
                HStack {
                    Image(systemName: result.urgency.icon)
                        .font(.system(size: 40))
                        .foregroundColor(result.urgency.color)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.urgency.title)
                            .font(.petlyTitle(20))
                            .foregroundColor(.petlyDarkGreen)
                        Text(result.urgency.subtitle)
                            .font(.petlyBody(14))
                            .foregroundColor(.petlyFormIcon)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(result.urgency.color.opacity(0.1))
                .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Assessment")
                        .font(.petlyBodyMedium(16))
                        .foregroundColor(.petlyDarkGreen)
                    
                    Text(result.assessment)
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyDarkGreen)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recommended Actions")
                        .font(.petlyBodyMedium(16))
                        .foregroundColor(.petlyDarkGreen)
                    
                    ForEach(result.recommendations, id: \.self) { rec in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.petlyDarkGreen)
                            Text(rec)
                                .font(.petlyBody(14))
                                .foregroundColor(.petlyDarkGreen)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                
                Button(action: openVetSearch) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text(result.urgency == .emergency || result.urgency == .urgent ? "Find Emergency Vet Now" : "Contact Your Vet")
                    }
                    .font(.petlyBodyMedium(16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(result.urgency == .emergency || result.urgency == .urgent ? Color.red : Color.petlyDarkGreen)
                    .cornerRadius(12)
                }
                
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("Important Disclaimer")
                            .font(.petlyBodyMedium(12))
                            .foregroundColor(.petlyDarkGreen)
                    }
                    
                    Text("This assessment is for informational purposes only and is not a substitute for professional veterinary advice, diagnosis, or treatment. Always consult a qualified veterinarian for any health concerns about your pet.")
                        .font(.petlyBody(11))
                        .foregroundColor(.petlyFormIcon)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                HStack(spacing: 12) {
                    Button(action: saveAndDismiss) {
                        Text("Save & Close")
                            .font(.petlyBodyMedium(14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.petlyDarkGreen)
                            .cornerRadius(12)
                    }
                    
                    Button(action: { dismiss() }) {
                        Text("Dismiss")
                            .font(.petlyBodyMedium(14))
                            .foregroundColor(.petlyDarkGreen)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                    }
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Unable to complete analysis")
                        .font(.petlyBodyMedium(18))
                        .foregroundColor(.petlyDarkGreen)
                    
                    Text(error)
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyFormIcon)
                        .multilineTextAlignment(.center)
                    
                    Button(action: saveAndDismiss) {
                        Text("Save Symptom Anyway")
                            .font(.petlyBodyMedium(14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.petlyDarkGreen)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if currentStep.rawValue > 0 {
                Button(action: previousStep) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.petlyDarkGreen)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.petlyLightGreen)
                    .cornerRadius(12)
                }
            }
            
            Button(action: nextStep) {
                HStack {
                    Text(currentStep == .notes ? "Analyze" : "Next")
                    Image(systemName: currentStep == .notes ? "sparkles" : "chevron.right")
                }
                .font(.petlyBodyMedium(14))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canProceed ? Color.petlyDarkGreen : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!canProceed)
        }
        .padding()
        .background(Color.petlyBackground)
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .symptomType: return !symptomType.isEmpty
        case .severity: return true
        case .duration: return !duration.isEmpty
        case .appetite: return !appetiteChange.isEmpty
        case .behavior: return !behaviorChange.isEmpty
        case .notes: return true
        default: return false
        }
    }
    
    private func nextStep() {
        if currentStep == .notes {
            withAnimation {
                currentStep = .analyzing
            }
        } else if let nextIndex = TriageStep(rawValue: currentStep.rawValue + 1) {
            withAnimation {
                currentStep = nextIndex
            }
        }
    }
    
    private func previousStep() {
        if let prevIndex = TriageStep(rawValue: currentStep.rawValue - 1) {
            withAnimation {
                currentStep = prevIndex
            }
        }
    }
    
    private func severityColor(_ level: Int) -> Color {
        switch level {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return Color(red: 1, green: 0.4, blue: 0)
        case 5: return .red
        default: return .gray
        }
    }
    
    private func severityDescription(_ level: Int) -> String {
        switch level {
        case 1: return "Very mild - barely noticeable, not affecting daily activities"
        case 2: return "Mild - noticeable but not causing significant discomfort"
        case 3: return "Moderate - clearly affecting comfort or behavior"
        case 4: return "Significant - causing obvious distress or impairment"
        case 5: return "Severe - very concerning, may need immediate attention"
        default: return ""
        }
    }
    
    private func performTriage() {
        Task {
            do {
                let prompt = buildTriagePrompt()
                let dogProfile = buildDogProfile()
                
                let response = try await APIService.shared.sendChatMessage(
                    message: prompt,
                    conversationId: nil,
                    dogId: appState.currentDog?.id,
                    dogProfile: dogProfile,
                    healthLogs: nil
                )
                
                let result = parseTriageResponse(response.message.content)
                
                await MainActor.run {
                    triageResult = result
                    currentStep = .result
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Unable to analyze symptoms. The symptom will still be saved."
                    currentStep = .result
                }
            }
        }
    }
    
    private func buildTriagePrompt() -> String {
        return """
        I need a symptom triage assessment. Please analyze and respond in this exact format:
        
        URGENCY: [EMERGENCY/URGENT/SOON/MONITOR]
        ASSESSMENT: [2-3 sentence assessment]
        RECOMMENDATIONS:
        - [recommendation 1]
        - [recommendation 2]
        - [recommendation 3]
        
        Symptom details:
        - Type: \(symptomType)
        - Severity: \(severity)/5
        - Duration: \(duration)
        - Appetite: \(appetiteChange)
        - Behavior: \(behaviorChange)
        - Additional notes: \(additionalNotes.isEmpty ? "None" : additionalNotes)
        
        Be conservative - if in doubt, recommend veterinary consultation. Use EMERGENCY only for life-threatening situations.
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
            foodAllergies: dog.foodAllergies
        )
    }
    
    private func parseTriageResponse(_ response: String) -> TriageResult {
        var urgency: TriageUrgency = .monitor
        var assessment = ""
        var recommendations: [String] = []
        
        let lines = response.components(separatedBy: "\n")
        var inRecommendations = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.uppercased().contains("URGENCY:") {
                if trimmed.uppercased().contains("EMERGENCY") {
                    urgency = .emergency
                } else if trimmed.uppercased().contains("URGENT") {
                    urgency = .urgent
                } else if trimmed.uppercased().contains("SOON") {
                    urgency = .soon
                } else {
                    urgency = .monitor
                }
            } else if trimmed.uppercased().contains("ASSESSMENT:") {
                assessment = trimmed.replacingOccurrences(of: "ASSESSMENT:", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
            } else if trimmed.uppercased().contains("RECOMMENDATIONS:") {
                inRecommendations = true
            } else if inRecommendations && trimmed.hasPrefix("-") {
                let rec = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                if !rec.isEmpty {
                    recommendations.append(String(rec))
                }
            } else if !trimmed.isEmpty && assessment.isEmpty && !trimmed.uppercased().contains("URGENCY") {
                assessment += (assessment.isEmpty ? "" : " ") + trimmed
            }
        }
        
        if assessment.isEmpty {
            assessment = "Based on the symptoms described, we recommend monitoring \(dogName) closely."
        }
        
        if recommendations.isEmpty {
            recommendations = [
                "Monitor the symptom closely for any changes",
                "Ensure \(dogName) stays hydrated",
                "Contact your vet if symptoms worsen or persist"
            ]
        }
        
        return TriageResult(urgency: urgency, assessment: assessment, recommendations: recommendations)
    }
    
    private func openVetSearch() {
        if let url = URL(string: "https://www.google.com/maps/search/emergency+veterinarian+near+me") {
            UIApplication.shared.open(url)
        }
    }
    
    private func saveAndDismiss() {
        let dogId = appState.currentDog?.id ?? "default"
        
        var notes = "Duration: \(duration)\nAppetite: \(appetiteChange)\nBehavior: \(behaviorChange)"
        if !additionalNotes.isEmpty {
            notes += "\nNotes: \(additionalNotes)"
        }
        if let result = triageResult {
            notes += "\n\nTriage: \(result.urgency.title)\n\(result.assessment)"
        }
        
        let entry = HealthLogEntry(
            dogId: dogId,
            logType: "Symptom",
            timestamp: Date(),
            notes: notes,
            symptomType: symptomType,
            severityLevel: severity
        )
        
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save symptom: \(error)")
        }
        
        dismiss()
    }
}

struct TriageResult {
    let urgency: TriageUrgency
    let assessment: String
    let recommendations: [String]
}

enum TriageUrgency {
    case emergency
    case urgent
    case soon
    case monitor
    
    var title: String {
        switch self {
        case .emergency: return "Emergency"
        case .urgent: return "Urgent Care Needed"
        case .soon: return "See Vet Soon"
        case .monitor: return "Monitor at Home"
        }
    }
    
    var subtitle: String {
        switch self {
        case .emergency: return "Seek immediate veterinary care"
        case .urgent: return "Contact your vet today"
        case .soon: return "Schedule a vet visit within a few days"
        case .monitor: return "Watch for changes, no immediate action needed"
        }
    }
    
    var icon: String {
        switch self {
        case .emergency: return "exclamationmark.triangle.fill"
        case .urgent: return "exclamationmark.circle.fill"
        case .soon: return "calendar.badge.exclamationmark"
        case .monitor: return "eye.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .emergency: return .red
        case .urgent: return .orange
        case .soon: return .yellow
        case .monitor: return .green
        }
    }
}

#Preview {
    SymptomTriageView()
        .environmentObject(AppState())
}
