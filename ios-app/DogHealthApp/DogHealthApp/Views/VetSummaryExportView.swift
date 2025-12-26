import SwiftUI
import SwiftData
import PDFKit

struct VetSummaryExportView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Query private var allLogs: [HealthLogEntry]
    
    @State private var selectedTimeRange: TimeRange = .lastMonth
    @State private var includeSymptoms = true
    @State private var includeMeals = true
    @State private var includeWalks = true
    @State private var includeDigestion = true
    @State private var includeMood = true
    @State private var includeNotes = true
    @State private var isGenerating = false
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    
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
    
    private var filteredLogs: [HealthLogEntry] {
        guard let dogId = appState.currentDog?.id else { return [] }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        
        return allLogs.filter { log in
            log.dogId == dogId && log.timestamp >= cutoffDate
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    private var logsToExport: [HealthLogEntry] {
        filteredLogs.filter { log in
            switch log.logType {
            case "Symptom": return includeSymptoms
            case "Meals": return includeMeals
            case "Walk": return includeWalks
            case "Digestion": return includeDigestion
            case "Mood": return includeMood
            case "Notes": return includeNotes
            default: return true
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    timeRangeSection
                    
                    categoriesSection
                    
                    summaryPreview
                    
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
                VetSummaryShareSheet(items: [url])
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 50))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Vet Visit Summary")
                .font(.petlyTitle(24))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Generate a PDF summary of your pet's health logs to share with your veterinarian")
                .font(.petlyBody(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    private var timeRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Range")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Include Categories")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            VStack(spacing: 0) {
                CategoryToggle(title: "Symptoms", icon: "heart.text.square.fill", isOn: $includeSymptoms)
                Divider().padding(.horizontal)
                CategoryToggle(title: "Meals", icon: "fork.knife", isOn: $includeMeals)
                Divider().padding(.horizontal)
                CategoryToggle(title: "Walks & Exercise", icon: "figure.walk", isOn: $includeWalks)
                Divider().padding(.horizontal)
                CategoryToggle(title: "Digestion", icon: "leaf.fill", isOn: $includeDigestion)
                Divider().padding(.horizontal)
                CategoryToggle(title: "Mood", icon: "face.smiling.fill", isOn: $includeMood)
                Divider().padding(.horizontal)
                CategoryToggle(title: "Notes", icon: "note.text", isOn: $includeNotes)
            }
            .background(Color.petlyLightGreen)
            .cornerRadius(12)
        }
    }
    
    private var summaryPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary Preview")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            VStack(alignment: .leading, spacing: 8) {
                if let dog = appState.currentDog {
                    HStack {
                        Text("Pet:")
                            .font(.petlyBody(14))
                            .foregroundColor(.secondary)
                        Text(dog.name)
                            .font(.petlyBodyMedium(14))
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
                
                HStack {
                    Text("Period:")
                        .font(.petlyBody(14))
                        .foregroundColor(.secondary)
                    Text(selectedTimeRange.rawValue)
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.petlyDarkGreen)
                }
                
                HStack {
                    Text("Total Entries:")
                        .font(.petlyBody(14))
                        .foregroundColor(.secondary)
                    Text("\(logsToExport.count)")
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.petlyDarkGreen)
                }
                
                if logsToExport.isEmpty {
                    Text("No health logs found for the selected period and categories.")
                        .font(.petlyBody(12))
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.petlyLightGreen)
            .cornerRadius(12)
        }
    }
    
    private var generateButton: some View {
        Button(action: generatePDF) {
            HStack {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
                Text(isGenerating ? "Generating..." : "Generate & Share PDF")
            }
            .font(.petlyBodyMedium(16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(logsToExport.isEmpty ? Color.gray : Color.petlyDarkGreen)
            .cornerRadius(12)
        }
        .disabled(logsToExport.isEmpty || isGenerating)
    }
    
    private func generatePDF() {
        isGenerating = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let pdfData = createPDFData()
            
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("VetSummary_\(appState.currentDog?.name ?? "Pet")_\(Date().formatted(date: .numeric, time: .omitted)).pdf")
            
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
                    print("Error saving PDF: \(error)")
                }
            }
        }
    }
    
    private func createPDFData() -> Data {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - (margin * 2)
        
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        
        let data = pdfRenderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = margin
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.systemGreen
            ]
            
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.darkGray
            ]
            
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.darkGray
            ]
            
            let smallAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ]
            
            let title = "Pet Health Summary"
            title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 35
            
            let subtitle = "Generated by Petly on \(Date().formatted(date: .long, time: .shortened))"
            subtitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: smallAttributes)
            yPosition += 30
            
            if let dog = appState.currentDog {
                let petInfo = "Pet: \(dog.name) | Breed: \(dog.breed) | Period: \(selectedTimeRange.rawValue)"
                petInfo.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: bodyAttributes)
                yPosition += 25
            }
            
            let dividerPath = UIBezierPath()
            dividerPath.move(to: CGPoint(x: margin, y: yPosition))
            dividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
            UIColor.lightGray.setStroke()
            dividerPath.stroke()
            yPosition += 20
            
            let logsByType = Dictionary(grouping: logsToExport) { $0.logType }
            
            for (logType, logs) in logsByType.sorted(by: { $0.key < $1.key }) {
                if yPosition > pageHeight - 100 {
                    context.beginPage()
                    yPosition = margin
                }
                
                "\(logType) (\(logs.count) entries)".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttributes)
                yPosition += 25
                
                for log in logs.prefix(20) {
                    if yPosition > pageHeight - 60 {
                        context.beginPage()
                        yPosition = margin
                    }
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .short
                    
                    var logText = "• \(dateFormatter.string(from: log.timestamp))"
                    
                    if let notes = log.notes, !notes.isEmpty {
                        logText += ": \(notes)"
                    }
                    
                    if logType == "Symptom", let symptomType = log.symptomType {
                        logText += " - \(symptomType)"
                        if let severity = log.severityLevel {
                            logText += " (Severity: \(severity)/5)"
                        }
                    }
                    
                    if logType == "Walk", let duration = log.duration {
                        logText += " - \(duration) minutes"
                    }
                    
                    if logType == "Meals", let mealType = log.mealType {
                        logText += " - \(mealType)"
                    }
                    
                    if logType == "Mood", let moodLevel = log.moodLevel {
                        logText += " - Mood: \(moodLevel)/5"
                    }
                    
                    if logType == "Digestion", let quality = log.digestionQuality {
                        logText += " - \(quality)"
                    }
                    
                    let truncatedText = String(logText.prefix(100))
                    let textRect = CGRect(x: margin + 10, y: yPosition, width: contentWidth - 10, height: 40)
                    truncatedText.draw(in: textRect, withAttributes: bodyAttributes)
                    yPosition += 20
                }
                
                if logs.count > 20 {
                    "... and \(logs.count - 20) more entries".draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: smallAttributes)
                    yPosition += 15
                }
                
                yPosition += 15
            }
            
            if yPosition > pageHeight - 80 {
                context.beginPage()
                yPosition = margin
            }
            
            yPosition = pageHeight - 60
            let disclaimer = "This summary is for informational purposes only and does not constitute medical advice. Please consult with your veterinarian for professional guidance."
            let disclaimerRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 40)
            disclaimer.draw(in: disclaimerRect, withAttributes: smallAttributes)
        }
        
        return data
    }
}

struct CategoryToggle: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.petlyDarkGreen)
                    .frame(width: 24)
                
                Text(title)
                    .font(.petlyBody(14))
                    .foregroundColor(.petlyDarkGreen)
            }
        }
        .tint(.petlyDarkGreen)
        .padding()
    }
}

struct VetSummaryShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationView {
        VetSummaryExportView()
            .environmentObject(AppState())
    }
}
