import SwiftUI

struct ChatHistoryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var conversations: [Conversation] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedConversationForDetail: Conversation?
    @State private var conversationToDelete: Conversation?
    @State private var conversationToRename: Conversation?
    @State private var newTitle: String = ""
    @State private var showingDeleteAlert = false
    @State private var showingRenameAlert = false
    @State private var searchText: String = ""
    @State private var showArchived = false
    @State private var showingExportSheet = false
    @State private var conversationToExport: Conversation?
    @State private var exportedText: String = ""
    
    var onSelectConversation: ((String, [Message]) -> Void)?
    
    private var filteredConversations: [Conversation] {
        var filtered = conversations.filter { !$0.isArchived || showArchived }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { conversation in
                conversation.title.localizedCaseInsensitiveContains(searchText) ||
                (conversation.lastMessagePreview?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        return filtered
    }
    
    private var pinnedConversations: [Conversation] {
        filteredConversations.filter { $0.isPinned }
    }
    
    private var unpinnedConversations: [Conversation] {
        filteredConversations.filter { !$0.isPinned }
    }
    
    private var groupedConversations: [(String, [Conversation])] {
        let calendar = Calendar.current
        let now = Date()
        
        var pinned: [Conversation] = pinnedConversations
        var today: [Conversation] = []
        var yesterday: [Conversation] = []
        var thisWeek: [Conversation] = []
        var thisMonth: [Conversation] = []
        var older: [Conversation] = []
        
        for conversation in unpinnedConversations {
            let date = conversation.lastMessageCreatedAt ?? conversation.updatedAt ?? conversation.createdAt
            
            if calendar.isDateInToday(date) {
                today.append(conversation)
            } else if calendar.isDateInYesterday(date) {
                yesterday.append(conversation)
            } else if let daysAgo = calendar.dateComponents([.day], from: date, to: now).day, daysAgo < 7 {
                thisWeek.append(conversation)
            } else if let daysAgo = calendar.dateComponents([.day], from: date, to: now).day, daysAgo < 30 {
                thisMonth.append(conversation)
            } else {
                older.append(conversation)
            }
        }
        
        var result: [(String, [Conversation])] = []
        if !pinned.isEmpty { result.append(("Pinned", pinned)) }
        if !today.isEmpty { result.append(("Today", today)) }
        if !yesterday.isEmpty { result.append(("Yesterday", yesterday)) }
        if !thisWeek.isEmpty { result.append(("This Week", thisWeek)) }
        if !thisMonth.isEmpty { result.append(("This Month", thisMonth)) }
        if !older.isEmpty { result.append(("Earlier", older)) }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.petlyBackground.ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.petlyLightGreen)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 32))
                                .foregroundColor(.petlyDarkGreen)
                                .symbolEffect(.pulse)
                        }
                        
                        Text("Loading chats...")
                            .font(.petlyBody(15))
                            .foregroundColor(.petlyFormIcon)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.red.opacity(0.7))
                        }
                        
                        Text(error)
                            .font(.petlyBody(14))
                            .foregroundColor(.petlyFormIcon)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            Task { await loadConversations() }
                        }) {
                            Text("Try Again")
                                .font(.petlyBody(14))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.petlyDarkGreen)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                } else if conversations.isEmpty {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Color.petlyLightGreen)
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.petlyDarkGreen.opacity(0.6))
                        }
                        
                        VStack(spacing: 8) {
                            Text("No conversations yet")
                                .font(.petlyTitle(22))
                                .foregroundColor(.petlyDarkGreen)
                            
                            Text("Start chatting with Petly AI to get personalized advice about your pet's health, nutrition, and training.")
                                .font(.petlyBody(15))
                                .foregroundColor(.petlyFormIcon)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 40)
                } else {
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundColor(.petlyFormIcon)
                            
                            TextField("Search conversations...", text: $searchText)
                                .font(.petlyBody(15))
                                .foregroundColor(.petlyDarkGreen)
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.petlyFormIcon)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.petlyDarkGreen.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                        
                        if filteredConversations.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.petlyFormIcon.opacity(0.5))
                                Text("No results for \"\(searchText)\"")
                                    .font(.petlyBody(15))
                                    .foregroundColor(.petlyFormIcon)
                            }
                            .frame(maxHeight: .infinity)
                        } else {
                            List {
                                ForEach(groupedConversations, id: \.0) { section, convos in
                                    Section {
                                        ForEach(convos) { conversation in
                                            SwipeableConversationRow(
                                                conversation: conversation,
                                                showContinueButton: onSelectConversation != nil,
                                                onDelete: {
                                                    conversationToDelete = conversation
                                                    showingDeleteAlert = true
                                                },
                                                onRename: {
                                                    conversationToRename = conversation
                                                    newTitle = conversation.title
                                                    showingRenameAlert = true
                                                },
                                                onPin: {
                                                    togglePin(conversation)
                                                },
                                                onArchive: {
                                                    toggleArchive(conversation)
                                                },
                                                onExport: {
                                                    exportConversation(conversation)
                                                },
                                                onTap: {
                                                    HapticFeedback.light()
                                                    if onSelectConversation != nil {
                                                        loadAndSwitchToConversation(conversation)
                                                    } else {
                                                        selectedConversationForDetail = conversation
                                                    }
                                                }
                                            )
                                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                            .listRowSeparator(.hidden)
                                            .listRowBackground(Color.petlyBackground)
                                        }
                                    } header: {
                                        Text(section)
                                            .font(.petlyBody(13))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.petlyFormIcon)
                                            .textCase(nil)
                                    }
                                }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .background(Color.petlyBackground)
                            .refreshable {
                                await loadConversations()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showArchived.toggle()
                            }
                        }) {
                            Image(systemName: showArchived ? "archivebox.fill" : "archivebox")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(showArchived ? .petlyDarkGreen : .petlyFormIcon)
                        }
                        
                        if !conversations.isEmpty {
                            Text("\(filteredConversations.count) chat\(filteredConversations.count == 1 ? "" : "s")")
                                .font(.petlyCaption(12))
                                .foregroundColor(.petlyFormIcon)
                        }
                    }
                }
            }
            .sheet(item: $selectedConversationForDetail) { conversation in
                ConversationDetailView(conversation: conversation)
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showingExportSheet) {
                if !exportedText.isEmpty {
                    ShareSheet(items: [exportedText])
                }
            }
            .alert("Delete Chat", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let conversation = conversationToDelete {
                        deleteConversation(conversation)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this chat? This cannot be undone.")
            }
            .alert("Rename Chat", isPresented: $showingRenameAlert) {
                TextField("Chat name", text: $newTitle)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    if let conversation = conversationToRename {
                        renameConversation(conversation, newTitle: newTitle)
                    }
                }
            } message: {
                Text("Enter a new name for this chat")
            }
        }
        .task {
            await loadConversations()
        }
    }
    
        private func deleteConversation(_ conversation: Conversation) {
            // Remove immediately from UI (optimistic delete) to prevent pop-back issue
            withAnimation(.easeOut(duration: 0.25)) {
                conversations.removeAll { $0.id == conversation.id }
            }
            conversationToDelete = nil
        
            // Then delete from server in background
            Task {
                do {
                    try await APIService.shared.deleteConversation(conversationId: conversation.id)
                } catch {
                    print("Failed to delete conversation: \(error)")
                    // Optionally: could re-add the conversation if delete fails
                }
            }
        }
    
    private func renameConversation(_ conversation: Conversation, newTitle: String) {
        Task {
            do {
                try await APIService.shared.renameConversation(conversationId: conversation.id, title: newTitle)
                await MainActor.run {
                    if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                        conversations[index].title = newTitle
                    }
                }
            } catch {
                print("Failed to rename conversation: \(error)")
            }
        }
    }
    
    private func loadAndSwitchToConversation(_ conversation: Conversation) {
        onSelectConversation?(conversation.id, [])
        dismiss()
    }
    
    private func loadConversations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let allConversations = try await APIService.shared.getConversations()
            conversations = allConversations.filter { $0.messageCount > 0 }
            isLoading = false
        } catch {
            errorMessage = "Failed to load conversations: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func togglePin(_ conversation: Conversation) {
        HapticFeedback.light()
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            let newPinnedState = !conversations[index].isPinned
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                conversations[index].isPinned = newPinnedState
            }
            // Persist to server
            Task {
                do {
                    try await APIService.shared.updateConversation(conversationId: conversation.id, isPinned: newPinnedState)
                } catch {
                    print("Failed to update pin state: \(error)")
                }
            }
        }
    }
    
    private func toggleArchive(_ conversation: Conversation) {
        HapticFeedback.light()
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            let newArchivedState = !conversations[index].isArchived
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                conversations[index].isArchived = newArchivedState
            }
            // Persist to server
            Task {
                do {
                    try await APIService.shared.updateConversation(conversationId: conversation.id, isArchived: newArchivedState)
                } catch {
                    print("Failed to update archive state: \(error)")
                }
            }
        }
    }
    
    private func exportConversation(_ conversation: Conversation) {
        conversationToExport = conversation
        Task {
            do {
                let messages = try await APIService.shared.getConversationMessages(conversationId: conversation.id)
                await MainActor.run {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .short
                    
                    var text = "Chat Export: \(conversation.title)\n"
                    text += "Exported on: \(dateFormatter.string(from: Date()))\n"
                    text += String(repeating: "-", count: 40) + "\n\n"
                    
                    for message in messages {
                        let role = message.role == .user ? "You" : "Petly AI"
                        let time = dateFormatter.string(from: message.timestamp)
                        text += "[\(time)] \(role):\n\(message.content)\n\n"
                    }
                    
                    exportedText = text
                    showingExportSheet = true
                }
            } catch {
                print("Failed to export conversation: \(error)")
            }
        }
    }
}

