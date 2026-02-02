import SwiftUI
import SwiftData

struct PetRemindersView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Query private var allReminders: [PetReminder]
    @State private var showingAddReminder = false
    
    private var reminders: [PetReminder] {
        guard let dogId = appState.currentDog?.id else { return [] }
        return allReminders.filter { $0.dogId == dogId }.sorted { $0.nextDueDate < $1.nextDueDate }
    }
    
    private var upcomingReminders: [PetReminder] {
        reminders.filter { !$0.isDue && $0.isEnabled }
    }
    
    private var dueReminders: [PetReminder] {
        reminders.filter { $0.isDue && $0.isEnabled }
    }
    
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if dueReminders.isEmpty && upcomingReminders.isEmpty {
                        emptyStateView
                    } else {
                        if !dueReminders.isEmpty {
                            dueSection
                        }
                        
                        if !upcomingReminders.isEmpty {
                            upcomingSection
                        }
                    }
                    
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
                Button(action: { showingAddReminder = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.petlyDarkGreen)
                }
            }
        }
        .sheet(isPresented: $showingAddReminder) {
            AddReminderView()
                .buttonStyle(.plain)
        }
        .buttonStyle(.plain)
        .preferredColorScheme(.light)
        .onboardingTooltip(
            key: .reminders,
            message: "Set reminders for vaccinations, medications, and vet appointments. Never miss an important date!",
            icon: "calendar.badge.clock"
        )
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 50))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Pet Reminders")
                .font(.petlyTitle(24))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Track vaccinations, medications, and more")
                .font(.petlyBody(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 40))
                .foregroundColor(.petlyFormIcon)
            
            Text("No Reminders Yet")
                .font(.petlyBodyMedium(18))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Add reminders for vaccinations, medications, flea treatments, and more to keep your pet healthy.")
                .font(.petlyBody(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingAddReminder = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Reminder")
                }
                .font(.petlyBodyMedium(14))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.petlyDarkGreen)
                .cornerRadius(20)
            }
        }
        .padding()
        .background(Color.petlyLightGreen)
        .cornerRadius(16)
    }
    
    private var dueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                Text("Due Now")
                    .font(.petlyBodyMedium(18))
                    .foregroundColor(.petlyDarkGreen)
            }
            
            ForEach(dueReminders, id: \.id) { reminder in
                ReminderCard(reminder: reminder, onComplete: {
                    completeReminder(reminder)
                }, onDelete: {
                    deleteReminder(reminder)
                })
            }
        }
    }
    
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.petlyDarkGreen)
                Text("Upcoming")
                    .font(.petlyBodyMedium(18))
                    .foregroundColor(.petlyDarkGreen)
            }
            
            ForEach(upcomingReminders, id: \.id) { reminder in
                ReminderCard(reminder: reminder, onComplete: {
                    completeReminder(reminder)
                }, onDelete: {
                    deleteReminder(reminder)
                })
            }
        }
    }
    
    private func completeReminder(_ reminder: PetReminder) {
        reminder.markCompleted()
        NotificationManager.shared.scheduleReminderNotification(for: reminder)
        try? modelContext.save()
    }
    
    private func deleteReminder(_ reminder: PetReminder) {
        NotificationManager.shared.cancelReminderNotification(for: reminder)
        modelContext.delete(reminder)
        try? modelContext.save()
    }
}

struct ReminderCard: View {
    let reminder: PetReminder
    let onComplete: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteConfirmation = false
    
    private var reminderColor: Color {
        switch reminder.type.color {
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "teal": return .teal
        case "green": return .green
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(reminderColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: reminder.type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(reminderColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.petlyDarkGreen)
                
                HStack(spacing: 4) {
                    Text(reminder.type.rawValue)
                        .font(.petlyBody(12))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    if reminder.isDue {
                        Text("Due now")
                            .font(.petlyBody(12))
                            .foregroundColor(.orange)
                    } else {
                        Text(dueDateText)
                            .font(.petlyBody(12))
                            .foregroundColor(.secondary)
                    }
                }
                
                if let notes = reminder.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.petlyBody(11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Button(action: onComplete) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.petlyDarkGreen)
                }
                
                Button(action: { showingDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red.opacity(0.7))
                }
            }
        }
        .padding()
        .background(Color.petlyLightGreen)
        .cornerRadius(12)
        .confirmationDialog("Delete Reminder", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this reminder?")
        }
    }
    
    private var dueDateText: String {
        let days = reminder.daysUntilDue
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else if days < 7 {
            return "In \(days) days"
        } else if days < 30 {
            let weeks = days / 7
            return "In \(weeks) week\(weeks > 1 ? "s" : "")"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: reminder.nextDueDate)
        }
    }
}

struct AddReminderView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var reminderType: ReminderType = .vaccination
    @State private var frequency: ReminderFrequency = .annually
    @State private var nextDueDate = Date()
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reminder Name")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextField("e.g., Rabies Vaccine", text: $title)
                                .font(.petlyBody(14))
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(ReminderType.allCases, id: \.self) { type in
                                        ReminderTypeChip(type: type, isSelected: reminderType == type) {
                                            reminderType = type
                                        }
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Frequency")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            Picker("Frequency", selection: $frequency) {
                                ForEach(ReminderFrequency.allCases, id: \.self) { freq in
                                    Text(freq.rawValue).tag(freq)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Next Due Date")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            DatePicker("", selection: $nextDueDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
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
                        
                        Button(action: saveReminder) {
                            Text("Save Reminder")
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
        guard let dogId = appState.currentDog?.id else { return }
        
        let reminder = PetReminder(
            dogId: dogId,
            title: title,
            reminderType: reminderType,
            frequency: frequency,
            nextDueDate: nextDueDate,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(reminder)
        try? modelContext.save()
        
        NotificationManager.shared.scheduleReminderNotification(for: reminder)
        
        dismiss()
    }
}

struct ReminderTypeChip: View {
    let type: ReminderType
    let isSelected: Bool
    let action: () -> Void
    
    private var chipColor: Color {
        switch type.color {
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "teal": return .teal
        case "green": return .green
        default: return .gray
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 12))
                Text(type.rawValue)
                    .font(.petlyBody(12))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? chipColor.opacity(0.2) : Color.petlyLightGreen)
            .foregroundColor(isSelected ? chipColor : .petlyDarkGreen)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? chipColor : Color.clear, lineWidth: 1)
            )
        }
    }
}

#Preview {
    NavigationView {
        PetRemindersView()
            .environmentObject(AppState())
    }
}
