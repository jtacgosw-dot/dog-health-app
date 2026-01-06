import SwiftUI
import SwiftData

struct HealthTimelineView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    
    @Query(sort: \HealthLogEntry.timestamp, order: .reverse) private var allEntries: [HealthLogEntry]
    
    @State private var selectedFilter: LogType?
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingAddEntry = false
    @State private var entriesVisible = false
    @State private var isRefreshing = false
    @State private var entryToEdit: HealthLogEntry?
    
    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "Week"
        case month = "Month"
        case all = "All"
        
        var dateThreshold: Date {
            let calendar = Calendar.current
            switch self {
            case .today:
                return calendar.startOfDay(for: Date())
            case .week:
                return calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            case .all:
                return Date.distantPast
            }
        }
    }
    
    private var filteredEntries: [HealthLogEntry] {
        let dogId = appState.currentDog?.id ?? "default"
        return allEntries.filter { entry in
            let matchesDog = entry.dogId == dogId
            let matchesTime = entry.timestamp >= selectedTimeRange.dateThreshold
            let matchesFilter = selectedFilter == nil || entry.logType == selectedFilter?.rawValue
            return matchesDog && matchesTime && matchesFilter
        }
    }
    
    private var groupedEntries: [(date: Date, entries: [HealthLogEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }.map { (date: $0.key, entries: $0.value) }
    }
    
    private var stats: (total: Int, thisWeek: Int, streak: Int) {
        let dogId = appState.currentDog?.id ?? "default"
        let dogEntries = allEntries.filter { $0.dogId == dogId }
        let total = dogEntries.count
        
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let thisWeek = dogEntries.filter { $0.timestamp >= weekAgo }.count
        
        var streak = 0
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: Date())
        
        while true {
            let dayEntries = dogEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: currentDate) }
            if dayEntries.isEmpty {
                break
            }
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return (total, thisWeek, streak)
    }
    
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                ScrollView {
                    VStack(spacing: 20) {
                        statsCards
                            .appearAnimation(delay: 0.1)
                        
                        filterSection
                            .appearAnimation(delay: 0.2)
                        
                        timeRangeSelector
                            .appearAnimation(delay: 0.3)
                        
                        if filteredEntries.isEmpty {
                            emptyState
                                .appearAnimation(delay: 0.4)
                        } else {
                            timelineContent
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            entriesVisible = true
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            DailyLogEntryView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .buttonStyle(.plain)
        }
        .sheet(item: $entryToEdit) { entry in
            EditLogEntryView(entry: entry)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .buttonStyle(.plain)
        }
        .buttonStyle(.plain)
    }
    
    private var header: some View {
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
            
            Text("Health Timeline")
                .font(.petlyTitle(24))
                .foregroundColor(.petlyDarkGreen)
            
            Spacer()
            
            Button(action: { showingAddEntry = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.petlyDarkGreen)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var statsCards: some View {
        HStack(spacing: 12) {
            TimelineStatCard(
                title: "Total Logs",
                value: "\(stats.total)",
                icon: "list.bullet.clipboard",
                color: .petlyDarkGreen
            )
            
            TimelineStatCard(
                title: "This Week",
                value: "\(stats.thisWeek)",
                icon: "calendar",
                color: .blue
            )
            
            TimelineStatCard(
                title: "Day Streak",
                value: "\(stats.streak)",
                icon: "flame.fill",
                color: .orange
            )
        }
    }
    
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Filter by Type")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All",
                        icon: "square.grid.2x2",
                        isSelected: selectedFilter == nil,
                        action: { selectedFilter = nil }
                    )
                    
                    ForEach(LogType.allCases) { logType in
                        FilterChip(
                            title: logType.rawValue,
                            icon: logType.icon,
                            isSelected: selectedFilter == logType,
                            action: { selectedFilter = logType }
                        )
                    }
                }
            }
        }
    }
    
    private var timeRangeSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTimeRange = range
                    }
                }) {
                    Text(range.rawValue)
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(selectedTimeRange == range ? .white : .petlyDarkGreen)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(selectedTimeRange == range ? Color.petlyDarkGreen : Color.clear)
                        .cornerRadius(8)
                }
            }
        }
        .padding(4)
        .background(Color.petlyLightGreen)
        .cornerRadius(12)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundColor(.petlyDarkGreen.opacity(0.5))
            
            Text("No health logs yet")
                .font(.petlyBodyMedium(18))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Start tracking your pet's health by adding your first log entry")
                .font(.petlyBody(14))
                .foregroundColor(.petlyFormIcon)
                .multilineTextAlignment(.center)
            
            Button(action: { showingAddEntry = true }) {
                Text("Add First Entry")
                    .font(.petlyBodyMedium(16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.petlyDarkGreen)
                    .cornerRadius(25)
            }
        }
        .padding(.vertical, 40)
    }
    
    private var timelineContent: some View {
        VStack(spacing: 0) {
            ForEach(Array(groupedEntries.enumerated()), id: \.element.date) { index, group in
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(formatDateHeader(group.date))
                            .font(.petlyBodyMedium(16))
                            .foregroundColor(.petlyDarkGreen)
                        
                        Spacer()
                        
                        Text("\(group.entries.count) entries")
                            .font(.petlyBody(12))
                            .foregroundColor(.petlyFormIcon)
                    }
                    .padding(.vertical, 12)
                    .slideIn(index: index, isVisible: entriesVisible)
                    
                    ForEach(Array(group.entries.enumerated()), id: \.element.id) { entryIndex, entry in
                        TimelineEntryRow(
                            entry: entry,
                            isFirst: entryIndex == 0,
                            isLast: entryIndex == group.entries.count - 1,
                            onDelete: { deleteEntry(entry) },
                            onEdit: { entryToEdit = entry }
                        )
                        .slideIn(index: index * 10 + entryIndex, isVisible: entriesVisible)
                    }
                }
                
                if index < groupedEntries.count - 1 {
                    Rectangle()
                        .fill(Color.petlyDarkGreen.opacity(0.1))
                        .frame(height: 1)
                        .padding(.vertical, 8)
                }
            }
        }
    }
    
    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
    
    private func deleteEntry(_ entry: HealthLogEntry) {
        withAnimation {
            modelContext.delete(entry)
            try? modelContext.save()
        }
    }
}