struct SwipeableConversationRow: View {
    let conversation: Conversation
    var showContinueButton: Bool = false
    var onDelete: () -> Void
    var onRename: () -> Void
    var onPin: () -> Void
    var onArchive: () -> Void
    var onExport: () -> Void
    var onTap: () -> Void
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            ConversationRow(
                conversation: conversation,
                showContinueButton: showContinueButton
            )
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                HapticFeedback.medium()
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
        .contextMenu {
            Button {
                onPin()
            } label: {
                Label(conversation.isPinned ? "Unpin" : "Pin", systemImage: conversation.isPinned ? "pin.slash" : "pin")
            }
            
            Button {
                onRename()
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            
            Button {
                onExport()
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            
            Button {
                onArchive()
            } label: {
                Label(conversation.isArchived ? "Unarchive" : "Archive", systemImage: conversation.isArchived ? "tray.and.arrow.up" : "archivebox")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    var showContinueButton: Bool = false
    
    private var formattedDate: String {
        let calendar = Calendar.current
        let now = Date()
        let dateToShow = conversation.lastMessageCreatedAt ?? conversation.updatedAt ?? conversation.createdAt
        
        if calendar.isDateInToday(dateToShow) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: dateToShow)
        } else if calendar.isDateInYesterday(dateToShow) {
            return "Yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: dateToShow, to: now).day, daysAgo < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: dateToShow)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: dateToShow)
        }
    }
    
    private var previewText: String {
        if let preview = conversation.lastMessagePreview {
            let prefix = conversation.lastMessageRole == "assistant" ? "Petly: " : ""
            return prefix + preview
        }
        if let lastMessage = conversation.messages.last {
            return lastMessage.content
        }
        return "\(conversation.messageCount) message\(conversation.messageCount == 1 ? "" : "s")"
    }
    
    private var conversationIcon: String {
        let title = conversation.title.lowercased()
        if title.contains("food") || title.contains("eat") || title.contains("diet") || title.contains("nutrition") {
            return "fork.knife"
        } else if title.contains("health") || title.contains("sick") || title.contains("symptom") || title.contains("vet") {
            return "heart.fill"
        } else if title.contains("train") || title.contains("behavior") || title.contains("walk") {
            return "figure.walk"
        } else if title.contains("groom") || title.contains("bath") || title.contains("brush") {
            return "scissors"
        } else {
            return "sparkles"
        }
    }
    
    private var iconBackgroundColor: Color {
        let title = conversation.title.lowercased()
        if title.contains("food") || title.contains("eat") || title.contains("diet") || title.contains("nutrition") {
            return Color(red: 0.95, green: 0.6, blue: 0.4)
        } else if title.contains("health") || title.contains("sick") || title.contains("symptom") || title.contains("vet") {
            return Color(red: 0.9, green: 0.5, blue: 0.5)
        } else if title.contains("train") || title.contains("behavior") || title.contains("walk") {
            return Color(red: 0.5, green: 0.7, blue: 0.9)
        } else if title.contains("groom") || title.contains("bath") || title.contains("brush") {
            return Color(red: 0.7, green: 0.6, blue: 0.85)
        } else {
            return Color.petlyDarkGreen
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconBackgroundColor.opacity(0.15))
                    .frame(width: 52, height: 52)
                
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 44, height: 44)
                
                Image(systemName: conversationIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center) {
                    if conversation.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.petlyDarkGreen)
                    }
                    
                    Text(conversation.title)
                        .font(.petlyBody(15))
                        .fontWeight(.semibold)
                        .foregroundColor(.petlyDarkGreen)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(formattedDate)
                        .font(.petlyBody(11))
                        .foregroundColor(.petlyFormIcon)
                }
                
