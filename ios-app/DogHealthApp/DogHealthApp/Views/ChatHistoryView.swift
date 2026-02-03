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
    
    var onSelectConversation: ((String, [Message]) -> Void)?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.petlyBackground.ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading conversations...")
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
                            Task { await loadConversations() }
                        }
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyDarkGreen)
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
                    List {
                        ForEach(conversations) { conversation in
                            ConversationRow(
                                conversation: conversation,
                                showContinueButton: onSelectConversation != nil
                            )
                            .listRowBackground(Color.petlyBackground)
                            .listRowSeparator(.hidden)
                            .onTapGesture {
                                if onSelectConversation != nil {
                                    loadAndSwitchToConversation(conversation)
                                } else {
                                    selectedConversationForDetail = conversation
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    conversationToDelete = conversation
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    conversationToRename = conversation
                                    newTitle = conversation.title
                                    showingRenameAlert = true
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                .tint(.petlyDarkGreen)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.petlyDarkGreen)
                }
            }
            .sheet(item: $selectedConversationForDetail) { conversation in
                ConversationDetailView(conversation: conversation)
                    .environmentObject(appState)
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
        Task {
            do {
                try await APIService.shared.deleteConversation(conversationId: conversation.id)
                await MainActor.run {
                    conversations.removeAll { $0.id == conversation.id }
                }
            } catch {
                print("Failed to delete conversation: \(error)")
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
        Task {
            do {
                let messages = try await APIService.shared.getConversationMessages(conversationId: conversation.id)
                await MainActor.run {
                    onSelectConversation?(conversation.id, messages)
                    dismiss()
                }
            } catch {
                print("Failed to load conversation: \(error)")
            }
        }
    }
    
    private func loadConversations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let allConversations = try await APIService.shared.getConversations()
            // Client-side filter: only show conversations with messages (messageCount > 0)
            conversations = allConversations.filter { $0.messageCount > 0 }
            isLoading = false
        } catch {
            errorMessage = "Failed to load conversations: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    var showContinueButton: Bool = false
    
    private var formattedDate: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(conversation.createdAt) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: conversation.createdAt)
        } else if calendar.isDateInYesterday(conversation.createdAt) {
            return "Yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: conversation.createdAt, to: now).day, daysAgo < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: conversation.createdAt)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: conversation.createdAt)
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
                .shadow(color: Color.petlyDarkGreen.opacity(0.08), radius: 12, x: 0, y: 4)
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
                                    NewMessageBubble(message: message, petPhotoData: appState.petPhotoData)
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

#Preview {
    ChatHistoryView()
        .environmentObject(AppState())
}
