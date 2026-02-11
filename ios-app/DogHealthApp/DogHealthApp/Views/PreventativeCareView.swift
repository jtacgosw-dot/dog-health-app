import SwiftUI
import SwiftData

struct PreventativeCareView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @Query(sort: \PetReminder.nextDueDate) private var reminders: [PetReminder]
    
    @State private var showingAddReminder = false
    @State private var selectedReminderType: ReminderType = .vaccination
    @State private var scrollProxy: ScrollViewProxy?
    
    private var dogId: String {
        appState.currentDog?.id ?? ""
    }
    
    private var dogName: String {
        appState.currentDog?.name ?? "your pet"
    }
    
    private var dogReminders: [PetReminder] {
        reminders.filter { $0.dogId == dogId && $0.isEnabled }
    }
    
    private var dueReminders: [PetReminder] {
        dogReminders.filter { $0.isDue }
    }
    
    private var upcomingReminders: [PetReminder] {
        dogReminders.filter { !$0.isDue }.sorted { $0.nextDueDate < $1.nextDueDate }
    }
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if !dueReminders.isEmpty {
                        dueNowSection
                            .id("dueNowSection")
                    }
                    
                    upcomingSection
                    
                    if dogReminders.isEmpty {
                        emptyStateSection
                    }
                    
                    careTypesSection
                }
                .padding()
            }
            .onAppear { scrollProxy = proxy }
            }
            .background(Color.petlyBackground)
            .navigationTitle("Preventative Care")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddReminder = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                AddPreventativeCareReminderView(selectedType: $selectedReminderType)
                    .buttonStyle(.plain)
            }
        }
        .buttonStyle(.plain)
        .preferredColorScheme(.light)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(dogName)'s Care Calendar")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Keep track of vaccinations, medications, and preventatives")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.petlyLightGreen)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.title2)
                        .foregroundColor(.petlyDarkGreen)
                }
            }
            
            if !dueReminders.isEmpty {
                Button {
                    withAnimation {
                        scrollProxy?.scrollTo("dueNowSection", anchor: .top)
                    }
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                        Text("\(dueReminders.count) item\(dueReminders.count == 1 ? "" : "s") due")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.petlyLightGreen.opacity(0.8), Color.petlyLightGreen.opacity(0.4)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    private var dueNowSection:some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Due Now")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Spacer()
            }
            
            ForEach(dueReminders, id: \.id) { reminder in
                PreventativeCareReminderCard(reminder: reminder, isDue: true) {
                    logAndCompleteReminder(reminder)
                }
            }
        }
    }
    
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming")
                    .font(.headline)
                
                Spacer()
            }
            
            if upcomingReminders.isEmpty && dueReminders.isEmpty {
                Text("No upcoming care scheduled")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(upcomingReminders.prefix(5), id: \.id) { reminder in
                    PreventativeCareReminderCard(reminder: reminder, isDue: false) {
                        logAndCompleteReminder(reminder)
                    }
                }
            }
        }
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No preventative care scheduled")
                .font(.headline)
            
            Text("Add vaccinations, medications, and other preventatives to keep \(dogName) healthy")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingAddReminder = true
            } label: {
                Text("Add First Reminder")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.petlyDarkGreen)
                    .cornerRadius(12)
            }
        }
        .padding(.vertical, 32)
    }
    
    private var careTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Add")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ReminderType.allCases, id: \.rawValue) { type in
                    CareTypeButton(type: type) {
                        selectedReminderType = type
                        showingAddReminder = true
                    }
                }
            }
        }
    }
    
    private func logAndCompleteReminder(_ reminder: PetReminder) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        let currentDogId = dogId
        let logType = healthLogType(for: reminder.type)
        let logEntry = HealthLogEntry(
            dogId: currentDogId,
            logType: logType,
            timestamp: Date(),
            notes: reminder.title,
            supplementName: [.medication, .fleaTick, .heartworm].contains(reminder.type) ? reminder.title : nil,
            appointmentType: [.vaccination, .vetAppointment].contains(reminder.type) ? reminder.title : nil,
            groomingType: reminder.type == .grooming ? reminder.title : nil
        )
        modelContext.insert(logEntry)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            reminder.markCompleted()
            try? modelContext.save()
        }
    }
    
    private func healthLogType(for type: ReminderType) -> String {
        switch type {
        case .vaccination, .vetAppointment: return "Upcoming Appointments"
        case .medication, .fleaTick, .heartworm: return "Supplements"
        case .grooming: return "Grooming"
        case .other: return "Notes"
        }
    }
}

