import SwiftUI
import SwiftData

enum LogType: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case meals = "Meals"
    case walk = "Walk"
    case treat = "Treat"
    case symptom = "Symptom"
    case water = "Water"
    case playtime = "Playtime"
    case digestion = "Digestion"
    case grooming = "Grooming"
    case mood = "Mood"
    case supplements = "Supplements"
    case appointments = "Upcoming Appointments"
    case notes = "Notes"
    
    var icon: String {
        switch self {
        case .meals: return "fork.knife"
        case .walk: return "figure.walk"
        case .treat: return "gift.fill"
        case .symptom: return "stethoscope"
        case .water: return "drop.fill"
        case .playtime: return "sportscourt.fill"
        case .digestion: return "leaf.arrow.triangle.circlepath"
        case .grooming: return "scissors"
        case .mood: return "face.smiling.fill"
        case .supplements: return "pills.fill"
        case .appointments: return "calendar"
        case .notes: return "note.text"
        }
    }
}

struct LogDetailView: View {
    let logType: LogType
    var initialMealType: Int?
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    
    @State private var selectedDate = Date()
    @State private var notes = ""
    @State private var amount = ""
    @State private var duration = ""
    @State private var selectedMood = 2
    @State private var selectedSeverity = 3 // Separate variable for symptom severity
    @State private var selectedMealType: Int
    @State private var selectedSymptom = 0
    @State private var selectedDigestion = 0
    @State private var isSaved = false
    @State private var photoData: Data? = nil
    @State private var showSuccessAnimation = false
    @State private var errorMessage: String?
    
    let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
    
