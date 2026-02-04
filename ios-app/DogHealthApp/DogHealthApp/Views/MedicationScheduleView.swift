import SwiftUI
import UserNotifications

struct Medication: Identifiable, Codable {
    let id: String
    var name: String
    var dosage: String
    var frequency: MedicationFrequency
    var times: [Date]
    var startDate: Date
    var endDate: Date?
    var notes: String?
    var refillReminder: Bool
    var refillDate: Date?
    var isActive: Bool
    var createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        dosage: String,
        frequency: MedicationFrequency = .daily,
        times: [Date] = [],
        startDate: Date = Date(),
        endDate: Date? = nil,
        notes: String? = nil,
        refillReminder: Bool = false,
        refillDate: Date? = nil,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.times = times
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.refillReminder = refillReminder
        self.refillDate = refillDate
        self.isActive = isActive
        self.createdAt = createdAt
    }
    
    enum MedicationFrequency: String, Codable, CaseIterable {
        case daily = "Daily"
        case twiceDaily = "Twice Daily"
        case everyOtherDay = "Every Other Day"
        case weekly = "Weekly"
        case asNeeded = "As Needed"
    }
}

struct MedicationLog: Identifiable, Codable {
    let id: String
    let medicationId: String
    let timestamp: Date
    var skipped: Bool
    var notes: String?
    
    init(
        id: String = UUID().uuidString,
        medicationId: String,
        timestamp: Date = Date(),
        skipped: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.medicationId = medicationId
        self.timestamp = timestamp
        self.skipped = skipped
        self.notes = notes
    }
}

class MedicationManager: ObservableObject {
    static let shared = MedicationManager()
    
    @Published var medications: [Medication] = []
    @Published var medicationLogs: [MedicationLog] = []
    
    private let userDefaults = UserDefaults.standard
    private let medicationsKey = "medications"
    private let logsKey = "medicationLogs"
    
    private init() {
        loadData()
    }
    
    func addMedication(_ medication: Medication) {
        medications.append(medication)
        saveMedications()
        scheduleMedicationReminders(for: medication)
    }
    
    func updateMedication(_ medication: Medication) {
        if let index = medications.firstIndex(where: { $0.id == medication.id }) {
            medications[index] = medication
            saveMedications()
            cancelMedicationReminders(for: medication.id)
            if medication.isActive {
                scheduleMedicationReminders(for: medication)
            }
        }
    }
    
    func deleteMedication(_ medication: Medication) {
        medications.removeAll { $0.id == medication.id }
        medicationLogs.removeAll { $0.medicationId == medication.id }
        saveMedications()
        saveLogs()
        cancelMedicationReminders(for: medication.id)
    }
    
    func logMedication(_ medication: Medication, skipped: Bool = false, notes: String? = nil) {
        let log = MedicationLog(
            medicationId: medication.id,
            timestamp: Date(),
            skipped: skipped,
            notes: notes
        )
        medicationLogs.append(log)
        saveLogs()
    }
    
    func getTodayLogs(for medication: Medication) -> [MedicationLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        return medicationLogs.filter {
            $0.medicationId == medication.id &&
            $0.timestamp >= today &&
            $0.timestamp < tomorrow
        }
    }
    
    func getAdherenceRate(for medication: Medication, days: Int = 7) -> Double {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else { return 0 }
        
        let logs = medicationLogs.filter {
            $0.medicationId == medication.id &&
            $0.timestamp >= startDate &&
            !$0.skipped
        }
        
        let expectedDoses = calculateExpectedDoses(for: medication, days: days)
        guard expectedDoses > 0 else { return 0 }
        
        return min(Double(logs.count) / Double(expectedDoses), 1.0)
    }
    
    private func calculateExpectedDoses(for medication: Medication, days: Int) -> Int {
        switch medication.frequency {
        case .daily:
            return days * medication.times.count
        case .twiceDaily:
            return days * 2
        case .everyOtherDay:
            return (days / 2) * medication.times.count
        case .weekly:
            return (days / 7) * medication.times.count
        case .asNeeded:
            return 0
        }
    }
    
    private func saveMedications() {
        if let encoded = try? JSONEncoder().encode(medications) {
            userDefaults.set(encoded, forKey: medicationsKey)
        }
    }
    
