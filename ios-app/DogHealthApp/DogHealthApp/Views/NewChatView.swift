import SwiftUI
import SwiftData
import PhotosUI
import Combine

class KeyboardObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    private var cancellables = Set<AnyCancellable>()
    
    var safeAreaBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .safeAreaInsets.bottom ?? 34
    }
    
    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification))
            .compactMap { notification -> (CGFloat, Double)? in
                guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                      let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                    return nil
                }
                return (frame.height, duration)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] height, _ in
                withAnimation(.spring(response: 0.25, dampingFraction: 1.0)) {
                    self?.keyboardHeight = height
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .compactMap { notification -> Double? in
                notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                withAnimation(.spring(response: 0.25, dampingFraction: 1.0)) {
                    self?.keyboardHeight = 0
                }
            }
            .store(in: &cancellables)
    }
}

struct NewChatView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HealthLogEntry.timestamp, order: .reverse) private var allHealthLogs: [HealthLogEntry]
    @Binding var initialPrompt: String
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @State private var isLoading = false
    @State private var isCreatingConversation = false
    @State private var conversationId: String?
    @State private var errorMessage: String?
    @State private var showCloseButton = false
    @State private var attachedImages: [ChatImageAttachment] = []
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingChatHistory = false
    @FocusState private var isTextFieldFocused: Bool
        @StateObject private var keyboardObserver = KeyboardObserver()
    
    // Scaled sizes for Dynamic Type support
    @ScaledMetric(relativeTo: .body) private var avatarSize: CGFloat = 50
    @ScaledMetric(relativeTo: .body) private var avatarIconSize: CGFloat = 25
    @ScaledMetric(relativeTo: .body) private var imagePreviewSize: CGFloat = 60
    // Fixed padding for tab bar when keyboard is hidden
    private let inputBarDefaultPadding: CGFloat = 90
    
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
                        Menu {
                            Button(action: {
                                withAnimation {
                                    messages = []
                                    conversationId = nil
                                    isCreatingConversation = false
                                    showCloseButton = false
                                    attachedImages = []
                                }
                            }) {
                                Label("New Chat", systemImage: "plus.bubble")
                            }
                            
                            Button(action: { showingChatHistory = true }) {
                                Label("Switch Chat", systemImage: "bubble.left.and.bubble.right")
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 14))
                                Text("Chats")
                                    .font(.petlyBody(14))
                            }
                            .foregroundColor(.petlyDarkGreen)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.petlyLightGreen)
                            .cornerRadius(20)
                        }
                    } else {
                        Button(action: { showingChatHistory = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 14))
                                Text("History")
                                    .font(.petlyBody(14))
                            }
                            .foregroundColor(.petlyDarkGreen)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.petlyLightGreen)
                            .cornerRadius(20)
                        }
                    }
                    
                    Spacer()
                    
                                                                                        if appState.currentDog != nil {
                                                                                            if let photoData = appState.petPhotoData,
                                                                                               let uiImage = UIImage(data: photoData) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: min(avatarSize, 70), height: min(avatarSize, 70))
                                                        .clipShape(Circle())
                                                } else {
                                                    Circle()
                                                        .fill(Color.petlyLightGreen)
                                                        .frame(width: min(avatarSize, 70), height: min(avatarSize, 70))
                                                        .overlay(
                                                            Image(systemName: "dog.fill")
                                                                .font(.system(size: min(avatarIconSize, 32)))
                                                                .foregroundColor(.petlyDarkGreen)
                                                        )
                                                }
                                            }
                }
                .padding()
                
                if messages.isEmpty {
                    ScrollView {
                        EmptyStateChatView(onQuickAction: handleQuickAction)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture {
                        dismissKeyboard()
                    }
                } else {
                    ScrollViewReader { proxy in
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
                                    .id(message.id)
                                }
                                
                                if isLoading {
                                    TypingIndicatorBubble()
                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                            }
                            .padding()
                            .padding(.bottom, 120)
                        }
                                                .scrollDismissesKeyboard(.interactively)
                                                                        .scrollBounceBehavior(.basedOnSize)
                                                                        .onChange(of: messages.count) {
                                                    if let lastMessage = messages.last {
                                                        withAnimation {
                                                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                                        }
                                                    }
                                                }
                    }
                }
                
                Spacer(minLength: 0)
            }
        }
        .safeAreaInset(edge: .bottom) {
            chatInputBar
        }
                .onChange(of: initialPrompt) { oldValue, newValue in
                    if !newValue.isEmpty {
                        messageText = newValue
                        initialPrompt = ""
                        sendMessage()
                    }
                }
                .onChange(of: selectedPhotoItem) { oldValue, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                    let resizedData = resizeImage(uiImage, maxDimension: 1024)
                    await MainActor.run {
                        let attachment = ChatImageAttachment(id: UUID(), imageData: resizedData, previewImage: uiImage)
                        attachedImages.append(attachment)
                        selectedPhotoItem = nil
                    }
                }
            }
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhotoItem, matching: .images)
        .fullScreenCover(isPresented: $showingCamera) {
            ChatCameraView(onImageCaptured: { imageData in
                if let uiImage = UIImage(data: imageData) {
                    let resizedData = resizeImage(uiImage, maxDimension: 1024)
                    let attachment = ChatImageAttachment(id: UUID(), imageData: resizedData, previewImage: uiImage)
                    attachedImages.append(attachment)
                }
            })
        }
        .sheet(isPresented: $showingChatHistory) {
            ChatHistoryView(onSelectConversation: { selectedConversationId, loadedMessages in
                withAnimation {
                    conversationId = selectedConversationId
                    messages = loadedMessages
                    showCloseButton = true
                    attachedImages = []
                }
            })
                .environmentObject(appState)
        }
                .buttonStyle(.plain)
                .onboardingTooltip(
            key: .aiChat,
            message: "Ask Petly AI anything about your pet's health, nutrition, or training. You can also attach photos!",
            icon: "bubble.left.and.bubble.right.fill"
        )
    }
    
        private var chatInputBar: some View {
        VStack(spacing: 0) {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.petlyBody(12))
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
            }
            
            if !attachedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(attachedImages) { attachment in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: attachment.previewImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                Button(action: {
                                    withAnimation {
                                        attachedImages.removeAll { $0.id == attachment.id }
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color.petlyLightGreen.opacity(0.5))
            }
            
            HStack(spacing: 8) {
                Menu {
                    Button(action: { showingCamera = true }) {
                        Label("Take Photo", systemImage: "camera")
                    }
                    Button(action: { showingImagePicker = true }) {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.petlyDarkGreen)
                }
                
                TextField("Start A Conversation...", text: $messageText, axis: .vertical)
                    .font(.petlyBody(14))
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.petlyLightGreen)
                    .cornerRadius(25)
                    .lineLimit(1...5)
                    .focused($isTextFieldFocused)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor((messageText.isEmpty && attachedImages.isEmpty) ? .petlyFormIcon : .petlyDarkGreen)
                }
                .disabled((messageText.isEmpty && attachedImages.isEmpty) || isLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .padding(.bottom, keyboardObserver.keyboardHeight > 0 ? max((keyboardObserver.keyboardHeight - keyboardObserver.safeAreaBottom) * 0.3, 0) : inputBarDefaultPadding)
            .background(Color.petlyBackground)
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> Data {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        
        if ratio >= 1 {
            return image.jpegData(compressionQuality: 0.7) ?? Data()
        }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage?.jpegData(compressionQuality: 0.7) ?? Data()
    }
    
    private func handleQuickAction(_ action: String) {
        messageText = action
        sendMessage()
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty || !attachedImages.isEmpty else { return }
        
        // Prevent duplicate conversations: if we're already creating a conversation, wait for it
        // This fixes the issue where rapid message sends create multiple conversations
        if conversationId == nil && isCreatingConversation {
            print("[NewChatView] Blocked duplicate conversation creation - already in progress")
            return
        }
        
        // Haptic feedback when sending
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        let imageCount = attachedImages.count
        let displayContent = messageText.isEmpty && imageCount > 0 
            ? "[Sent \(imageCount) image\(imageCount > 1 ? "s" : "")]" 
            : messageText
        
        let currentImageData = attachedImages.map { $0.imageData }
        
        let userMessage = Message(
            id: UUID().uuidString,
            conversationId: conversationId ?? "",
            role: .user,
            content: displayContent,
            timestamp: Date(),
            feedback: nil,
            imageData: currentImageData.isEmpty ? nil : currentImageData
        )
        
        messages.append(userMessage)
        let currentMessage = messageText
        let currentImages = attachedImages.map { $0.base64String }
        let currentConversationId = conversationId
        messageText = ""
        attachedImages = []
        isLoading = true
        errorMessage = nil
        showCloseButton = true
        
        // Mark that we're creating a conversation if we don't have one yet
        if currentConversationId == nil {
            isCreatingConversation = true
        }
        
        Task {
            do {
                let dogProfile = buildDogProfile()
                let healthLogs = buildHealthLogs()
                
                                                                                                                // Validate dogId is a valid UUID before sending
                                                                // Don't send test dog IDs that don't exist in the database
                                                                let validDogId: String? = {
                                                                    guard let id = appState.currentDog?.id else { return nil }
                                                                    // Skip test dog IDs that would fail foreign key constraint
                                                                    if id.hasPrefix("00000000-0000-") { return nil }
                                                                    return UUID(uuidString: id) != nil ? id : nil
                                                                }()
                
                                                // Validate conversationId is a valid UUID before sending
                                                let validConversationId: String? = {
                                                    guard let id = currentConversationId else { return nil }
                                                    return UUID(uuidString: id) != nil ? id : nil
                                                }()
                
                                                // Ensure message is not empty (trim whitespace)
                                                let messageToSend = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                                                let finalMessage = messageToSend.isEmpty ? "What do you see in this image?" : messageToSend
                
                                                let response = try await APIService.shared.sendChatMessage(
                                                    message: finalMessage,
                                                    conversationId: validConversationId,
                                                    dogId: validDogId,
                                                    dogProfile: dogProfile,
                                                    healthLogs: healthLogs,
                                                    images: currentImages.isEmpty ? nil : currentImages
                                                )
                
                await MainActor.run {
                    conversationId = response.conversationId
                    isCreatingConversation = false
                    
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
                    isCreatingConversation = false
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
    
    private func shouldShowDateHeader(for index: Int) -> Bool {
        guard index < messages.count else { return false }
        let message = messages[index]
        
        if index == 0 { return true }
        
        let previousMessage = messages[index - 1]
        let calendar = Calendar.current
        
        return !calendar.isDate(message.timestamp, inSameDayAs: previousMessage.timestamp)
    }
}

struct EmptyStateChatView: View {
    @EnvironmentObject var appState: AppState
    let onQuickAction: (String) -> Void
    
        private var userName: String {
            if let fullName = appState.currentUser?.fullName, !fullName.isEmpty {
                return fullName.components(separatedBy: " ").first ?? fullName
            }
            if let savedName = UserDefaults.standard.string(forKey: "ownerName"), !savedName.isEmpty {
                return savedName.components(separatedBy: " ").first ?? savedName
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
    @State private var showCopiedFeedback = false
    
    @ScaledMetric(relativeTo: .body) private var bubbleMaxWidth: CGFloat = 280
    @ScaledMetric(relativeTo: .body) private var avatarSize: CGFloat = 32
    @ScaledMetric(relativeTo: .body) private var imageSize: CGFloat = 120
    
    private var isUser: Bool { message.role == .user }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser {
                Spacer(minLength: 50)
            } else {
                aiAvatar
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                combinedBubble
                
                HStack(spacing: 4) {
                    Text(message.timestamp, style: .time)
                        .font(.petlyBody(10))
                        .foregroundColor(.petlyFormIcon)
                    
                    if showCopiedFeedback {
                        Text("Copied!")
                            .font(.petlyBody(10))
                            .foregroundColor(.petlyDarkGreen)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
            }
            .frame(maxWidth: min(bubbleMaxWidth, 320), alignment: isUser ? .trailing : .leading)
            
            if !isUser {
                Spacer(minLength: 50)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }
    
    @ViewBuilder
    private var combinedBubble: some View {
        let hasImages = message.imageData != nil && !message.imageData!.isEmpty
        let hasText = !message.content.isEmpty && !message.content.starts(with: "[Sent")
        let bubbleColor = isUser ? Color.petlyDarkGreen : Color.petlyLightGreen
        
        VStack(alignment: .leading, spacing: 0) {
            if hasImages, let images = message.imageData {
                imageContent(images: images, hasTextBelow: hasText, bubbleColor: bubbleColor)
            }
            
            if hasText {
                Text(message.content)
                    .font(.petlyBody(15))
                    .foregroundColor(isUser ? .white : .petlyDarkGreen)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
        }
        .background(bubbleColor)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .contextMenu {
            Button(action: copyMessage) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            ShareLink(item: message.content) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }
    
    @ViewBuilder
    private func imageContent(images: [Data], hasTextBelow: Bool, bubbleColor: Color) -> some View {
        VStack(spacing: 2) {
            ForEach(Array(images.enumerated()), id: \.offset) { index, imageData in
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: 220)
                        .frame(height: 160)
                        .clipped()
                }
            }
        }
        .padding(.bottom, hasTextBelow ? 6 : 0)
    }
    
    private var aiAvatar: some View {
        Circle()
            .fill(Color.petlyDarkGreen)
            .frame(width: avatarSize, height: avatarSize)
            .overlay(
                Image(systemName: "sparkles")
                    .font(.system(size: avatarSize * 0.5))
                    .foregroundColor(.white)
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var messageBubble: some View {
        Text(message.content)
            .font(.petlyBody(15))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isUser ? Color.petlyDarkGreen : Color.petlyLightGreen)
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            )
            .foregroundColor(isUser ? .white : .petlyDarkGreen)
            .contextMenu {
                Button(action: copyMessage) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                
                ShareLink(item: message.content) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
    }
    
    private func copyMessage() {
        UIPasteboard.general.string = message.content
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showCopiedFeedback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.2)) {
                showCopiedFeedback = false
            }
        }
    }
}

struct MessageDateHeader: View {
    let date: Date
    
    private var dateText: String {
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
    
    var body: some View {
        Text(dateText)
            .font(.petlyBody(12))
            .fontWeight(.medium)
            .foregroundColor(.petlyFormIcon)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.petlyLightGreen.opacity(0.5))
            )
    }
}

struct TypingIndicatorBubble: View {
    @State private var appeared = false
    @ScaledMetric(relativeTo: .body) private var avatarSize: CGFloat = 32
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            aiAvatar
            
            HStack(spacing: 6) {
                LoadingDotsView()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.petlyLightGreen)
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            )
            
            Spacer(minLength: 50)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }
    
    private var aiAvatar: some View {
        Circle()
            .fill(Color.petlyDarkGreen)
            .frame(width: avatarSize, height: avatarSize)
            .overlay(
                Image(systemName: "sparkles")
                    .font(.system(size: avatarSize * 0.5))
                    .foregroundColor(.white)
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct ChatImageAttachment: Identifiable {
    let id: UUID
    let imageData: Data
    let previewImage: UIImage
    
    var base64String: String {
        imageData.base64EncodedString()
    }
}

struct ChatCameraView: UIViewControllerRepresentable {
    let onImageCaptured: (Data) -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ChatCameraView
        
        init(_ parent: ChatCameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.8) {
                parent.onImageCaptured(data)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    NewChatView()
        .environmentObject(AppState())
}
