import SwiftUI
import SwiftData

struct CarePlanView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allLogs: [HealthLogEntry]
    @Query private var carePlans: [CarePlan]
    
    @State private var showCreatePlan = false
    @State private var selectedPlan: CarePlan?
    
    private var dogName: String {
        appState.currentDog?.name ?? "your pet"
    }
    
    private var activePlans: [CarePlan] {
        guard let dogId = appState.currentDog?.id else { return [] }
        return carePlans.filter { $0.dogId == dogId && $0.isActive && $0.endDate > Date() }
    }
    
    private var completedPlans: [CarePlan] {
        guard let dogId = appState.currentDog?.id else { return [] }
        return carePlans.filter { $0.dogId == dogId && (!$0.isActive || $0.endDate <= Date()) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        if activePlans.isEmpty && completedPlans.isEmpty {
                            emptyState
                        } else {
                            if !activePlans.isEmpty {
                                activePlansSection
                            }
                            
                            if !completedPlans.isEmpty {
                                completedPlansSection
                            }
                        }
                        
                        createPlanButton
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Care Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
            .sheet(isPresented: $showCreatePlan) {
                CreateCarePlanView()
                    .environmentObject(appState)
                    .buttonStyle(.plain)
            }
            .sheet(item: $selectedPlan) { plan in
                CarePlanDetailView(plan: plan)
                    .environmentObject(appState)
                    .buttonStyle(.plain)
            }
        }
        .buttonStyle(.plain)
        .preferredColorScheme(.light)
        .onboardingTooltip(
            key: .carePlans,
            message: "Create personalized care plans for your pet's health goals like weight management or allergy control.",
            icon: "list.clipboard"
        )
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 60))
                .foregroundColor(.petlyFormIcon)
            
            Text("No Care Plans Yet")
                .font(.petlyTitle(22))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Create a personalized care plan to help \(dogName) reach health goals like weight management, allergy control, or post-surgery recovery.")
                .font(.petlyBody(14))
                .foregroundColor(.petlyFormIcon)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }
    
    private var activePlansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Plans")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            ForEach(activePlans) { plan in
                CarePlanCard(plan: plan, onTap: { selectedPlan = plan })
            }
        }
    }
    
    private var completedPlansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Past Plans")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyFormIcon)
            
            ForEach(completedPlans) { plan in
                CarePlanCard(plan: plan, onTap: { selectedPlan = plan })
                    .opacity(0.7)
            }
        }
    }
    
    private var createPlanButton: some View {
        Button(action: { showCreatePlan = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Create New Care Plan")
            }
            .font(.petlyBodyMedium(16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.petlyDarkGreen)
            .cornerRadius(12)
        }
    }
}

struct CarePlanCard: View {
    let plan: CarePlan
    let onTap: () -> Void
    
    private var progress: Double {
        let total = plan.tasks.count
        guard total > 0 else { return 0 }
        let completed = plan.tasks.filter { $0.isCompleted }.count
        return Double(completed) / Double(total)
    }
    
    private var daysRemaining: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: plan.endDate).day ?? 0
        return max(0, days)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: plan.goalType.icon)
                        .font(.system(size: 24))
                        .foregroundColor(plan.goalType.color)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plan.title)
                            .font(.petlyBodyMedium(16))
                            .foregroundColor(.petlyDarkGreen)
                        Text(plan.goalType.rawValue)
                            .font(.petlyBody(12))
                            .foregroundColor(.petlyFormIcon)
                    }
                    
                    Spacer()
                    
                    if plan.isActive && plan.endDate > Date() {
                        Text("\(daysRemaining)d left")
                            .font(.petlyBody(12))
                            .foregroundColor(.petlyFormIcon)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.petlyLightGreen)
                            .cornerRadius(8)
                    }
                }
                
                ProgressView(value: progress)
                    .tint(plan.goalType.color)
                
                HStack {
                    Text("\(Int(progress * 100))% complete")
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                    
                    Spacer()
                    
                    Text("\(plan.tasks.filter { $0.isCompleted }.count)/\(plan.tasks.count) tasks")
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
        }
    }
}