    private func saveLogs() {
        if let encoded = try? JSONEncoder().encode(medicationLogs) {
            userDefaults.set(encoded, forKey: logsKey)
        }
    }
    
    private func loadData() {
        if let data = userDefaults.data(forKey: medicationsKey),
           let decoded = try? JSONDecoder().decode([Medication].self, from: data) {
            medications = decoded
        }
        
        if let data = userDefaults.data(forKey: logsKey),
           let decoded = try? JSONDecoder().decode([MedicationLog].self, from: data) {
            medicationLogs = decoded
        }
    }
    
    private func scheduleMedicationReminders(for medication: Medication) {
        guard medication.isActive else { return }
        
        let center = UNUserNotificationCenter.current()
        
        for (index, time) in medication.times.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Medication Reminder"
            content.body = "Time to give \(medication.name) (\(medication.dosage))"
            content.sound = .default
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: time)
            
            var trigger: UNNotificationTrigger
            
            switch medication.frequency {
            case .daily, .twiceDaily:
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            case .everyOtherDay:
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            case .weekly:
                var weeklyComponents = components
                weeklyComponents.weekday = calendar.component(.weekday, from: medication.startDate)
                trigger = UNCalendarNotificationTrigger(dateMatching: weeklyComponents, repeats: true)
            case .asNeeded:
                return
            }
            
            let request = UNNotificationRequest(
                identifier: "medication-\(medication.id)-\(index)",
                content: content,
                trigger: trigger
            )
            
            center.add(request)
        }
        
        if medication.refillReminder, let refillDate = medication.refillDate {
            let refillContent = UNMutableNotificationContent()
            refillContent.title = "Refill Reminder"
            refillContent.body = "Time to refill \(medication.name)"
            refillContent.sound = .default
            
            let refillComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: refillDate)
            let refillTrigger = UNCalendarNotificationTrigger(dateMatching: refillComponents, repeats: false)
            
            let refillRequest = UNNotificationRequest(
                identifier: "medication-refill-\(medication.id)",
                content: refillContent,
                trigger: refillTrigger
            )
            
            center.add(refillRequest)
        }
    }
    
    private func cancelMedicationReminders(for medicationId: String) {
        let center = UNUserNotificationCenter.current()
        let identifiers = (0..<10).map { "medication-\(medicationId)-\($0)" } + ["medication-refill-\(medicationId)"]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

struct MedicationScheduleView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @StateObject private var medicationManager = MedicationManager.shared
    
    @State private var showAddMedication = false
    @State private var selectedMedication: Medication?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        
                        if medicationManager.medications.isEmpty {
                            emptyStateView
                        } else {
                            todaySection
                            allMedicationsSection
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Medications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddMedication = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
            .sheet(isPresented: $showAddMedication) {
                AddMedicationView(medicationManager: medicationManager)
            }
            .sheet(item: $selectedMedication) { medication in
                MedicationDetailView(medication: medication, medicationManager: medicationManager)
            }
        }
        .buttonStyle(.plain)
        .preferredColorScheme(.light)
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "pills.fill")
                .font(.system(size: 50))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Medication Schedule")
                .font(.petlyTitle(24))
                .foregroundColor(.petlyDarkGreen)
            
            if let dogName = appState.currentDog?.name {
                Text("Track \(dogName)'s medications and reminders")
                    .font(.petlyBody(14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "pills.circle")
                .font(.system(size: 60))
                .foregroundColor(.petlyFormIcon)
            
            Text("No Medications")
                .font(.petlyBodyMedium(18))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Add your pet's medications to track doses and receive reminders.")
                .font(.petlyBody(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showAddMedication = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Medication")
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
    
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Schedule")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            let activeMeds = medicationManager.medications.filter { $0.isActive }
            
            if activeMeds.isEmpty {
                Text("No active medications scheduled for today")
                    .font(.petlyBody(14))
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(12)
            } else {
                ForEach(activeMeds) { medication in
                    TodayMedicationCard(
                        medication: medication,
                        medicationManager: medicationManager
                    )
                }
            }
        }
    }
    
    private var allMedicationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Medications")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            ForEach(medicationManager.medications) { medication in
                MedicationCard(medication: medication) {
                    selectedMedication = medication
                }
            }
        }
    }
}