struct TimelineStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.petlyTitle(24))
                .foregroundColor(.petlyDarkGreen)
                .contentTransition(.numericText())
            
            Text(title)
                .font(.petlyBody(12))
                .foregroundColor(.petlyFormIcon)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.petlyLightGreen)
        .cornerRadius(16)
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.petlyBody(12))
            }
            .foregroundColor(isSelected ? .white : .petlyDarkGreen)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.petlyDarkGreen : Color.petlyLightGreen)
            .cornerRadius(20)
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

struct TimelineEntryRow: View {
    let entry: HealthLogEntry
    let isFirst: Bool
    let isLast: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(Color.petlyDarkGreen.opacity(0.3))
                        .frame(width: 2, height: 12)
                }
                
                ZStack {
                    Circle()
                        .fill(Color.petlyLightGreen)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: entry.logTypeEnum?.icon ?? "circle")
                        .font(.system(size: 16))
                        .foregroundColor(.petlyDarkGreen)
                }
                
                if !isLast {
                    Rectangle()
                        .fill(Color.petlyDarkGreen.opacity(0.3))
                        .frame(width: 2)
                        .frame(minHeight: 20)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.displayTitle)
                        .font(.petlyBodyMedium(16))
                        .foregroundColor(.petlyDarkGreen)
                    
                    Spacer()
                    
                    Text(formatTime(entry.timestamp))
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                }
                
                if !entry.displaySubtitle.isEmpty {
                    Text(entry.displaySubtitle)
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyFormIcon)
                }
                
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 8)
            .padding(.trailing, 12)
            .background(Color.petlyLightGreen.opacity(0.5))
            .cornerRadius(12)
            .contextMenu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .confirmationDialog("Delete this entry?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct EditLogEntryView: View {
    @Bindable var entry: HealthLogEntry
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedDate: Date
    @State private var notes: String
    @State private var amount: String
    @State private var duration: String
    @State private var selectedMood: Int
    @State private var showSuccessAnimation = false
    
    init(entry: HealthLogEntry) {
        self.entry = entry
        _selectedDate = State(initialValue: entry.timestamp)
        _notes = State(initialValue: entry.notes)
        _amount = State(initialValue: entry.amount ?? entry.waterAmount ?? entry.treatName ?? entry.groomingType ?? entry.activityType ?? "")
        _duration = State(initialValue: entry.duration ?? entry.dosage ?? entry.location ?? "")
        _selectedMood = State(initialValue: entry.moodLevel ?? entry.severityLevel ?? 3)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
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
                        
                        if entry.logType == "Walk" || entry.logType == "Playtime" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Duration (minutes)")
                                    .font(.petlyBodyMedium(14))
                                    .foregroundColor(.petlyDarkGreen)
                                
                                TextField("e.g., 30", text: $duration)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(PetlyTextFieldStyle())
                            }
                        }
                        
                        if entry.logType == "Meals" || entry.logType == "Water" || entry.logType == "Treat" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Amount")
                                    .font(.petlyBodyMedium(14))
                                    .foregroundColor(.petlyDarkGreen)
                                
                                TextField("e.g., 1 cup", text: $amount)
                                    .textFieldStyle(PetlyTextFieldStyle())
                            }
                        }
                        
                        if entry.logType == "Mood" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Mood Level")
                                    .font(.petlyBodyMedium(14))
                                    .foregroundColor(.petlyDarkGreen)
                                
                                HStack(spacing: 12) {
                                    ForEach(0..<5, id: \.self) { index in
                                        let moods = ["😢", "😕", "😐", "🙂", "😄"]
                                        Button(action: { selectedMood = index }) {
                                            Text(moods[index])
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
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                                .scrollContentBackground(.hidden)
                        }
                        
                        Button(action: saveChanges) {
                            Text("SAVE CHANGES")
                                .font(.petlyBodyMedium(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.petlyDarkGreen)
                                .cornerRadius(25)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Edit \(entry.logType)")
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
        .overlay {
            SuccessCheckmarkView(isShowing: $showSuccessAnimation)
        }
        .onChange(of: showSuccessAnimation) { _, newValue in
            if !newValue {
                dismiss()
            }
        }
    }
    
    private func saveChanges() {
        entry.timestamp = selectedDate
        entry.notes = notes
        
        switch entry.logType {
        case "Walk", "Playtime":
            entry.duration = duration
            entry.amount = amount
        case "Meals":
            entry.amount = amount
        case "Water":
            entry.waterAmount = amount
        case "Treat":
            entry.treatName = amount
        case "Grooming":
            entry.groomingType = amount
        case "Mood":
            entry.moodLevel = selectedMood
        case "Symptom":
            entry.severityLevel = selectedMood
        case "Supplements":
            entry.supplementName = amount
            entry.dosage = duration
        case "Upcoming Appointments":
            entry.appointmentType = amount
            entry.location = duration
        default:
            break
        }
        
        entry.needsSync = true
        
        do {
            try modelContext.save()
            Task {
                await HealthLogSyncService.shared.syncSingleLog(entry)
            }
        } catch {
            print("Failed to save changes: \(error)")
        }
        
        showSuccessAnimation = true
    }
}

#Preview {
    HealthTimelineView()
        .environmentObject(AppState())
}
