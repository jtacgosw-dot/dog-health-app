import SwiftUI

struct ChatHistoryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var conversations: [Conversation] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedConversation: Conversation?
    
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
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(conversations) { conversation in
                                ConversationRow(conversation: conversation)
                                    .onTapGesture {
                                        selectedConversation = conversation
                                    }
                            }
                        }
                        .padding()
                    }
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
            .sheet(item: $selectedConversation) { conversation in
                ConversationDetailView(conversation: conversation)
                    .environmentObject(appState)
            }
        }
        .task {
            await loadConversations()
        }
    }
    
    private func loadConversations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            conversations = try await APIService.shared.getConversations()
            isLoading = false
        } catch {
            errorMessage = "Failed to load conversations: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
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
