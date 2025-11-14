import SwiftUI

struct ChatView: View {
    @EnvironmentObject var appState: AppState
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @State private var isLoading = false
    @State private var conversationId: String?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyCream
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if messages.isEmpty {
                        EmptyStateView(onQuickAction: handleQuickAction)
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(spacing: 15) {
                                    ForEach(messages) { message in
                                        MessageBubble(message: message)
                                            .id(message.id)
                                    }
                                    
                                    if isLoading {
                                        HStack {
                                            ProgressView()
                                                .tint(.petlyDarkGreen)
                                            Text("Petly is thinking...")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                    }
                                }
                                .padding()
                            }
                            .onChange(of: messages.count) { _ in
                                if let lastMessage = messages.last {
                                    withAnimation {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.1))
                    }
                    
                    Divider()
                    
                    HStack(spacing: 12) {
                        TextField("Ask Petly anything...", text: $messageText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(20)
                            .lineLimit(1...5)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(messageText.isEmpty ? .gray : .petlyDarkGreen)
                        }
                        .disabled(messageText.isEmpty || isLoading)
                    }
                    .padding()
                    .background(Color.petlyCream)
                }
            }
            .navigationTitle("Petly AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "pawprint.fill")
                            .foregroundColor(.petlyDarkGreen)
                        Text("Petly AI")
                            .font(.headline)
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
        }
    }
    
    private func handleQuickAction(_ action: String) {
        messageText = action
        sendMessage()
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let userMessage = Message(
            id: UUID().uuidString,
            conversationId: conversationId ?? "",
            role: .user,
            content: messageText,
            timestamp: Date(),
            feedback: nil
        )
        
        messages.append(userMessage)
        let currentMessage = messageText
        messageText = ""
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await APIService.shared.sendChatMessage(
                    message: currentMessage,
                    conversationId: conversationId,
                    dogId: appState.currentDog?.id
                )
                
                await MainActor.run {
                    conversationId = response.conversationId
                    
                    let assistantMessage = Message(
                        id: UUID().uuidString,
                        conversationId: response.conversationId,
                        role: .assistant,
                        content: response.response,
                        timestamp: Date(),
                        feedback: nil
                    )
                    messages.append(assistantMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to send message: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

struct EmptyStateView: View {
    let onQuickAction: (String) -> Void
    
    let quickActions = [
        ("fork.knife", "Food Suggestions", "What food do you recommend for my dog?"),
        ("heart.text.square", "Create a Care Plan", "Help me create a care plan for my dog"),
        ("cross.case", "Wellness Tips", "What are some wellness tips for my dog?"),
        ("figure.walk", "Enrichment Ideas", "Give me enrichment ideas for my dog")
    ]
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Chat with Petly AI")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.petlyDarkGreen)
            
            Text("Get personalized guidance for your pet's health, nutrition, and wellbeing")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(spacing: 12) {
                ForEach(quickActions, id: \.1) { icon, title, prompt in
                    QuickActionButton(icon: icon, title: title) {
                        onQuickAction(prompt)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            Spacer()
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.petlyDarkGreen)
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.petlyDarkGreen)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.petlySageGreen)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.petlySageGreen.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == .user {
                Spacer()
            } else {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.petlyDarkGreen)
                    .padding(8)
                    .background(Color.petlySageGreen.opacity(0.2))
                    .clipShape(Circle())
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 5) {
                Text(message.content)
                    .padding(14)
                    .background(message.role == .user ? Color.petlyDarkGreen : Color.white)
                    .foregroundColor(message.role == .user ? .white : .black)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(message.role == .user ? Color.clear : Color.petlySageGreen.opacity(0.3), lineWidth: 1)
                    )
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(AppState())
}