    init(logType: LogType, initialMealType: Int? = nil) {
        self.logType = logType
        self.initialMealType = initialMealType
        _selectedMealType = State(initialValue: initialMealType ?? 0)
    }
    let symptoms = ["Vomiting", "Diarrhea", "Lethargy", "Loss of Appetite", "Coughing", "Sneezing", "Limping", "Scratching", "Other"]
    let digestionOptions = ["Normal", "Soft", "Hard", "Diarrhea", "Constipated"]
    let moodEmojis = ["😢", "😕", "😐", "🙂", "😄"]
    
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.petlyDarkGreen)
                            .padding(12)
                            .background(Color.petlyLightGreen)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text(logType.rawValue)
                        .font(.petlyTitle(24))
                        .foregroundColor(.petlyDarkGreen)
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 20) {
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.petlyBody(12))
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        dateSection
                        
                        logTypeSpecificContent
                        
                        PhotoAttachmentView(photoData: $photoData)
                        
                        notesSection
                        
                        saveButton
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
        }
        .overlay {
            SuccessCheckmarkView(isShowing: $showSuccessAnimation)
        }
        .onChange(of: showSuccessAnimation) { _, newValue in
            if !newValue && isSaved {
                dismiss()
            }
        }
        .buttonStyle(.plain)
        .preferredColorScheme(.light)
    }
    
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date & Time")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            DatePicker("", selection: $selectedDate)
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding()
                .background(Color.petlyLightGreen)
                .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var logTypeSpecificContent: some View {
        switch logType {
        case .meals:
            mealsContent
        case .walk:
            walkContent
        case .treat:
            treatContent
        case .symptom:
            symptomContent
        case .water:
            waterContent
        case .playtime:
            playtimeContent
        case .digestion:
            digestionContent
        case .grooming:
            groomingContent
        case .mood:
            moodContent
        case .supplements:
            supplementsContent
        case .appointments:
            appointmentsContent
        case .notes:
            EmptyView()
        }
    }
    
    private var mealsContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meal Type")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            Picker("Meal Type", selection: $selectedMealType) {
                ForEach(0..<mealTypes.count, id: \.self) { index in
                    Text(mealTypes[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
            
            Text("Amount")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
                .padding(.top, 12)
            
            TextField("e.g., 1 cup, 200g", text: $amount)
                .textFieldStyle(PetlyTextFieldStyle())
        }
    }
    
    private var walkContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration (minutes)")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            TextField("e.g., 30", text: $duration)
                .keyboardType(.numberPad)
                .textFieldStyle(PetlyTextFieldStyle())
            
            Text("Distance (optional)")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
                .padding(.top, 12)
            
            TextField("e.g., 1.5 miles", text: $amount)
                .textFieldStyle(PetlyTextFieldStyle())
        }
    }
    
    private var treatContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Treat Name")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            TextField("e.g., Dental chew", text: $amount)
                .textFieldStyle(PetlyTextFieldStyle())
        }
    }
    
    private var symptomContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Symptom Type")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<symptoms.count, id: \.self) { index in
                        Button(action: { selectedSymptom = index }) {
                            Text(symptoms[index])
                                .font(.petlyBody(14))
                                .foregroundColor(selectedSymptom == index ? .white : .petlyDarkGreen)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedSymptom == index ? Color.petlyDarkGreen : Color.petlyLightGreen)
                                .cornerRadius(20)
                        }
                    }
                }
            }
            
            Text("Severity")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
                .padding(.top, 12)
            
            HStack {
                ForEach(1...5, id: \.self) { level in
                    Button(action: { selectedSeverity = level }) {
                        Circle()
                            .fill(selectedSeverity >= level ? Color.petlyDarkGreen : Color.petlyLightGreen)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text("\(level)")
                                    .font(.petlyBodyMedium(16))
                                    .foregroundColor(selectedSeverity >= level ? .white : .petlyDarkGreen)
                            )
                    }
                }
            }
        }
    }
    
    private var waterContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            TextField("e.g., 2 cups, 500ml", text: $amount)
                .textFieldStyle(PetlyTextFieldStyle())
        }
    }
    
    private var playtimeContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration (minutes)")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            TextField("e.g., 20", text: $duration)
                .keyboardType(.numberPad)
                .textFieldStyle(PetlyTextFieldStyle())
            
            Text("Activity Type")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
                .padding(.top, 12)
            
            TextField("e.g., Fetch, Tug of war", text: $amount)
                .textFieldStyle(PetlyTextFieldStyle())
        }
    }
    
    private var digestionContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stool Quality")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<digestionOptions.count, id: \.self) { index in
                        Button(action: { selectedDigestion = index }) {
                            Text(digestionOptions[index])
                                .font(.petlyBody(14))
                                .foregroundColor(selectedDigestion == index ? .white : .petlyDarkGreen)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedDigestion == index ? Color.petlyDarkGreen : Color.petlyLightGreen)
                                .cornerRadius(20)
                        }
                    }
                }
            }
        }
    }
    
    private var groomingContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Grooming Type")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            TextField("e.g., Bath, Nail trim, Brushing", text: $amount)
                .textFieldStyle(PetlyTextFieldStyle())
        }
    }
    
    private var moodContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How is your pet feeling?")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            HStack(spacing: 12) {
                ForEach(0..<moodEmojis.count, id: \.self) { index in
                    Button(action: { selectedMood = index }) {
                        Text(moodEmojis[index])
                            .font(.system(size: 36))
                            .padding(8)
                            .background(selectedMood == index ? Color.petlyLightGreen : Color.clear)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedMood == index ? Color.petlyDarkGreen : Color.clear, lineWidth: 2)
                            )
                    }
                }
            }
        }
    }
    
    private var supplementsContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Supplement Name")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            TextField("e.g., Fish oil, Glucosamine", text: $amount)
                .textFieldStyle(PetlyTextFieldStyle())
            
            Text("Dosage")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
                .padding(.top, 12)
            
            TextField("e.g., 1 tablet, 5ml", text: $duration)
                .textFieldStyle(PetlyTextFieldStyle())
        }
    }
    
    private var appointmentsContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Appointment Type")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            TextField("e.g., Vet checkup, Grooming", text: $amount)
                .textFieldStyle(PetlyTextFieldStyle())
            
            Text("Location")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
                .padding(.top, 12)
            
            TextField("e.g., Happy Paws Vet Clinic", text: $duration)
                .textFieldStyle(PetlyTextFieldStyle())
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            TextEditor(text: $notes)
                .scrollContentBackground(.hidden)
                .foregroundColor(.petlyDarkGreen)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color.petlyLightGreen)
                .cornerRadius(12)
        }
    }
    
    private var saveButton: some View {
        Button(action: saveEntry) {
            Text("SAVE ENTRY")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.petlyDarkGreen)
                .cornerRadius(25)
        }
        .padding(.top, 20)
    }
    
    private func saveEntry() {
        guard let dogId = appState.currentDog?.id else {
            errorMessage = "Please select a pet before logging entries"
            return
        }
        
        errorMessage = nil
        
        let entry = HealthLogEntry(
            dogId: dogId,
            logType: logType.rawValue,
            timestamp: selectedDate,
            notes: notes,
            photoData: photoData,
            hasPhoto: photoData != nil
        )
        
        switch logType {
        case .meals:
            entry.mealType = mealTypes[selectedMealType]
            entry.amount = amount
        case .walk:
            entry.duration = duration
            entry.amount = amount
        case .treat:
            entry.treatName = amount
        case .symptom:
            entry.symptomType = symptoms[selectedSymptom]
            entry.severityLevel = selectedSeverity
        case .water:
            entry.waterAmount = amount
        case .playtime:
            entry.duration = duration
            entry.activityType = amount
        case .digestion:
            entry.digestionQuality = digestionOptions[selectedDigestion]
        case .grooming:
            entry.groomingType = amount
        case .mood:
            entry.moodLevel = selectedMood
        case .supplements:
            entry.supplementName = amount
            entry.dosage = duration
        case .appointments:
            entry.appointmentType = amount
            entry.location = duration
        case .notes:
            break
        }
        
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
            
            // Trigger sync to backend
            Task {
                await HealthLogSyncService.shared.syncSingleLog(entry)
            }
        } catch {
            print("Failed to save entry: \(error)")
        }
        
        isSaved = true
        showSuccessAnimation = true
    }
}

struct PetlyTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.petlyLightGreen)
            .cornerRadius(12)
            .font(.petlyBody(16))
    }
}

#Preview {
    LogDetailView(logType: .meals)
        .environmentObject(AppState())
}
