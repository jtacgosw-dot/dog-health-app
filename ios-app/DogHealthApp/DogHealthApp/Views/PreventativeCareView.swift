import SwiftUI
import SwiftData

struct PreventativeCareView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @Query(sort: \PetReminder.nextDueDate) private var reminders: [PetReminder]
    
    @State private var showingAddReminder = false
    @State private var selectedReminderType: ReminderType = .vaccination
    
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
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if !dueReminders.isEmpty {
                        dueNowSection
                    }
                    
                    upcomingSection
                    
                    if dogReminders.isEmpty {
                        emptyStateSection
                    }
                    
                    careTypesSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Preventative Care")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddReminder = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                AddReminderView(selectedType: $selectedReminderType)
            }
        }
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
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    Text("\(dueReminders.count) item\(dueReminders.count == 1 ? "" : "s") due")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    private var dueNowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Due Now")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Spacer()
            }
            
            ForEach(dueReminders, id: \.id) { reminder in
                ReminderCard(reminder: reminder, isDue: true) {
                    markReminderComplete(reminder)
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
                    ReminderCard(reminder: reminder, isDue: false) {
                        markReminderComplete(reminder)
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
    
    private func markReminderComplete(_ reminder: PetReminder) {
        reminder.markCompleted()
        try? modelContext.save()
    }
}

struct ReminderCard: View {
    let reminder: PetReminder
    let isDue: Bool
    let onComplete: () -> Void
    
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
            } label: {
                Text("Done")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.petlyDarkGreen)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDue ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

struct CareTypeButton: View {
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
            .background(typeColor.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddReminderView: View {
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
            Form {
                Section("Reminder Details") {
                    TextField("Title (e.g., Rabies Vaccine)", text: $title)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(ReminderType.allCases, id: \.rawValue) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(ReminderFrequency.allCases, id: \.rawValue) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    
                    DatePicker("Next Due Date", selection: $nextDueDate, displayedComponents: .date)
                }
                
                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
                
                Section {
                    Button {
                        saveReminder()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Add Reminder")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
            .navigationTitle("Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
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
