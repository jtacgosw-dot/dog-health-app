import SwiftUI

struct NewChatView: View {
    @EnvironmentObject var appState: AppState
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @State private var isLoading = false
    @State private var conversationId: String?
    @State private var errorMessage: String?
    @State private var showCloseButton = false
    
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    if showCloseButton {
                        Button(action: {
                            withAnimation {
                                messages = []
                                conversationId = nil
                                showCloseButton = false
                            }
                        }) {
                            Text("X Close Chat")
                                .font(.petlyBody(14))
                                .foregroundColor(.petlyDarkGreen)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.petlyLightGreen)
                                .cornerRadius(20)
                        }
                    }
                    
                    Spacer()
                    
                    if let dog = appState.currentDog {
                        Circle()
                            .fill(Color.petlyLightGreen)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text("🐕")
                                    .font(.system(size: 25))
                            )
                    }
                }
                .padding()
                
                if messages.isEmpty {
                    EmptyStateChatView(onQuickAction: handleQuickAction)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(messages) { message in
                                    NewMessageBubble(message: message)
                                        .id(message.id)
                                }
                                
                                if isLoading {
                                    HStack {
                                        ProgressView()
                                            .tint(.petlyDarkGreen)
                                        Text("Petly is thinking...")
                                            .font(.petlyBody(12))
                                            .foregroundColor(.petlyFormIcon)
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
                        .font(.petlyBody(12))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                }
                
                HStack(spacing: 12) {
                    TextField("Start A Conversation...", text: $messageText, axis: .vertical)
                        .font(.petlyBody(14))
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.petlyLightGreen)
                        .cornerRadius(25)
                        .lineLimit(1...5)
                    
                    Button(action: {}) {
                        Image(systemName: "photo")
                            .font(.system(size: 20))
                            .foregroundColor(.petlyDarkGreen)
                    }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20))
                            .foregroundColor(messageText.isEmpty ? .petlyFormIcon : .petlyDarkGreen)
                    }
                    .disabled(messageText.isEmpty || isLoading)
                }
                .padding()
                .background(Color.petlyBackground)
                .padding(.bottom, 80)
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
        showCloseButton = true
        
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
                        id: response.message.id,
                        conversationId: response.conversationId,
                        role: .assistant,
                        content: response.message.content,
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

struct EmptyStateChatView: View {
    let onQuickAction: (String) -> Void
    
    let quickActions = [
        ("⚡", "Energy level today?", "What's my dog's energy level today?"),
        ("🎓", "Training needs?", "What training does my dog need?"),
        ("🍖", "Preferred food type?", "What food type is best for my dog?"),
        ("📋", "Any recent vet notes?", "Do you have any recent vet notes?")
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 12) {
                Text("Hello Kate")
                    .font(.petlyTitle(36))
                    .foregroundColor(.petlyDarkGreen)
                
                Text("How can we help you today?")
                    .font(.petlyTitle(32))
                    .foregroundColor(.petlyDarkGreen)
                    .multilineTextAlignment(.center)
            }
            
            Text("PETLY AI is here to make your pet's wellness an easy experience. From nutrition, to training - ask anything.")
                .font(.petlyBody(14))
                .foregroundColor(.petlyFormIcon)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ChatQuickActionChip(emoji: quickActions[0].0, title: quickActions[0].1) {
                        onQuickAction(quickActions[0].2)
                    }
                    ChatQuickActionChip(emoji: quickActions[1].0, title: quickActions[1].1) {
                        onQuickAction(quickActions[1].2)
                    }
                }
                HStack(spacing: 12) {
                    ChatQuickActionChip(emoji: quickActions[2].0, title: quickActions[2].1) {
                        onQuickAction(quickActions[2].2)
                    }
                    ChatQuickActionChip(emoji: quickActions[3].0, title: quickActions[3].1) {
                        onQuickAction(quickActions[3].2)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

struct ChatQuickActionChip: View {
    let emoji: String
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 16))
                Text(title)
                    .font(.petlyBody(13))
                    .foregroundColor(.petlyDarkGreen)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.petlyLightGreen)
            .cornerRadius(20)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

struct NewMessageBubble: View {
    let message: Message
    @State private var appeared = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 5) {
                Text(message.content)
                    .font(.petlyBody(14))
                    .padding(14)
                    .background(message.role == .user ? Color.petlyDarkGreen : Color.petlyLightGreen)
                    .foregroundColor(message.role == .user ? .white : .petlyDarkGreen)
                    .cornerRadius(18)
                
                Text(message.timestamp, style: .time)
                    .font(.petlyBody(10))
                    .foregroundColor(.petlyFormIcon)
            }
            .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .assistant {
                Spacer()
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

#Preview {
    NewChatView()
        .environmentObject(AppState())
}
