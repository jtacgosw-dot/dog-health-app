import SwiftUI
import SwiftData
import PDFKit

struct VetVisitPackView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Query private var allLogs: [HealthLogEntry]
    @Query private var carePlans: [CarePlan]
    
    @State private var selectedTimeRange: TimeRange = .lastMonth
    @State private var isGenerating = false
    @State private var isGeneratingAISummary = false
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    @State private var aiSummary: String?
    @State private var showEmergencyCard = false
    
    enum TimeRange: String, CaseIterable {
        case lastWeek = "Last 7 Days"
        case lastTwoWeeks = "Last 14 Days"
        case lastMonth = "Last 30 Days"
        case lastThreeMonths = "Last 3 Months"
        
        var days: Int {
            switch self {
            case .lastWeek: return 7
            case .lastTwoWeeks: return 14
            case .lastMonth: return 30
            case .lastThreeMonths: return 90
            }
        }
    }
    
    private var dogName: String {
        appState.currentDog?.name ?? "your pet"
    }
    
    private var filteredLogs: [HealthLogEntry] {
        guard let dogId = appState.currentDog?.id else { return [] }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        return allLogs.filter { $0.dogId == dogId && $0.timestamp >= cutoffDate }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    private var activeCarePlans: [CarePlan] {
        guard let dogId = appState.currentDog?.id else { return [] }
        return carePlans.filter { $0.dogId == dogId && $0.isActive && $0.endDate > Date() }
    }
    
    private var symptomLogs: [HealthLogEntry] {
        filteredLogs.filter { $0.logType == "Symptom" }
    }
    
    private var mealLogs: [HealthLogEntry] {
        filteredLogs.filter { $0.logType == "Meals" }
    }
    
    private var activityLogs: [HealthLogEntry] {
        filteredLogs.filter { $0.logType == "Walk" || $0.logType == "Playtime" }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        
                        quickActionsSection
                        
                        timeRangeSection
                        
                        packContentsPreview
                        
                        aiSummarySection
                        
                        generateButton
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
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
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    VetPackShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showEmergencyCard) {
                EmergencyCardView()
                    .environmentObject(appState)
                    .buttonStyle(.plain)
            }
        }
        .buttonStyle(.plain)
        .preferredColorScheme(.light)
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.petlyLightGreen)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "suitcase.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.petlyDarkGreen)
            }
            
            Text("Vet Visit Pack")
                .font(.petlyTitle(28))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Everything your vet needs in one shareable document")
                .font(.petlyBody(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            VetPackQuickActionButton(
                icon: "creditcard.fill",
                title: "Emergency Card",
                subtitle: "For pet sitters",
                color: .red
            ) {
                showEmergencyCard = true
            }
            
            VetPackQuickActionButton(
                icon: "square.and.arrow.up",
                title: "Quick Share",
                subtitle: "Text to vet",
                color: .blue
            ) {
                generateAndShare()
            }
        }
    }
    
    private var timeRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Include data from")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedTimeRange) { _, _ in
                aiSummary = nil
            }
        }
    }
    
    private var packContentsPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pack Contents")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            VStack(spacing: 0) {
                PackContentRow(
                    icon: "pawprint.fill",
                    title: "Pet Profile",
                    detail: "\(dogName) - \(appState.currentDog?.breed ?? "Unknown breed")",
                    included: true
                )
                
                Divider().padding(.horizontal)
                
                PackContentRow(
                    icon: "heart.text.square.fill",
                    title: "Symptom History",
                    detail: "\(symptomLogs.count) entries",
                    included: !symptomLogs.isEmpty
                )
                
                Divider().padding(.horizontal)
                
                PackContentRow(
                    icon: "fork.knife",
                    title: "Meal Log",
                    detail: "\(mealLogs.count) entries",
                    included: !mealLogs.isEmpty
                )
                
                Divider().padding(.horizontal)
                
                PackContentRow(
                    icon: "figure.walk",
                    title: "Activity Log",
                    detail: "\(activityLogs.count) entries",
                    included: !activityLogs.isEmpty
                )
                
                Divider().padding(.horizontal)
                
                PackContentRow(
                    icon: "list.clipboard.fill",
                    title: "Active Care Plans",
                    detail: activeCarePlans.isEmpty ? "None" : "\(activeCarePlans.count) plan(s)",
                    included: !activeCarePlans.isEmpty
                )
                
                Divider().padding(.horizontal)
                
                PackContentRow(
                    icon: "brain.head.profile",
                    title: "AI Health Summary",
                    detail: aiSummary != nil ? "Generated" : "Will generate",
                    included: true
                )
            }
            .background(Color.petlyLightGreen)
            .cornerRadius(12)
        }
    }
    
    private var aiSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI Summary for Vet")
                    .font(.petlyBodyMedium(16))
                    .foregroundColor(.petlyDarkGreen)
                
                Spacer()
                
                if aiSummary == nil {
                    Button(action: generateAISummary) {
                        HStack(spacing: 4) {
                            if isGeneratingAISummary {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isGeneratingAISummary ? "Generating..." : "Generate")
                        }
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyDarkGreen)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.petlyLightGreen)
                        .cornerRadius(8)
                    }
                    .disabled(isGeneratingAISummary)
                }
            }
            
            if let summary = aiSummary {
                Text(summary)
                    .font(.petlyBody(14))
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.petlyLightGreen.opacity(0.5))
                    .cornerRadius(12)
            } else {
                Text("An AI-generated summary will be included in your Vet Visit Pack, highlighting key health patterns and concerns for your veterinarian.")
                    .font(.petlyBody(12))
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    private var generateButton: some View {
        Button(action: generateAndShare) {
            HStack {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "doc.fill")
                }
                Text(isGenerating ? "Generating Pack..." : "Generate Vet Visit Pack")
            }
            .font(.petlyBodyMedium(16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.petlyDarkGreen)
            .cornerRadius(12)
        }
        .disabled(isGenerating)
    }
    
    private func generateAISummary() {
        isGeneratingAISummary = true
        
        Task {
            do {
                let prompt = buildSummaryPrompt()
                let dogProfile = buildDogProfile()
                let healthLogs = buildHealthLogs()
                
                let response = try await APIService.shared.sendChatMessage(
                    message: prompt,
                    conversationId: nil,
                    dogId: appState.currentDog?.id,
                    dogProfile: dogProfile,
                    healthLogs: healthLogs
                )
                
                await MainActor.run {
                    aiSummary = response.message.content
                    isGeneratingAISummary = false
                }
            } catch {
                await MainActor.run {
                    aiSummary = "Unable to generate AI summary. The pack will include all logged health data."
                    isGeneratingAISummary = false
                }
            }
        }
    }
    
    private func buildSummaryPrompt() -> String {
        """
        Generate a concise professional summary for a veterinarian visit. Include:
        1. Key health observations from the past \(selectedTimeRange.rawValue.lowercased())
        2. Any concerning patterns or symptoms
        3. Notable changes in behavior, appetite, or activity
        4. Current care plan status if any
        
        Keep it under 200 words, professional tone, bullet points for key items.
        Start with "Health Summary for [pet name]:" and end with any recommended discussion points for the vet visit.
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
            allergies: dog.allergies.isEmpty ? nil : dog.allergies
        )
    }
    
    private func buildHealthLogs() -> [ChatHealthLog] {
        let formatter = ISO8601DateFormatter()
        return filteredLogs.prefix(50).map { log in
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
    
    private func generateAndShare() {
        isGenerating = true
        
        Task {
            if aiSummary == nil {
                await generateAISummarySync()
            }
            
            await MainActor.run {
                generatePDF()
            }
        }
    }
    
    private func generateAISummarySync() async {
        do {
            let prompt = buildSummaryPrompt()
            let dogProfile = buildDogProfile()
            let healthLogs = buildHealthLogs()
            
            let response = try await APIService.shared.sendChatMessage(
                message: prompt,
                conversationId: nil,
                dogId: appState.currentDog?.id,
                dogProfile: dogProfile,
                healthLogs: healthLogs
            )
            
            await MainActor.run {
                aiSummary = response.message.content
            }
        } catch {
            await MainActor.run {
                aiSummary = "Health data summary included below."
            }
        }
    }
    
    private func generatePDF() {
        DispatchQueue.global(qos: .userInitiated).async {
            let pdfData = createPDFData()
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: Date())
            
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("VetVisitPack_\(dogName)_\(dateString).pdf")
            
            do {
                try pdfData.write(to: tempURL)
                
                DispatchQueue.main.async {
                    self.pdfURL = tempURL
                    self.isGenerating = false
                    self.showShareSheet = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.isGenerating = false
                }
            }
        }
    }
    
    private func createPDFData() -> Data {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 40
        let contentWidth = pageWidth - (margin * 2)
        
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        
        let data = pdfRenderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = margin
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 28),
                .foregroundColor: UIColor(red: 0.2, green: 0.5, blue: 0.3, alpha: 1.0)
            ]
            
            let sectionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor(red: 0.2, green: 0.5, blue: 0.3, alpha: 1.0)
            ]
            
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.darkGray
            ]
            
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.darkGray
            ]
            
            let smallAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor.gray
            ]
            
            let logoRect = CGRect(x: margin, y: yPosition, width: 40, height: 40)
            let logoPath = UIBezierPath(ovalIn: logoRect)
            UIColor(red: 0.9, green: 0.95, blue: 0.9, alpha: 1.0).setFill()
            logoPath.fill()
            
            let pawIcon = "🐾"
            let pawAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 24)]
            pawIcon.draw(at: CGPoint(x: margin + 8, y: yPosition + 6), withAttributes: pawAttributes)
            
            "Vet Visit Pack".draw(at: CGPoint(x: margin + 50, y: yPosition + 5), withAttributes: titleAttributes)
            yPosition += 50
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            "Generated \(dateFormatter.string(from: Date())) by Petly".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: smallAttributes)
            yPosition += 25
            
            drawDivider(context: context, y: yPosition, margin: margin, width: contentWidth)
            yPosition += 15
            
            "PET PROFILE".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttributes)
            yPosition += 25
            
            if let dog = appState.currentDog {
                let weightText = dog.weight.map { String(format: "%.1f", $0) + " lbs" } ?? "Unknown"
                let profileInfo = [
                    ("Name:", dog.name),
                    ("Breed:", dog.breed),
                    ("Age:", "\(dog.age) years"),
                    ("Weight:", weightText)
                ]
                
                for (label, value) in profileInfo {
                    "\(label) \(value)".draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: bodyAttributes)
                    yPosition += 18
                }
            }
            yPosition += 10
            
            drawDivider(context: context, y: yPosition, margin: margin, width: contentWidth)
            yPosition += 15
            
            "AI HEALTH SUMMARY".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttributes)
            yPosition += 25
            
            if let summary = aiSummary {
                let summaryRect = CGRect(x: margin + 10, y: yPosition, width: contentWidth - 20, height: 150)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4
                let summaryAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11),
                    .foregroundColor: UIColor.darkGray,
                    .paragraphStyle: paragraphStyle
                ]
                summary.draw(in: summaryRect, withAttributes: summaryAttributes)
                yPosition += 160
            } else {
                "No AI summary available.".draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: bodyAttributes)
                yPosition += 25
            }
            
            drawDivider(context: context, y: yPosition, margin: margin, width: contentWidth)
            yPosition += 15
            
            "HEALTH LOG (\(selectedTimeRange.rawValue))".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttributes)
            yPosition += 25
            
            let logsByType = Dictionary(grouping: filteredLogs) { $0.logType }
            
            for (logType, logs) in logsByType.sorted(by: { $0.key < $1.key }) {
                if yPosition > pageHeight - 100 {
                    context.beginPage()
                    yPosition = margin
                }
                
                "\(logType) (\(logs.count))".draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: headerAttributes)
                yPosition += 20
                
                for log in logs.prefix(10) {
                    if yPosition > pageHeight - 60 {
                        context.beginPage()
                        yPosition = margin
                    }
                    
                    let logDateFormatter = DateFormatter()
                    logDateFormatter.dateStyle = .short
                    logDateFormatter.timeStyle = .short
                    
                    var logText = "• \(logDateFormatter.string(from: log.timestamp))"
                    
                    if logType == "Symptom", let symptomType = log.symptomType {
                        logText += " - \(symptomType)"
                        if let severity = log.severityLevel {
                            logText += " (Severity: \(severity)/5)"
                        }
                    } else if logType == "Walk" || logType == "Playtime", let duration = log.duration {
                        logText += " - \(duration) min"
                    } else if logType == "Meals", let mealType = log.mealType {
                        logText += " - \(mealType)"
                    } else if !log.notes.isEmpty {
                        logText += " - \(String(log.notes.prefix(50)))"
                    }
                    
                    logText.draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: bodyAttributes)
                    yPosition += 16
                }
                
                if logs.count > 10 {
                    "... and \(logs.count - 10) more".draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: smallAttributes)
                    yPosition += 16
                }
                
                yPosition += 10
            }
            
            if !activeCarePlans.isEmpty {
                if yPosition > pageHeight - 120 {
                    context.beginPage()
                    yPosition = margin
                }
                
                drawDivider(context: context, y: yPosition, margin: margin, width: contentWidth)
                yPosition += 15
                
                "ACTIVE CARE PLANS".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttributes)
                yPosition += 25
                
                for plan in activeCarePlans {
                    "\(plan.title) - \(plan.goalType.rawValue)".draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: headerAttributes)
                    yPosition += 18
                    
                    let completedTasks = plan.tasks.filter { $0.isCompleted }.count
                    let totalTasks = plan.tasks.count
                    let progress = totalTasks > 0 ? Int((Double(completedTasks) / Double(totalTasks)) * 100) : 0
                    
                    "Progress: \(progress)% (\(completedTasks)/\(totalTasks) tasks)".draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: bodyAttributes)
                    yPosition += 16
                    
                    let endDateFormatter = DateFormatter()
                    endDateFormatter.dateStyle = .medium
                    "End Date: \(endDateFormatter.string(from: plan.endDate))".draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: bodyAttributes)
                    yPosition += 20
                }
            }
            
            yPosition = pageHeight - 50
            let disclaimer = "This document is for informational purposes only. Please consult with your veterinarian for professional medical advice."
            let disclaimerRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 30)
            disclaimer.draw(in: disclaimerRect, withAttributes: smallAttributes)
        }
        
        return data
    }
    
    private func drawDivider(context: UIGraphicsPDFRendererContext, y: CGFloat, margin: CGFloat, width: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: margin + width, y: y))
        UIColor.lightGray.setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }
}

struct VetPackQuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.petlyBodyMedium(12))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.petlyBody(10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.petlyLightGreen.opacity(0.5))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PackContentRow: View {
    let icon: String
    let title: String
    let detail: String
    let included: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(included ? .petlyDarkGreen : .gray)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(included ? .primary : .gray)
                
                Text(detail)
                    .font(.petlyBody(12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: included ? "checkmark.circle.fill" : "circle")
                .foregroundColor(included ? .petlyDarkGreen : .gray)
        }
        .padding()
    }
}

struct EmergencyCardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false
    @State private var cardImage: UIImage?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Emergency Pet Card")
                        .font(.petlyTitle(24))
                        .foregroundColor(.petlyDarkGreen)
                    
                    Text("Share this card with pet sitters, dog walkers, or keep it in your wallet")
                        .font(.petlyBody(14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    emergencyCardPreview
                    
                    Button(action: shareCard) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Card")
                        }
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
                .padding(.top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body)
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = cardImage {
                    VetPackShareSheet(items: [image])
                }
            }
        }
        .preferredColorScheme(.light)
    }
    
    private var emergencyCardPreview: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "cross.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text("EMERGENCY PET INFO")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.red)
            
            VStack(alignment: .leading, spacing: 12) {
                if let dog = appState.currentDog {
                    let weightText = dog.weight.map { String(format: "%.0f", $0) + " lbs" } ?? "Unknown"
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dog.name)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("\(dog.breed) • \(dog.age) yrs • \(weightText)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Circle()
                            .fill(Color.petlyLightGreen)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(String(dog.name.prefix(1)))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.petlyDarkGreen)
                            )
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(icon: "person.fill", label: "Owner", value: appState.currentUser?.fullName ?? "Not set")
                        InfoRow(icon: "phone.fill", label: "Phone", value: "Contact via Petly app")
                        InfoRow(icon: "cross.case.fill", label: "Vet", value: "See Petly app for details")
                    }
                    
                    Divider()
                    
                    Text("In case of emergency, please contact the owner immediately. All health records available in Petly app.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.white)
        }
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
    
    private func shareCard() {
        let renderer = ImageRenderer(content: emergencyCardPreview)
        renderer.scale = 3.0
        
        if let image = renderer.uiImage {
            cardImage = image
            showShareSheet = true
        }
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.petlyDarkGreen)
                .frame(width: 20)
            
            Text(label + ":")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

struct VetPackShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    VetVisitPackView()
        .environmentObject(AppState())
}