struct TodayMedicationCard: View {
    let medication: Medication
    @ObservedObject var medicationManager: MedicationManager
    
    private var todayLogs: [MedicationLog] {
        medicationManager.getTodayLogs(for: medication)
    }
    
    private var isDoseGiven: Bool {
        !todayLogs.filter { !$0.skipped }.isEmpty
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(isDoseGiven ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: isDoseGiven ? "checkmark" : "pills.fill")
                        .font(.system(size: 22))
                        .foregroundColor(isDoseGiven ? .green : .orange)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.petlyBodyMedium(16))
                    .foregroundColor(.petlyDarkGreen)
                
                Text(medication.dosage)
                    .font(.petlyBody(14))
                    .foregroundColor(.secondary)
                
                if !medication.times.isEmpty {
                    Text(formatTimes(medication.times))
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                }
            }
            
            Spacer()
            
            if !isDoseGiven {
                VStack(spacing: 8) {
                    Button(action: { medicationManager.logMedication(medication) }) {
                        Text("Given")
                            .font(.petlyBodyMedium(14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.petlyDarkGreen)
                            .cornerRadius(20)
                    }
                    
                    Button(action: { medicationManager.logMedication(medication, skipped: true) }) {
                        Text("Skip")
                            .font(.petlyBody(12))
                            .foregroundColor(.petlyFormIcon)
                    }
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatTimes(_ times: [Date]) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return times.map { formatter.string(from: $0) }.joined(separator: ", ")
    }
}

struct MedicationCard: View {
    let medication: Medication
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Circle()
                    .fill(medication.isActive ? Color.petlyDarkGreen.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "pills.fill")
                            .font(.system(size: 18))
                            .foregroundColor(medication.isActive ? .petlyDarkGreen : .gray)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(medication.name)
                            .font(.petlyBodyMedium(16))
                            .foregroundColor(.petlyDarkGreen)
                        
                        if !medication.isActive {
                            Text("Inactive")
                                .font(.petlyBody(10))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text("\(medication.dosage) - \(medication.frequency.rawValue)")
                        .font(.petlyBody(14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.petlyFormIcon)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

struct AddMedicationView: View {
    @ObservedObject var medicationManager: MedicationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency: Medication.MedicationFrequency = .daily
    @State private var times: [Date] = [Date()]
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()
    @State private var notes = ""
    @State private var refillReminder = false
    @State private var refillDate = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Medication Name")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextField("e.g., Heartgard, Apoquel", text: $name)
                                .font(.petlyBody(16))
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Dosage")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextField("e.g., 1 tablet, 5ml", text: $dosage)
                                .font(.petlyBody(16))
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Frequency")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            Picker("Frequency", selection: $frequency) {
                                ForEach(Medication.MedicationFrequency.allCases, id: \.self) { freq in
                                    Text(freq.rawValue).tag(freq)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        if frequency != .asNeeded {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Reminder Times")
                                        .font(.petlyBodyMedium(14))
                                        .foregroundColor(.petlyDarkGreen)
                                    
                                    Spacer()
                                    
                                    Button(action: { times.append(Date()) }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.petlyDarkGreen)
                                    }
                                }
                                
                                ForEach(times.indices, id: \.self) { index in
                                    HStack {
                                        DatePicker("", selection: $times[index], displayedComponents: .hourAndMinute)
                                            .labelsHidden()
                                        
                                        if times.count > 1 {
                                            Button(action: { times.remove(at: index) }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color.petlyLightGreen)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Start Date")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        Toggle(isOn: $hasEndDate) {
                            Text("Has End Date")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                        }
                        .tint(.petlyDarkGreen)
                        
                        if hasEndDate {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("End Date")
                                    .font(.petlyBodyMedium(14))
                                    .foregroundColor(.petlyDarkGreen)
                                
                                DatePicker("", selection: $endDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .padding()
                                    .background(Color.petlyLightGreen)
                                    .cornerRadius(12)
                            }
                        }
                        
                        Toggle(isOn: $refillReminder) {
                            Text("Refill Reminder")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                        }
                        .tint(.petlyDarkGreen)
                        
                        if refillReminder {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Refill Date")
                                    .font(.petlyBodyMedium(14))
                                    .foregroundColor(.petlyDarkGreen)
                                
                                DatePicker("", selection: $refillDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .padding()
                                    .background(Color.petlyLightGreen)
                                    .cornerRadius(12)
                            }
                        }
                        
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
                        
                        Button(action: saveMedication) {
                            Text("Save Medication")
                                .font(.petlyBodyMedium(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(canSave ? Color.petlyDarkGreen : Color.gray)
                                .cornerRadius(25)
                        }
                        .disabled(!canSave)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Medication")
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
    
    private var canSave: Bool {
        !name.isEmpty && !dosage.isEmpty
    }
    
    private func saveMedication() {
        let medication = Medication(
            name: name,
            dosage: dosage,
            frequency: frequency,
            times: times,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            notes: notes.isEmpty ? nil : notes,
            refillReminder: refillReminder,
            refillDate: refillReminder ? refillDate : nil
        )
        
        medicationManager.addMedication(medication)
        dismiss()
    }
}

struct MedicationDetailView: View {
    let medication: Medication
    @ObservedObject var medicationManager: MedicationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showDeleteConfirm = false
    
    private var adherenceRate: Double {
        medicationManager.getAdherenceRate(for: medication)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
                            Circle()
                                .fill(Color.petlyDarkGreen.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "pills.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.petlyDarkGreen)
                                )
                            
                            Text(medication.name)
                                .font(.petlyTitle(24))
                                .foregroundColor(.petlyDarkGreen)
                            
                            Text(medication.dosage)
                                .font(.petlyBody(16))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical)
                        
                        HStack(spacing: 16) {
                            VStack(spacing: 4) {
                                Text("\(Int(adherenceRate * 100))%")
                                    .font(.petlyTitle(24))
                                    .foregroundColor(.petlyDarkGreen)
                                Text("Adherence")
                                    .font(.petlyBody(12))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            
                            VStack(spacing: 4) {
                                Text(medication.frequency.rawValue)
                                    .font(.petlyBodyMedium(16))
                                    .foregroundColor(.petlyDarkGreen)
                                Text("Frequency")
                                    .font(.petlyBody(12))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Details")
                                .font(.petlyBodyMedium(16))
                                .foregroundColor(.petlyDarkGreen)
                            
                            DetailRow(label: "Status", value: medication.isActive ? "Active" : "Inactive")
                            DetailRow(label: "Start Date", value: medication.startDate.formatted(date: .abbreviated, time: .omitted))
                            
                            if let endDate = medication.endDate {
                                DetailRow(label: "End Date", value: endDate.formatted(date: .abbreviated, time: .omitted))
                            }
                            
                            if !medication.times.isEmpty {
                                DetailRow(label: "Times", value: formatTimes(medication.times))
                            }
                            
                            if let notes = medication.notes {
                                DetailRow(label: "Notes", value: notes)
                            }
                            
                            if medication.refillReminder, let refillDate = medication.refillDate {
                                DetailRow(label: "Refill Date", value: refillDate.formatted(date: .abbreviated, time: .omitted))
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        
                        Spacer(minLength: 40)
                        
                        Button(action: toggleActive) {
                            Text(medication.isActive ? "Mark as Inactive" : "Mark as Active")
                                .font(.petlyBodyMedium(16))
                                .foregroundColor(.petlyDarkGreen)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(25)
                        }
                        
                        Button(action: { showDeleteConfirm = true }) {
                            Text("Delete Medication")
                                .font(.petlyBodyMedium(16))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(25)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Medication Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
            .confirmationDialog("Delete Medication", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    medicationManager.deleteMedication(medication)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this medication? This action cannot be undone.")
            }
        }
        .buttonStyle(.plain)
        .preferredColorScheme(.light)
    }
    
    private func toggleActive() {
        var updated = medication
        updated.isActive.toggle()
        medicationManager.updateMedication(updated)
        dismiss()
    }
    
    private func formatTimes(_ times: [Date]) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return times.map { formatter.string(from: $0) }.joined(separator: ", ")
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.petlyBody(14))
                .foregroundColor(.petlyFormIcon)
            
            Spacer()
            
            Text(value)
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MedicationScheduleView()
        .environmentObject(AppState())
}
