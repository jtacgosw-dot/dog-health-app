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
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 50))
                            .foregroundColor(.petlyFormIcon.opacity(0.5))
                        Text("No conversations yet")
                            .font(.petlyTitle(20))
                            .foregroundColor(.petlyDarkGreen)
                        Text("Start a new chat to see your conversation history here")
                            .font(.petlyBody(14))
                            .foregroundColor(.petlyFormIcon)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
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
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: conversation.createdAt, relativeTo: Date())
    }
    
    private var previewText: String {
        if let lastMessage = conversation.messages.last {
            return lastMessage.content
        }
        return "No messages"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.petlyDarkGreen)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.title)
                        .font(.petlyBody(15))
                        .fontWeight(.medium)
                        .foregroundColor(.petlyDarkGreen)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(formattedDate)
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                }
                
                Text(previewText)
                    .font(.petlyBody(13))
                    .foregroundColor(.petlyFormIcon)
                    .lineLimit(2)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.petlyFormIcon)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
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