struct PreventativeCareReminderCard: View {
    let reminder: PetReminder
    let isDue: Bool
    let onComplete: () -> Void
    @State private var isLogged = false
    
    private var daysText: String {
        let days = reminder.daysUntilDue
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        if days < 0 { return "\(abs(days)) days overdue" }
        return "In \(days) days"
    }
    
    private var typeColor: Color {
        switch reminder.type {
        case .vaccination: return .blue
        case .medication: return .purple
        case .fleaTick: return .orange
        case .heartworm: return .red
        case .grooming: return .teal
        case .vetAppointment: return .green
        case .other: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: reminder.type.icon)
                    .font(.title3)
                    .foregroundColor(typeColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text(reminder.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(daysText)
                        .font(.caption)
                        .foregroundColor(isDue ? .orange : .secondary)
                        .fontWeight(isDue ? .medium : .regular)
                }
            }
            
            Spacer()
            
            Button {
                onComplete()
                withAnimation { isLogged = true }
            } label: {
                Text(isLogged ? "Logged" : "Log")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isLogged ? Color.green : Color.petlyDarkGreen)
                    .cornerRadius(8)
            }
            .disabled(isLogged)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct CareTypeButton:View {
    let type: ReminderType
    let action: () -> Void
    
    private var typeColor: Color {
        switch type {
        case .vaccination: return .blue
        case .medication: return .purple
        case .fleaTick: return .orange
        case .heartworm: return .red
        case .grooming: return .teal
        case .vetAppointment: return .green
        case .other: return .gray
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.subheadline)
                    .foregroundColor(typeColor)
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(Color.petlyLightGreen)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddPreventativeCareReminderView:View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @Binding var selectedType: ReminderType
    
    @State private var title = ""
    @State private var frequency: ReminderFrequency = .monthly
    @State private var nextDueDate = Date()
    @State private var notes = ""
    
    private var dogId: String {
        appState.currentDog?.id ?? ""
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Reminder Details Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Reminder Details")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            VStack(spacing: 12) {
                                TextField("Title (e.g., Rabies Vaccine)", text: $title)
                                    .font(.petlyBody(14))
                                    .padding()
                                    .background(Color.petlyLightGreen)
                                    .cornerRadius(12)
                                
                                HStack {
                                    Text("Type")
                                        .font(.petlyBody(14))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Picker("Type", selection: $selectedType) {
                                        ForEach(ReminderType.allCases, id: \.rawValue) { type in
                                            HStack {
                                                Image(systemName: type.icon)
                                                Text(type.rawValue)
                                            }
                                            .tag(type)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                                
                                HStack {
                                    Text("Frequency")
                                        .font(.petlyBody(14))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Picker("Frequency", selection: $frequency) {
                                        ForEach(ReminderFrequency.allCases, id: \.rawValue) { freq in
                                            Text(freq.rawValue).tag(freq)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                                
                                HStack {
                                    Text("Next Due Date")
                                        .font(.petlyBody(14))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    DatePicker("", selection: $nextDueDate, displayedComponents: .date)
                                        .labelsHidden()
                                }
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                            }
                        }
                        
                        // Notes Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (Optional)")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextField("Add any additional notes...", text: $notes, axis: .vertical)
                                .font(.petlyBody(14))
                                .lineLimit(3...5)
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        // Add Button
                        Button {
                            saveReminder()
                        } label: {
                            Text("Add Reminder")
                                .font(.petlyBodyMedium(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(title.isEmpty ? Color.gray : Color.petlyDarkGreen)
                                .cornerRadius(12)
                        }
                        .disabled(title.isEmpty)
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Reminder")
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
        }
        .preferredColorScheme(.light)
    }
    
    private func saveReminder() {
        let reminder = PetReminder(
            dogId: dogId,
            title: title,
            reminderType: selectedType,
            frequency: frequency,
            nextDueDate: nextDueDate,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(reminder)
        dismiss()
    }
}

#Preview {
    PreventativeCareView()
        .environmentObject(AppState())
}