struct CreateCarePlanView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allLogs: [HealthLogEntry]
    
    @State private var selectedGoals: Set<CarePlanGoalType> = []
    @State private var customTitle: String = ""
    @State private var duration: Int = 14
    @State private var isGenerating = false
    @State private var generatedPlan: GeneratedPlanData?
    @State private var errorMessage: String?
    
    private var conflictingGoals: [Set<CarePlanGoalType>] {
        [[.weightGain, .weightLoss]]
    }
    
    private var primaryGoal: CarePlanGoalType? {
        selectedGoals.first
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
                    VStack(spacing: 24) {
                        if generatedPlan == nil {
                            goalSelectionSection
                            
                            if !selectedGoals.isEmpty {
                                durationSection
                                generateButton
                            }
                        } else {
                            planPreviewSection
                        }
                    }
                    .padding()
                }
                
                if isGenerating {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Creating personalized plan...")
                            .font(.petlyBodyMedium(16))
                            .foregroundColor(.white)
                    }
                    .padding(30)
                    .background(Color.petlyDarkGreen)
                    .cornerRadius(16)
                }
            }
            .navigationTitle("Create Care Plan")
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
        .preferredColorScheme(.light)
    }
    
    private var goalSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's the goal for \(dogName)?")
                .font(.petlyTitle(22))
                .foregroundColor(.petlyDarkGreen)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(CarePlanGoalType.allCases, id: \.self) { goal in
                    Button(action: { toggleGoal(goal) }) {
                        VStack(spacing: 8) {
                            Image(systemName: goal.icon)
                                .font(.system(size: 30))
                                .foregroundColor(selectedGoals.contains(goal) ? .white : goal.color)
                            Text(goal.rawValue)
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(selectedGoals.contains(goal) ? .white : .petlyDarkGreen)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.7)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .frame(minHeight: 90)
                        .padding()
                        .background(selectedGoals.contains(goal) ? goal.color : Color.white)
                        .cornerRadius(12)
                    }
                }
            }
            
            if selectedGoals.contains(.custom) {
                TextField("Describe the goal...", text: $customTitle)
                    .font(.petlyBody(14))
                    .padding()
                    .background(Color.petlyLightGreen)
                    .cornerRadius(12)
            }
        }
    }
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plan Duration")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            // Use flexible layout that wraps on smaller screens or larger text
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80, maximum: 150))], spacing: 8) {
                ForEach([7, 14, 21, 30], id: \.self) { days in
                    Button(action: { duration = days }) {
                        Text("\(days) days")
                            .font(.petlyBody(14))
                            .foregroundColor(duration == days ? .white : .petlyDarkGreen)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(minWidth: 60)
                            .background(duration == days ? Color.petlyDarkGreen : Color.petlyLightGreen)
                            .cornerRadius(20)
                    }
                }
            }
        }
    }
    
    private var generateButton: some View {
        Button(action: generatePlan) {
            HStack {
                Image(systemName: "sparkles")
                Text("Generate Personalized Plan")
            }
            .font(.petlyBodyMedium(16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.petlyDarkGreen)
            .cornerRadius(12)
        }
        .disabled(selectedGoals.contains(.custom) && customTitle.isEmpty)
    }
    
    private var planPreviewSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let plan = generatedPlan {
                HStack {
                    Image(systemName: selectedGoal?.icon ?? "list.clipboard")
                        .font(.system(size: 30))
                        .foregroundColor(selectedGoal?.color ?? .petlyDarkGreen)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plan.title)
                            .font(.petlyTitle(20))
                            .foregroundColor(.petlyDarkGreen)
                        Text("\(duration) day plan · \(selectedGoals.count) goal\(selectedGoals.count == 1 ? "" : "s")")
                            .font(.petlyBody(14))
                            .foregroundColor(.petlyFormIcon)
                    }
                }
                
                Text(plan.description)
                    .font(.petlyBody(14))
                    .foregroundColor(.petlyDarkGreen)
                    .padding()
                    .background(Color.petlyLightGreen.opacity(0.5))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily Tasks")
                        .font(.petlyBodyMedium(16))
                        .foregroundColor(.petlyDarkGreen)
                    
                    ForEach(plan.tasks, id: \.title) { task in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "circle")
                                .foregroundColor(.petlyFormIcon)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.petlyBodyMedium(14))
                                    .foregroundColor(.petlyDarkGreen)
                                if let desc = task.description {
                                    Text(desc)
                                        .font(.petlyBody(12))
                                        .foregroundColor(.petlyFormIcon)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                }
                
                if !plan.milestones.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Milestones")
                            .font(.petlyBodyMedium(16))
                            .foregroundColor(.petlyDarkGreen)
                        
                        ForEach(plan.milestones, id: \.day) { milestone in
                            HStack {
                                Text("Day \(milestone.day)")
                                    .font(.petlyBodyMedium(14))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedGoal?.color ?? .petlyDarkGreen)
                                    .cornerRadius(8)
                                
                                Text(milestone.description)
                                    .font(.petlyBody(14))
                                    .foregroundColor(.petlyDarkGreen)
                            }
                        }
                    }
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
                    
                    Text("This care plan is AI-generated for informational purposes only. It is not a substitute for professional veterinary advice. Always consult your veterinarian before starting any new health regimen for your pet.")
                        .font(.petlyBody(11))
                        .foregroundColor(.petlyFormIcon)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                HStack(spacing: 12) {
                    Button(action: { generatedPlan = nil }) {
                        Text("Regenerate")
                            .font(.petlyBodyMedium(14))
                            .foregroundColor(.petlyDarkGreen)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                    }
                    
                    Button(action: savePlan) {
                        Text("Start Plan")
                            .font(.petlyBodyMedium(14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.petlyDarkGreen)
                            .cornerRadius(12)
                    }
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.petlyBody(14))
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
    
    private func toggleGoal(_ goal: CarePlanGoalType) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            for conflict in conflictingGoals {
                if conflict.contains(goal) {
                    for conflicting in conflict where conflicting != goal {
                        selectedGoals.remove(conflicting)
                    }
                }
            }
            selectedGoals.insert(goal)
        }
    }
    
    private func generatePlan() {
        guard let goal = primaryGoal else { return }
        
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let prompt = buildPlanPrompt(goal: goal)
                let dogProfile = buildDogProfile()
                let healthLogs = buildHealthLogs()
                
                let response = try await APIService.shared.sendChatMessage(
                    message: prompt,
                    conversationId: nil,
                    dogId: appState.currentDog?.id,
                    dogProfile: dogProfile,
                    healthLogs: healthLogs
                )
                
                let plan = parsePlanResponse(response.message.content, goal: goal)
                
                await MainActor.run {
                    generatedPlan = plan
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Unable to generate plan. Please try again."
                    isGenerating = false
                }
            }
        }
    }
    
    private func buildPlanPrompt(goal: CarePlanGoalType) -> String {
        let goalDescriptions = selectedGoals.map { $0 == .custom ? customTitle : $0.rawValue }
        let goalDescription = goalDescriptions.joined(separator: ", ")
        
        return """
        Create a \(duration)-day care plan for \(dogName) focused on: \(goalDescription)
        
        Respond in this exact format:
        TITLE: [Short plan title]
        DESCRIPTION: [2-3 sentence overview]
        TASKS:
        - [Daily task 1]|[Optional brief description]
        - [Daily task 2]|[Optional brief description]
        - [Daily task 3]|[Optional brief description]
        MILESTONES:
        - Day [X]: [Milestone description]
        - Day [X]: [Milestone description]
        
        Make tasks specific, actionable, and achievable. Include 3-5 daily tasks and 2-3 milestones.
        Consider the pet's health history when creating the plan.
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
            foodAllergies: dog.foodAllergies,
            sex: dog.sex,
            isNeutered: dog.isNeutered,
            medicalHistory: dog.medicalHistory,
            currentMedications: dog.currentMedications
        )
    }
    
    private func buildHealthLogs() -> [ChatHealthLog]? {
        guard let dogId = appState.currentDog?.id else { return nil }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentLogs = allLogs.filter { $0.dogId == dogId && $0.timestamp >= thirtyDaysAgo }
        
        guard !recentLogs.isEmpty else { return nil }
        
        let formatter = ISO8601DateFormatter()
        return Array(recentLogs.prefix(50)).map { log in
            ChatHealthLog(
                logType: log.logType,
                timestamp: formatter.string(from: log.timestamp),
                notes: log.notes.isEmpty ? nil : log.notes,
                mealType: log.mealType,
                amount: log.amount,
                duration: log.duration,
                moodLevel: log.moodLevel,
                symptomType: log.symptomType,
                severityLevel: log.severityLevel,
                digestionQuality: log.digestionQuality,
                activityType: log.activityType,
                supplementName: log.supplementName,
                dosage: log.dosage,
                appointmentType: log.appointmentType,
                location: log.location,
                groomingType: log.groomingType,
                treatName: log.treatName,
                waterAmount: log.waterAmount
            )
        }
    }
    
    private func parsePlanResponse(_ response: String, goal: CarePlanGoalType) -> GeneratedPlanData {
        var title = "\(goal.rawValue) Plan"
        var description = "A personalized plan to help \(dogName) achieve their health goals."
        var tasks: [GeneratedTaskData] = []
        var milestones: [GeneratedMilestoneData] = []
        
        let lines = response.components(separatedBy: "\n")
        var inTasks = false
        var inMilestones = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.uppercased().hasPrefix("TITLE:") {
                title = trimmed.replacingOccurrences(of: "TITLE:", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
            } else if trimmed.uppercased().hasPrefix("DESCRIPTION:") {
                description = trimmed.replacingOccurrences(of: "DESCRIPTION:", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
            } else if trimmed.uppercased().contains("TASKS:") {
                inTasks = true
                inMilestones = false
            } else if trimmed.uppercased().contains("MILESTONES:") {
                inTasks = false
                inMilestones = true
            } else if inTasks && trimmed.hasPrefix("-") {
                let taskContent = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                let parts = taskContent.components(separatedBy: "|")
                let taskTitle = parts[0].trimmingCharacters(in: .whitespaces)
                let taskDesc = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : nil
                if !taskTitle.isEmpty {
                    tasks.append(GeneratedTaskData(title: taskTitle, description: taskDesc))
                }
            } else if inMilestones && trimmed.hasPrefix("-") {
                let milestoneContent = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                if let dayMatch = milestoneContent.range(of: "Day \\d+", options: .regularExpression) {
                    let dayStr = String(milestoneContent[dayMatch]).replacingOccurrences(of: "Day ", with: "")
                    if let day = Int(dayStr) {
                        let desc = milestoneContent.replacingOccurrences(of: "Day \\d+:?\\s*", with: "", options: .regularExpression)
                        milestones.append(GeneratedMilestoneData(day: day, description: desc))
                    }
                }
            }
        }
        
        if tasks.isEmpty {
            tasks = [
                GeneratedTaskData(title: "Morning check-in", description: "Observe energy and appetite"),
                GeneratedTaskData(title: "Activity session", description: "30 minutes of exercise"),
                GeneratedTaskData(title: "Evening log", description: "Record any changes or concerns")
            ]
        }
        
        if milestones.isEmpty {
            milestones = [
                GeneratedMilestoneData(day: duration / 2, description: "Mid-plan check-in"),
                GeneratedMilestoneData(day: duration, description: "Plan completion review")
            ]
        }
        
        return GeneratedPlanData(title: title, description: description, tasks: tasks, milestones: milestones)
    }
    
    private func savePlan() {
        guard let goal = primaryGoal, let planData = generatedPlan else { return }
        
        let dogId = appState.currentDog?.id ?? "default"
        let endDate = Calendar.current.date(byAdding: .day, value: duration, to: Date()) ?? Date()
        
        let plan = CarePlan(
            dogId: dogId,
            title: planData.title,
            goalType: goal,
            startDate: Date(),
            endDate: endDate,
            planDescription: planData.description
        )
        
        for taskData in planData.tasks {
            let task = CarePlanTask(
                title: taskData.title,
                taskDescription: taskData.description,
                isDaily: true
            )
            plan.tasks.append(task)
        }
        
        for milestoneData in planData.milestones {
            if let milestoneDate = Calendar.current.date(byAdding: .day, value: milestoneData.day, to: Date()) {
                let milestone = CarePlanMilestone(
                    day: milestoneData.day,
                    milestoneDescription: milestoneData.description,
                    targetDate: milestoneDate
                )
                plan.milestones.append(milestone)
            }
        }
        
        modelContext.insert(plan)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save plan. Please try again."
        }
    }
}

struct GeneratedPlanData {
    let title: String
    let description: String
    let tasks: [GeneratedTaskData]
    let milestones: [GeneratedMilestoneData]
}

struct GeneratedTaskData {
    let title: String
    let description: String?
}

struct GeneratedMilestoneData {
    let day: Int
    let description: String
}

struct CarePlanDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var plan: CarePlan
    
    private var progress: Double {
        let total = plan.tasks.count
        guard total > 0 else { return 0 }
        let completed = plan.tasks.filter { $0.isCompleted }.count
        return Double(completed) / Double(total)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        progressSection
                        tasksSection
                        milestonesSection
                        
                        if plan.isActive {
                            endPlanButton
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle(plan.title)
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
        .preferredColorScheme(.light)
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: plan.goalType.icon)
                .font(.system(size: 50))
                .foregroundColor(plan.goalType.color)
            
            Text(plan.goalType.rawValue)
                .font(.petlyBody(14))
                .foregroundColor(.petlyFormIcon)
            
            Text(plan.planDescription)
                .font(.petlyBody(14))
                .foregroundColor(.petlyDarkGreen)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Progress")
                    .font(.petlyBodyMedium(16))
                    .foregroundColor(.petlyDarkGreen)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.petlyBodyMedium(16))
                    .foregroundColor(plan.goalType.color)
            }
            
            ProgressView(value: progress)
                .tint(plan.goalType.color)
                .scaleEffect(y: 2)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Started")
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                    Text(plan.startDate, style: .date)
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.petlyDarkGreen)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Ends")
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                    Text(plan.endDate, style: .date)
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.petlyDarkGreen)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Tasks")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            ForEach(plan.tasks) { task in
                TaskRow(task: task, color: plan.goalType.color) {
                    toggleTask(task)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Milestones")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            ForEach(plan.milestones) { milestone in
                MilestoneRow(milestone: milestone, color: plan.goalType.color)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private var endPlanButton: some View {
        Button(action: endPlan) {
            Text("End Plan Early")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
        }
    }
    
    private func toggleTask(_ task: CarePlanTask) {
        task.isCompleted.toggle()
        if task.isCompleted {
            task.completedDate = Date()
        } else {
            task.completedDate = nil
        }
        
        try? modelContext.save()
    }
    
    private func endPlan() {
        plan.isActive = false
        try? modelContext.save()
        dismiss()
    }
}

struct TaskRow: View {
    let task: CarePlanTask
    let color: Color
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(task.isCompleted ? color : .petlyFormIcon)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(task.isCompleted ? .petlyFormIcon : .petlyDarkGreen)
                        .strikethrough(task.isCompleted)
                    
                    if let desc = task.taskDescription {
                        Text(desc)
                            .font(.petlyBody(12))
                            .foregroundColor(.petlyFormIcon)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(task.isCompleted ? Color.petlyLightGreen.opacity(0.3) : Color.petlyLightGreen)
            .cornerRadius(12)
        }
    }
}

struct MilestoneRow: View {
    let milestone: CarePlanMilestone
    let color: Color
    
    private var isPast: Bool {
        milestone.targetDate < Date()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text("Day \(milestone.day)")
                .font(.petlyBodyMedium(12))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isPast ? color : color.opacity(0.5))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.milestoneDescription)
                    .font(.petlyBody(14))
                    .foregroundColor(.petlyDarkGreen)
                Text(milestone.targetDate, style: .date)
                    .font(.petlyBody(12))
                    .foregroundColor(.petlyFormIcon)
            }
            
            Spacer()
            
            if isPast {
                Image(systemName: milestone.isAchieved ? "checkmark.circle.fill" : "clock")
                    .foregroundColor(milestone.isAchieved ? .green : .orange)
            }
        }
        .padding()
        .background(Color.petlyLightGreen.opacity(0.3))
        .cornerRadius(12)
    }
}

#Preview {
    CarePlanView()
        .environmentObject(AppState())
}
