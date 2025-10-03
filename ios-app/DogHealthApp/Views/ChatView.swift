import SwiftUI

struct ChatView: View {
    @StateObject private var chatService = ChatService()
    @State private var messageText = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(chatService.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Thinking...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: chatService.messages.count) { _ in
                        if let lastMessage = chatService.messages.last {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                if chatService.messages.count <= 1 {
                    ActionButtonsView(onActionTap: { action in
                        messageText = action
                        sendMessage()
                    })
                }
                
                MessageInputView(
                    messageText: $messageText,
                    isLoading: isLoading,
                    onSend: sendMessage
                )
            }
            .navigationTitle("Petly")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if chatService.messages.isEmpty {
                chatService.addWelcomeMessage()
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = messageText
        messageText = ""
        isLoading = true
        
        Task {
            await chatService.sendMessage(userMessage)
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isFromUser {
                Spacer(minLength: 50)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(PetlyColors.primaryGreen)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(PetlyColors.primaryGreen)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PETLY AI")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(PetlyColors.messageBackground)
                            .foregroundColor(.primary)
                            .cornerRadius(20)
                        
                        if message.hasDisclaimer {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text("AI guidance - not medical advice")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text(formatTime(message.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer(minLength: 50)
            }
        }
        .padding(.horizontal)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ActionButtonsView: View {
    let onActionTap: (String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ActionButton(
                    icon: "🥕",
                    title: "Food Suggestions",
                    action: { onActionTap("What are some healthy food suggestions for my dog?") }
                )
                
                ActionButton(
                    icon: "🩺",
                    title: "Create a Care Plan",
                    action: { onActionTap("Help me create a care plan for my dog") }
                )
                
                ActionButton(
                    icon: "💡",
                    title: "Wellness Tips",
                    action: { onActionTap("Give me some wellness tips for my dog") }
                )
                
                ActionButton(
                    icon: "🎾",
                    title: "Enrichment Ideas",
                    action: { onActionTap("What are some enrichment ideas for my dog?") }
                )
            }
            .padding(.horizontal)
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                    )
            )
        }
    }
}

struct MessageInputView: View {
    @Binding var messageText: String
    let isLoading: Bool
    let onSend: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                TextField("Ask Anything.....", text: $messageText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...4)
                    .disabled(isLoading)
                
                Button(action: onSend) {
                    Circle()
                        .fill(canSend ? PetlyColors.primaryGreen : Color.gray)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        )
                }
                .disabled(!canSend || isLoading)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