                Text(previewText)
                    .font(.petlyBody(13))
                    .foregroundColor(.petlyFormIcon)
                    .lineLimit(2)
                    .lineSpacing(2)
                
                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 9))
                        Text("\(conversation.messageCount)")
                            .font(.petlyBody(10))
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.petlyDarkGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.petlyLightGreen)
                    )
                }
                .padding(.top, 2)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.petlyFormIcon.opacity(0.4))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }
}

struct ConversationDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let conversation: Conversation
    @State private var messages: [Message] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.petlyBackground.ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading messages...")
                            .font(.petlyBody(14))
                            .foregroundColor(.petlyFormIcon)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.petlyFormIcon)
                        Text(error)
                            .font(.petlyBody(14))
                            .foregroundColor(.petlyFormIcon)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task { await loadMessages() }
                        }
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyDarkGreen)
                    }
                    .padding()
                } else if messages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 50))
                            .foregroundColor(.petlyFormIcon.opacity(0.5))
                        Text("No messages in this conversation")
                            .font(.petlyBody(14))
                            .foregroundColor(.petlyFormIcon)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                                VStack(spacing: 0) {
                                    if shouldShowDateHeader(for: index) {
                                        MessageDateHeader(date: message.timestamp)
                                            .padding(.vertical, 8)
                                    }
                                    NewMessageBubble(message: message)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(conversation.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(.petlyDarkGreen)
                }
            }
        }
        .task {
            await loadMessages()
        }
    }
    
    private func loadMessages() async {
        isLoading = true
        errorMessage = nil
        
        do {
            messages = try await APIService.shared.getConversationMessages(conversationId: conversation.id)
            isLoading = false
        } catch {
            errorMessage = "Failed to load messages: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func shouldShowDateHeader(for index: Int) -> Bool {
        guard index < messages.count else { return false }
        let message = messages[index]
        
        if index == 0 { return true }
        
        let previousMessage = messages[index - 1]
        let calendar = Calendar.current
        
        return !calendar.isDate(message.timestamp, inSameDayAs: previousMessage.timestamp)
    }
}

