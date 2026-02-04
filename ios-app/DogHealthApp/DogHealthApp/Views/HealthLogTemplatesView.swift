import SwiftUI
import SwiftData

struct LogTemplate: Identifiable, Codable {
    let id: String
    var name: String
    var logType: String
    var mealType: String?
    var amount: String?
    var duration: String?
    var treatName: String?
    var supplementName: String?
    var dosage: String?
    var notes: String?
    var createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        logType: String,
        mealType: String? = nil,
        amount: String? = nil,
        duration: String? = nil,
        treatName: String? = nil,
        supplementName: String? = nil,
        dosage: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.logType = logType
        self.mealType = mealType
        self.amount = amount
        self.duration = duration
        self.treatName = treatName
        self.supplementName = supplementName
        self.dosage = dosage
        self.notes = notes
        self.createdAt = createdAt
    }
}

class LogTemplateManager: ObservableObject {
    static let shared = LogTemplateManager()
    
    @Published var templates: [LogTemplate] = []
    
    private let userDefaults = UserDefaults.standard
    private let templatesKey = "healthLogTemplates"
    
    private init() {
        loadTemplates()
    }
    
    func addTemplate(_ template: LogTemplate) {
        templates.append(template)
        saveTemplates()
    }
    
    func deleteTemplate(_ template: LogTemplate) {
        templates.removeAll { $0.id == template.id }
        saveTemplates()
    }
    
    func updateTemplate(_ template: LogTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
            saveTemplates()
        }
    }
    
    private func saveTemplates() {
        if let encoded = try? JSONEncoder().encode(templates) {
            userDefaults.set(encoded, forKey: templatesKey)
        }
    }
    
    private func loadTemplates() {
        if let data = userDefaults.data(forKey: templatesKey),
           let decoded = try? JSONDecoder().decode([LogTemplate].self, from: data) {
            templates = decoded
        }
    }
}

struct HealthLogTemplatesView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var templateManager = LogTemplateManager.shared
    
    @State private var showCreateTemplate = false
    @State private var selectedTemplate: LogTemplate?
    @State private var showLogCreated = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        
                        if templateManager.templates.isEmpty {
                            emptyStateView
                        } else {
                            templatesListSection
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
                
                if showLogCreated {
                    logCreatedToast
                }
            }
            .navigationTitle("Quick Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateTemplate = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
            .sheet(isPresented: $showCreateTemplate) {
                CreateTemplateView(templateManager: templateManager)
            }
        }
        .buttonStyle(.plain)
        .preferredColorScheme(.light)
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.on.doc.fill")
                .font(.system(size: 50))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Quick Templates")
                .font(.petlyTitle(24))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Save frequently used log entries as templates for one-tap logging")
                .font(.petlyBody(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.petlyFormIcon)
            
            Text("No Templates Yet")
                .font(.petlyBodyMedium(18))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Create templates for meals, walks, medications, and more to log them with a single tap.")
                .font(.petlyBody(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showCreateTemplate = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create First Template")
                }
                .font(.petlyBodyMedium(16))
                .foregroundColor(.white)
                .padding()
                .background(Color.petlyDarkGreen)
                .cornerRadius(25)
            }
            .padding(.top, 8)
        }
        .padding(40)
        .background(Color.petlyLightGreen)
        .cornerRadius(16)
    }
    
    private var templatesListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Templates")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            LazyVStack(spacing: 12) {
                ForEach(templateManager.templates) { template in
                    TemplateCard(
                        template: template,
                        onUse: { useTemplate(template) },
                        onDelete: { templateManager.deleteTemplate(template) }
                    )
                }
            }
        }
    }
    
    private var logCreatedToast: some View {
        VStack {
            Spacer()
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                Text("Log created from template!")
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.petlyDarkGreen)
            .cornerRadius(25)
            .shadow(radius: 10)
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(), value: showLogCreated)
    }
    
    private func useTemplate(_ template: LogTemplate) {
        guard let dogId = appState.currentDog?.id else { return }
        
        let entry = HealthLogEntry(
            dogId: dogId,
            logType: template.logType,
            timestamp: Date(),
            notes: template.notes ?? "",
            mealType: template.mealType,
            amount: template.amount,
            duration: template.duration,
            treatName: template.treatName,
            supplementName: template.supplementName,
            dosage: template.dosage
        )
        
        modelContext.insert(entry)
        
        Task {
            await HealthLogSyncService.shared.syncSingleLog(entry)
        }
        
        withAnimation {
            showLogCreated = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showLogCreated = false
            }
        }
    }
}

struct TemplateCard: View {
    let template: LogTemplate
    let onUse: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirm = false
    
    private var logTypeIcon: String {
        switch template.logType {
        case "Meals": return "fork.knife"
        case "Walk": return "figure.walk"
        case "Treat": return "gift.fill"
        case "Water": return "drop.fill"
        case "Supplements": return "pills.fill"
        case "Playtime": return "sportscourt.fill"
        default: return "list.bullet"
        }
    }
    
