import SwiftUI
import Charts

struct WeightEntry: Identifiable, Codable {
    let id: String
    let weight: Double
    let date: Date
    var note: String?
    
    init(id: String = UUID().uuidString, weight: Double, date: Date = Date(), note: String? = nil) {
        self.id = id
        self.weight = weight
        self.date = date
        self.note = note
    }
}

class WeightTrackingManager: ObservableObject {
    static let shared = WeightTrackingManager()
    
    @Published var weightEntries: [WeightEntry] = []
    
    private let userDefaults = UserDefaults.standard
    private var currentDogId: String?
    
    private var entriesKey: String {
        if let dogId = currentDogId {
            return "weightEntries_\(dogId)"
        }
        return "weightEntries"
    }
    
    private init() {
        loadEntries()
    }
    
    func switchDog(_ dogId: String) {
        guard dogId != currentDogId else { return }
        currentDogId = dogId
        loadEntries()
        migrateGlobalEntriesIfNeeded()
    }
    
    private func migrateGlobalEntriesIfNeeded() {
        guard currentDogId != nil else { return }
        let globalKey = "weightEntries"
        if let data = userDefaults.data(forKey: globalKey),
           let globalEntries = try? JSONDecoder().decode([WeightEntry].self, from: data),
           !globalEntries.isEmpty,
           weightEntries.isEmpty {
            weightEntries = globalEntries
            saveEntries()
            userDefaults.removeObject(forKey: globalKey)
        }
    }
    
    func addEntry(_ entry: WeightEntry) {
        weightEntries.append(entry)
        weightEntries.sort { $0.date < $1.date }
        saveEntries()
    }
    
    func deleteEntry(_ entry: WeightEntry) {
        weightEntries.removeAll { $0.id == entry.id }
        saveEntries()
    }
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(weightEntries) {
            userDefaults.set(encoded, forKey: entriesKey)
        }
    }
    
    private func loadEntries() {
        if let data = userDefaults.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([WeightEntry].self, from: data) {
            weightEntries = decoded
        } else {
            weightEntries = []
        }
    }
    
    var latestWeight: Double? {
        weightEntries.last?.weight
    }
    
    /// Returns the latest weight from entries, or falls back to dog's profile weight
    func currentWeight(dogProfileWeight: Double?) -> Double? {
        if let entryWeight = weightEntries.last?.weight {
            return entryWeight
        }
        return dogProfileWeight
    }
    
    var weightChange: Double? {
        guard weightEntries.count >= 2 else { return nil }
        let latest = weightEntries[weightEntries.count - 1].weight
        let previous = weightEntries[weightEntries.count - 2].weight
        return latest - previous
    }
    
    var averageWeight: Double? {
        guard !weightEntries.isEmpty else { return nil }
        let total = weightEntries.reduce(0) { $0 + $1.weight }
        return total / Double(weightEntries.count)
    }
    
    /// Returns average weight from entries, or falls back to dog's profile weight if no entries
    func averageOrProfileWeight(dogProfileWeight: Double?) -> Double? {
        if !weightEntries.isEmpty {
            return averageWeight
        }
        return dogProfileWeight
    }
}

