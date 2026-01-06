import SwiftUI
import SwiftData

struct NewChatView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HealthLogEntry.timestamp, order: .reverse) private var allHealthLogs: [HealthLogEntry]
    @Binding var initialPrompt: String
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @State private var isLoading = false
    @State private var conversationId: String?
    @State private var errorMessage: String?
    @State private var showCloseButton = false
    
    init(initialPrompt: Binding<String> = .constant("")) {
        self._initialPrompt = initialPrompt
    }
    
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
                                Image(systemName: "dog.fill")
                                    .font(.system(size: 25))
                                    .foregroundColor(.petlyDarkGreen)
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
        .onChange(of: initialPrompt) { newValue in
            if !newValue.isEmpty {
                messageText = newValue
                initialPrompt = ""
                sendMessage()
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
                let dogProfile = buildDogProfile()
                let healthLogs = buildHealthLogs()
                
                let response = try await APIService.shared.sendChatMessage(
                    message: currentMessage,
                    conversationId: conversationId,
                    dogId: appState.currentDog?.id,
                    dogProfile: dogProfile,
                    healthLogs: healthLogs
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
    
    private func buildDogProfile() -> ChatDogProfile? {
        guard let dog = appState.currentDog else { return nil }
        
        return ChatDogProfile(
            name: dog.name,
            breed: dog.breed,
            age: dog.age,
            weight: dog.weight,
            healthConcerns: dog.healthConcerns.isEmpty ? nil : dog.healthConcerns,
            allergies: dog.allergies.isEmpty ? nil : dog.allergies
        )
    }
    
    private func buildHealthLogs() -> [ChatHealthLog]? {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentLogs = allHealthLogs.filter { $0.timestamp >= thirtyDaysAgo }
        
        guard !recentLogs.isEmpty else { return nil }
        
        let formatter = ISO8601DateFormatter()
        
        return Array(recentLogs.prefix(100)).map { log in
            ChatHealthLog(
                logType: log.logType,
                timestamp: formatter.string(from: log.timestamp),
                notes: log.notes.isEmpty ? nil : log.notes,
                mealType: log.mealType,
                amount: log.amount,
                duration: log.duration,
                moodLevel: log.moodLevel,
                symptomType: log.symptomType,
                severityLevel: log.severityLevel,
                digestionQuality: log.digestionQuality,
                activityType: log.activityType,
                supplementName: log.supplementName,
                dosage: log.dosage,
                appointmentType: log.appointmentType,
                location: log.location,
                groomingType: log.groomingType,
                treatName: log.treatName,
                waterAmount: log.waterAmount
            )
        }
    }
}

struct EmptyStateChatView: View {
    @EnvironmentObject var appState: AppState
    let onQuickAction: (String) -> Void
    
    private var userName: String {
        if let fullName = appState.currentUser?.fullName, !fullName.isEmpty {
            return fullName.components(separatedBy: " ").first ?? fullName
        }
        return "there"
    }
    
    let quickActions = [
        ("bolt.fill", "Energy level today?", "What's my dog's energy level today?"),
        ("figure.run", "Training needs?", "What training does my dog need?"),
        ("fork.knife", "Preferred food type?", "What food type is best for my dog?"),
        ("doc.text", "Any recent vet notes?", "Do you have any recent vet notes?")
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 8) {
                Text("Hello \(userName)")
                    .font(.petlyTitle(36))
                    .foregroundColor(.petlyDarkGreen)
                    .underline()
                
                Text("How can we help")
                    .font(.petlyTitle(32))
                    .foregroundColor(.petlyDarkGreen)
                
                Text("you today?")
                    .font(.petlyTitle(32))
                    .foregroundColor(.petlyDarkGreen)
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
                Image(systemName: emoji)
                    .font(.system(size: 14))
                    .foregroundColor(.petlyDarkGreen)
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
        .buttonStyle(.plain)
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