    private var logTypeColor: Color {
        switch template.logType {
        case "Meals": return .orange
        case "Walk": return .green
        case "Treat": return .pink
        case "Water": return .blue
        case "Supplements": return .purple
        case "Playtime": return .yellow
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(logTypeColor.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: logTypeIcon)
                        .font(.system(size: 22))
                        .foregroundColor(logTypeColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.petlyBodyMedium(16))
                    .foregroundColor(.petlyDarkGreen)
                
                Text(template.logType)
                    .font(.petlyBody(12))
                    .foregroundColor(.secondary)
                
                if let details = templateDetails {
                    Text(details)
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Button(action: onUse) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.petlyDarkGreen)
                }
                
                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red.opacity(0.7))
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .confirmationDialog("Delete Template", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this template?")
        }
    }
    
    private var templateDetails: String? {
        var details: [String] = []
        
        if let mealType = template.mealType {
            details.append(mealType)
        }
        if let amount = template.amount {
            details.append(amount)
        }
        if let duration = template.duration {
            details.append("\(duration) min")
        }
        if let supplement = template.supplementName {
            details.append(supplement)
        }
        
        return details.isEmpty ? nil : details.joined(separator: " - ")
    }
}

struct CreateTemplateView: View {
    @ObservedObject var templateManager: LogTemplateManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var selectedLogType = "Meals"
    @State private var mealType = ""
    @State private var amount = ""
    @State private var duration = ""
    @State private var treatName = ""
    @State private var supplementName = ""
    @State private var dosage = ""
    @State private var notes = ""
    
    let logTypes = ["Meals", "Walk", "Treat", "Water", "Supplements", "Playtime", "Grooming"]
    let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Template Name")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextField("e.g., Morning Walk, Daily Vitamins", text: $name)
                                .font(.petlyBody(16))
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Log Type")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            Picker("Log Type", selection: $selectedLogType) {
                                ForEach(logTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        logTypeSpecificFields
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (optional)")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextField("Add any notes", text: $notes)
                                .font(.petlyBody(16))
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        Spacer(minLength: 40)
                        
                        Button(action: saveTemplate) {
                            Text("Save Template")
                                .font(.petlyBodyMedium(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(name.isEmpty ? Color.gray : Color.petlyDarkGreen)
                                .cornerRadius(25)
                        }
                        .disabled(name.isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle("Create Template")
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
    
    @ViewBuilder
    private var logTypeSpecificFields: some View {
        switch selectedLogType {
        case "Meals":
            VStack(alignment: .leading, spacing: 8) {
                Text("Meal Type")
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.petlyDarkGreen)
                
                Picker("Meal Type", selection: $mealType) {
                    Text("Select").tag("")
                    ForEach(mealTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .background(Color.petlyLightGreen)
                .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount (optional)")
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.petlyDarkGreen)
                
                TextField("e.g., 1 cup, 200g", text: $amount)
                    .font(.petlyBody(16))
                    .padding()
                    .background(Color.petlyLightGreen)
                    .cornerRadius(12)
            }
            
        case "Walk", "Playtime":
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration (minutes)")
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.petlyDarkGreen)
                
                TextField("e.g., 30", text: $duration)
                    .keyboardType(.numberPad)
                    .font(.petlyBody(16))
                    .padding()
                    .background(Color.petlyLightGreen)
                    .cornerRadius(12)
            }
            
        case "Treat":
            VStack(alignment: .leading, spacing: 8) {
                Text("Treat Name")
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.petlyDarkGreen)
                
                TextField("e.g., Dental Chew", text: $treatName)
                    .font(.petlyBody(16))
                    .padding()
                    .background(Color.petlyLightGreen)
                    .cornerRadius(12)
            }
            
        case "Supplements":
            VStack(alignment: .leading, spacing: 8) {
                Text("Supplement Name")
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.petlyDarkGreen)
                
                TextField("e.g., Fish Oil", text: $supplementName)
                    .font(.petlyBody(16))
                    .padding()
                    .background(Color.petlyLightGreen)
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Dosage")
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.petlyDarkGreen)
                
                TextField("e.g., 1 capsule", text: $dosage)
                    .font(.petlyBody(16))
                    .padding()
                    .background(Color.petlyLightGreen)
                    .cornerRadius(12)
            }
            
        case "Water":
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount")
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.petlyDarkGreen)
                
                TextField("e.g., Full bowl", text: $amount)
                    .font(.petlyBody(16))
                    .padding()
                    .background(Color.petlyLightGreen)
                    .cornerRadius(12)
            }
            
        default:
            EmptyView()
        }
    }
    
    private func saveTemplate() {
        let template = LogTemplate(
            name: name,
            logType: selectedLogType,
            mealType: mealType.isEmpty ? nil : mealType,
            amount: amount.isEmpty ? nil : amount,
            duration: duration.isEmpty ? nil : duration,
            treatName: treatName.isEmpty ? nil : treatName,
            supplementName: supplementName.isEmpty ? nil : supplementName,
            dosage: dosage.isEmpty ? nil : dosage,
            notes: notes.isEmpty ? nil : notes
        )
        
        templateManager.addTemplate(template)
        dismiss()
    }
}

#Preview {
    HealthLogTemplatesView()
        .environmentObject(AppState())
}