struct WeightTrackingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var weightManager = WeightTrackingManager.shared
    @State private var showAddEntry = false
    
    private var dogId: String {
        appState.currentDog?.id ?? ""
    }
    @State private var newWeight = ""
    @State private var newNote = ""
    @State private var selectedDate = Date()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    statsSection
                    
                    if !weightManager.weightEntries.isEmpty {
                        chartSection
                    }
                    
                    historySection
                    
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddEntry = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.petlyDarkGreen)
                }
            }
        }
        .sheet(isPresented: $showAddEntry) {
            addEntrySheet
                .buttonStyle(.plain)
                .preferredColorScheme(.light)
        }
        .buttonStyle(.plain)
        .preferredColorScheme(.light)
        .onAppear {
            if !dogId.isEmpty {
                weightManager.switchDog(dogId)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "scalemass.fill")
                .font(.system(size: 50))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Weight Tracking")
                .font(.petlyTitle(24))
                .foregroundColor(.petlyDarkGreen)
            
            if let dogName = appState.currentDog?.name {
                Text("Track \(dogName)'s weight over time")
                    .font(.petlyBody(14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical)
    }
    
    private var statsSection: some View {
        let currentWeight = weightManager.currentWeight(dogProfileWeight: appState.currentDog?.weight)
        
        return HStack(spacing: 16) {
            StatCard(
                title: "Current",
                value: currentWeight.map { String(format: "%.1f", $0) } ?? "--",
                unit: "lbs",
                icon: "scalemass.fill",
                color: .petlyDarkGreen
            )
            
            StatCard(
                title: "Change",
                value: weightManager.weightChange.map { String(format: "%+.1f", $0) } ?? "--",
                unit: "lbs",
                icon: weightManager.weightChange ?? 0 >= 0 ? "arrow.up.right" : "arrow.down.right",
                color: (weightManager.weightChange ?? 0) >= 0 ? .green : .red
            )
            
            StatCard(
                title: "Average",
                value: weightManager.averageOrProfileWeight(dogProfileWeight: appState.currentDog?.weight).map { String(format: "%.1f", $0) } ?? "--",
                unit: "lbs",
                icon: "chart.line.uptrend.xyaxis",
                color: .blue
            )
        }
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weight History")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            Chart(weightManager.weightEntries) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weight)
                )
                .foregroundStyle(Color.petlyDarkGreen)
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weight)
                )
                .foregroundStyle(Color.petlyDarkGreen)
                
                AreaMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weight)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.petlyDarkGreen.opacity(0.3), Color.petlyDarkGreen.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .padding()
            .background(Color.petlyLightGreen)
            .cornerRadius(16)
        }
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Entries")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
            
            if weightManager.weightEntries.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No weight entries yet")
                        .font(.petlyBody(14))
                        .foregroundColor(.secondary)
                    
                    Text("Tap the + button to add your pet's first weight entry")
                        .font(.petlyBody(12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.petlyLightGreen)
                .cornerRadius(16)
            } else {
                VStack(spacing: 0) {
                    ForEach(weightManager.weightEntries.reversed()) { entry in
                        WeightEntryRow(entry: entry) {
                            weightManager.deleteEntry(entry)
                        }
                        
                        if entry.id != weightManager.weightEntries.first?.id {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
                .background(Color.petlyLightGreen)
                .cornerRadius(16)
            }
        }
    }
    
    private var addEntrySheet: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight (lbs)")
                            .font(.petlyBodyMedium(14))
                            .foregroundColor(.petlyDarkGreen)
                        
                        TextField("Enter weight", text: $newWeight)
                            .keyboardType(.decimalPad)
                            .font(.petlyBody(16))
                            .padding()
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.petlyBodyMedium(14))
                            .foregroundColor(.petlyDarkGreen)
                        
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(.petlyDarkGreen)
                            .padding()
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note (optional)")
                            .font(.petlyBodyMedium(14))
                            .foregroundColor(.petlyDarkGreen)
                        
                        TextField("Add a note", text: $newNote)
                            .font(.petlyBody(16))
                            .padding()
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    Button(action: saveEntry) {
                        Text("Save Entry")
                            .font(.petlyBodyMedium(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(newWeight.isEmpty ? Color.gray : Color.petlyDarkGreen)
                            .cornerRadius(25)
                    }
                    .disabled(newWeight.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Add Weight Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showAddEntry = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body)
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
        }
    }
    
    private func saveEntry() {
        guard let weight = Double(newWeight) else { return }
        
        let entry = WeightEntry(
            weight: weight,
            date: selectedDate,
            note: newNote.isEmpty ? nil : newNote
        )
        
        weightManager.addEntry(entry)
        
        if var dog = appState.currentDog {
            dog.weight = weight
            appState.saveDogLocally(dog)
        }
        
        newWeight = ""
        newNote = ""
        selectedDate = Date()
        showAddEntry = false
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.petlyTitle(20))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            
            Text(unit)
                .font(.petlyBody(10))
                .foregroundColor(.secondary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            Text(title)
                .font(.petlyBody(12))
                .foregroundColor(.secondary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(Color.petlyLightGreen)
        .cornerRadius(12)
    }
}

struct WeightEntryRow: View {
    let entry: WeightEntry
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "%.1f lbs", entry.weight))
                    .font(.petlyBodyMedium(16))
                    .foregroundColor(.primary)
                
                Text(entry.date, style: .date)
                    .font(.petlyBody(12))
                    .foregroundColor(.secondary)
                
                if let note = entry.note {
                    Text(note)
                        .font(.petlyBody(12))
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}

#Preview {
    NavigationView {
        WeightTrackingView()
            .environmentObject(AppState())
    }
}