struct DeleteTrashIcon: View {
    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            
            context.fill(
                Path { path in
                    path.move(to: CGPoint(x: width * 0.15, y: height * 0.25))
                    path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.95))
                    path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.95))
                    path.addLine(to: CGPoint(x: width * 0.85, y: height * 0.25))
                    path.closeSubpath()
                },
                with: .color(.white)
            )
            
            context.fill(
                Path { path in
                    path.addRoundedRect(
                        in: CGRect(x: 0, y: height * 0.12, width: width, height: height * 0.1),
                        cornerSize: CGSize(width: 2, height: 2)
                    )
                },
                with: .color(.white)
            )
            
            context.fill(
                Path { path in
                    path.addRoundedRect(
                        in: CGRect(x: width * 0.35, y: 0, width: width * 0.3, height: height * 0.15),
                        cornerSize: CGSize(width: 2, height: 2)
                    )
                },
                with: .color(.white)
            )
            
            let lineWidth: CGFloat = 2
            let lineColor = Color.red
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: width * 0.35, y: height * 0.35))
                    path.addLine(to: CGPoint(x: width * 0.38, y: height * 0.85))
                },
                with: .color(lineColor),
                lineWidth: lineWidth
            )
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: width * 0.5, y: height * 0.35))
                    path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.85))
                },
                with: .color(lineColor),
                lineWidth: lineWidth
            )
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: width * 0.65, y: height * 0.35))
                    path.addLine(to: CGPoint(x: width * 0.62, y: height * 0.85))
                },
                with: .color(lineColor),
                lineWidth: lineWidth
            )
        }
    }
}

#Preview {
    ChatHistoryView()
        .environmentObject(AppState())
}
