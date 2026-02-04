import SwiftUI
import SwiftData
import PhotosUI
import Combine

class KeyboardObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    @Published var isKeyboardVisible: Bool = false
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
            .compactMap { notification -> CGFloat? in
                guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return nil
                }
                return frame.height
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] height in
                withAnimation(.spring(response: 0.25, dampingFraction: 1.0)) {
                    self?.keyboardHeight = height
                    self?.isKeyboardVisible = true
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                withAnimation(.spring(response: 0.25, dampingFraction: 1.0)) {
                    self?.keyboardHeight = 0
                    self?.isKeyboardVisible = false
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
    @State private var isLoadingHistory = false
    @State private var isCreatingConversation = false
    @State private var conversationId: String?
    @State private var errorMessage: String?
    @State private var showCloseButton = false
    @State private var attachedImages: [ChatImageAttachment] = []
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingChatHistory = false
    @State private var showingPetSwitcher = false
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
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
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
                                    Text("Chats")
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
                            Button(action: { showingPetSwitcher = true }) {
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
                    }
                    .padding()
                    
                    if isLoadingHistory {
                        VStack(spacing: 16) {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading conversation...")
                                .font(.petlyBody(14))
                                .foregroundColor(.petlyFormIcon)
                            Spacer()
                        }
                    } else if messages.isEmpty {
                        ScrollView {
                            EmptyStateChatView(onQuickAction: handleQuickAction)
                                .padding(.bottom, keyboardObserver.isKeyboardVisible ? max(keyboardObserver.keyboardHeight - geometry.safeAreaInsets.bottom, 0) + 80 : 150)
                        }
                        .scrollDismissesKeyboard(.immediately)
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 10, coordinateSpace: .local)
                                .onChanged { value in
                                    if value.translation.height > 20 {
                                        dismissKeyboard()
                                    }
                                }
                        )
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
                                            NewMessageBubble(
                                                message: message,
                                                onFeedback: { feedback in
                                                    handleMessageFeedback(messageId: message.id, feedback: feedback)
                                                },
                                                onLogSuggestion: { logType, details in
                                                    handleLogSuggestion(logType: logType, details: details)
                                                },
                                                onReminderSuggestion: { title, time in
                                                    handleReminderSuggestion(title: title, time: time)
                                                },
                                                onWeightUpdate: { newWeight in
                                                    handleWeightUpdate(newWeight: newWeight)
                                                }
                                            )
                                        }
                                        .id(message.id)
                                    }
                                    
                                    if isLoading {
                                        TypingIndicatorBubble()
                                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                                    }
                                    
                                }
                                .padding()
                                .padding(.bottom, keyboardObserver.isKeyboardVisible ? max(keyboardObserver.keyboardHeight - geometry.safeAreaInsets.bottom, 0) + 80 : 150)
                            }
                            .scrollDismissesKeyboard(.immediately)
                            .scrollBounceBehavior(.basedOnSize)
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 10, coordinateSpace: .local)
                                    .onChanged { value in
                                        if value.translation.height > 20 {
                                            dismissKeyboard()
                                        }
                                    }
                            )
                            .onChange(of: messages.count) {
                                if let lastMessage = messages.last {
                                    withAnimation {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            }
                            .onChange(of: conversationId) {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    if let lastMessage = messages.last {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            }
                            .onAppear {
                                if let lastMessage = messages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                
                chatInputBar
                    .padding(.bottom, keyboardObserver.isKeyboardVisible ? max(keyboardObserver.keyboardHeight - geometry.safeAreaInsets.bottom, 0) : inputBarDefaultPadding)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
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
            ChatHistoryView(onSelectConversation: { selectedConversationId, _ in
                withAnimation {
                    conversationId = selectedConversationId
                    messages = []
                    showCloseButton = true
                    attachedImages = []
                    isLoadingHistory = true
                }
                Task {
                    do {
                        let loadedMessages = try await APIService.shared.getConversationMessages(conversationId: selectedConversationId)
                        await MainActor.run {
                            withAnimation {
                                messages = loadedMessages
                                isLoadingHistory = false
                            }
                        }
                    } catch {
                        await MainActor.run {
                            isLoadingHistory = false
                            errorMessage = "Failed to load messages"
                        }
                    }
                }
            })
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingPetSwitcher) {
            PetSwitcherView()
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
            allergies: dog.allergies.isEmpty ? nil : dog.allergies,
            energyLevel: dog.energyLevel,
            friendliness: dog.friendliness,
            trainability: dog.trainability,
            personalityTraits: dog.personalityTraits?.isEmpty == true ? nil : dog.personalityTraits,
            feedingSchedule: dog.feedingSchedule,
            foodType: dog.foodType,
            portionSize: dog.portionSize,
            foodAllergies: dog.foodAllergies,
            sex: dog.sex,
            isNeutered: dog.isNeutered,
            medicalHistory: dog.medicalHistory,
            currentMedications: dog.currentMedications
        )
    }
    
    private func buildHealthLogs()-> [ChatHealthLog]? {
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
    
    private func handleMessageFeedback(messageId: String, feedback: MessageFeedback) {
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            messages[index].feedback = feedback
        }
    }
    
    private func handleLogSuggestion(logType: String, details: String) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        guard let dogId = appState.currentDog?.id else { return }
        
        // Capitalize first letter to match LogType enum values (e.g., "Meals", "Walk", "Water")
        // AI may generate "meals" or "Meals" - normalize to match the app's LogType enum
        var normalizedLogType = logType.prefix(1).uppercased() + logType.dropFirst().lowercased()
        
        // FALLBACK CATEGORIZATION: If AI outputs "Note" or "Notes", try to auto-categorize based on keywords in details
        if normalizedLogType == "Note" || normalizedLogType == "Notes" {
            normalizedLogType = inferLogTypeFromDetails(details)
        }
        
        // Parse duration from details for Walk/Playtime logs (e.g., "30 min walk", "2 hour 20 min walk", "3-hour walk")
        var duration: String? = nil
        if normalizedLogType == "Walk" || normalizedLogType == "Playtime" {
            // Try to extract duration from details - supports combined formats like "2 hour 20 min"
            // Pattern matches: "30 min", "30min", "3-hour", "3 hour", "3hour", "2 hour 20 min"
            let durationPattern = #"(\d+)[\s\-]*(min|minute|minutes|hr|hour|hours)"#
            if let regex = try? NSRegularExpression(pattern: durationPattern, options: .caseInsensitive) {
                let matches = regex.matches(in: details, options: [], range: NSRange(details.startIndex..., in: details))
                
                if !matches.isEmpty {
                    var totalMinutes = 0
                    
                    for match in matches {
                        if let numberRange = Range(match.range(at: 1), in: details),
                           let unitRange = Range(match.range(at: 2), in: details) {
                            let number = Int(details[numberRange]) ?? 0
                            let unit = details[unitRange].lowercased()
                            // Convert hours to minutes, add minutes directly
                            if unit.contains("hr") || unit.contains("hour") {
                                totalMinutes += number * 60
                            } else {
                                totalMinutes += number
                            }
                        }
                    }
                    
                    duration = "\(totalMinutes)"
                } else {
                    // Default to 30 minutes if no duration specified
                    duration = "30"
                }
            } else {
                // Default to 30 minutes if regex fails
                duration = "30"
            }
        }
        
        // Set type-specific fields based on log type
        var groomingType: String? = nil
        var moodLevel: Int? = nil
        var activityType: String? = nil
        var symptomType: String? = nil
        var severityLevel: Int? = nil
        var waterAmount: String? = nil
        var digestionQuality: String? = nil
        var supplementName: String? = nil
        var dosage: String? = nil
        var appointmentType: String? = nil
        var treatName: String? = nil
        var mealType: String? = nil
        var amount: String? = nil
        
        switch normalizedLogType {
        case "Grooming":
            groomingType = details
        case "Mood":
            // Try to determine mood level from details
            let lowercasedDetails = details.lowercased()
            if lowercasedDetails.contains("great") || lowercasedDetails.contains("amazing") || lowercasedDetails.contains("excellent") || lowercasedDetails.contains("super") {
                moodLevel = 4 // Great
            } else if lowercasedDetails.contains("good") || lowercasedDetails.contains("happy") || lowercasedDetails.contains("energetic") {
                moodLevel = 3 // Good
            } else if lowercasedDetails.contains("okay") || lowercasedDetails.contains("normal") || lowercasedDetails.contains("fine") {
                moodLevel = 2 // Okay
            } else if lowercasedDetails.contains("down") || lowercasedDetails.contains("tired") || lowercasedDetails.contains("low") {
                moodLevel = 1 // Down
            } else if lowercasedDetails.contains("sad") || lowercasedDetails.contains("lethargic") || lowercasedDetails.contains("depressed") {
                moodLevel = 0 // Sad
            } else {
                moodLevel = 3 // Default to Good
            }
        case "Playtime":
            activityType = details
        case "Symptom":
            symptomType = details
            // Try to determine severity from details
            let lowercasedDetails = details.lowercased()
            if lowercasedDetails.contains("severe") || lowercasedDetails.contains("serious") || lowercasedDetails.contains("emergency") {
                severityLevel = 5
            } else if lowercasedDetails.contains("moderate") || lowercasedDetails.contains("concerning") {
                severityLevel = 3
            } else if lowercasedDetails.contains("mild") || lowercasedDetails.contains("minor") || lowercasedDetails.contains("slight") {
                severityLevel = 1
            } else {
                severityLevel = 2 // Default to mild-moderate
            }
        case "Water":
            waterAmount = details
        case "Digestion":
            digestionQuality = details
        case "Supplements":
            supplementName = details
        case "Appointments":
            appointmentType = details
        case "Treat":
            treatName = details
        case "Meals":
            // Extract meal type (Breakfast/Lunch/Dinner) from details
            let lowercasedDetails = details.lowercased()
            if lowercasedDetails.contains("breakfast") {
                mealType = "Breakfast"
            } else if lowercasedDetails.contains("lunch") {
                mealType = "Lunch"
            } else if lowercasedDetails.contains("dinner") {
                mealType = "Dinner"
            } else {
                // Default based on time of day
                let hour = Calendar.current.component(.hour, from: Date())
                if hour < 11 {
                    mealType = "Breakfast"
                } else if hour < 16 {
                    mealType = "Lunch"
                } else {
                    mealType = "Dinner"
                }
            }
        default:
            break
        }
        
        let logEntry = HealthLogEntry(
            dogId: dogId,
            logType: normalizedLogType,
            timestamp: Date(),
            notes: details,
            mealType: mealType,
            amount: amount,
            duration: duration,
            moodLevel: moodLevel,
            symptomType: symptomType,
            severityLevel: severityLevel,
            digestionQuality: digestionQuality,
            activityType: activityType,
            supplementName: supplementName,
            dosage: dosage,
            appointmentType: appointmentType,
            groomingType: groomingType,
            treatName: treatName,
            waterAmount: waterAmount
        )
        
        modelContext.insert(logEntry)
        try? modelContext.save()
    }
    
    private func handleReminderSuggestion(title: String, time: String) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        guard let dogId = appState.currentDog?.id else { return }
        
        let reminderDate = parseReminderTime(time)
        
        let reminder = PetReminder(
            dogId: dogId,
            title: title,
            reminderType: .other,
            frequency: .once,
            nextDueDate: reminderDate,
            notes: "Created from chat"
        )
        
        modelContext.insert(reminder)
        try? modelContext.save()
        
        NotificationManager.shared.scheduleReminderNotification(for: reminder)
    }
    
    private func parseReminderTime(_ timeString: String) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        let lowercased = timeString.lowercased()
        if lowercased.contains("tomorrow") {
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.day! += 1
            
            if let timeMatch = lowercased.range(of: #"\d{1,2}:\d{2}"#, options: .regularExpression) {
                let timePart = String(lowercased[timeMatch])
                let parts = timePart.split(separator: ":")
                if parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) {
                    var adjustedHour = hour
                    if lowercased.contains("pm") && hour < 12 { adjustedHour += 12 }
                    if lowercased.contains("am") && hour == 12 { adjustedHour = 0 }
                    components.hour = adjustedHour
                    components.minute = minute
                }
            } else {
                components.hour = 9
                components.minute = 0
            }
            
            return calendar.date(from: components) ?? now.addingTimeInterval(86400)
        }
        
        if let timeMatch = lowercased.range(of: #"\d{1,2}:\d{2}"#, options: .regularExpression) {
            let timePart = String(lowercased[timeMatch])
            let parts = timePart.split(separator: ":")
            if parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) {
                var adjustedHour = hour
                if lowercased.contains("pm") && hour < 12 { adjustedHour += 12 }
                if lowercased.contains("am") && hour == 12 { adjustedHour = 0 }
                
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                components.hour = adjustedHour
                components.minute = minute
                
                if let date = calendar.date(from: components), date > now {
                    return date
                } else {
                    components.day! += 1
                    return calendar.date(from: components) ?? now.addingTimeInterval(3600)
                }
            }
        }
        
        return now.addingTimeInterval(3600)
    }
    
    private func handleWeightUpdate(newWeight: Double) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        guard var dog = appState.currentDog else { return }
        
        // Update the dog's profile weight
        dog.weight = newWeight
        appState.currentDog = dog
        
        // Also add a weight entry to track history
        let weightEntry = WeightEntry(
            weight: newWeight,
            date: Date(),
            note: "Updated via AI chat"
        )
        WeightTrackingManager.shared.addEntry(weightEntry)
    }
    
    /// Infers the proper log type from details when AI outputs "Note" instead of a specific type
    private func inferLogTypeFromDetails(_ details: String) -> String {
        let lowercased = details.lowercased()
        
        // Grooming keywords
        if lowercased.contains("bath") || lowercased.contains("brush") || lowercased.contains("groom") ||
           lowercased.contains("nail") || lowercased.contains("haircut") || lowercased.contains("ear clean") ||
           lowercased.contains("teeth clean") || lowercased.contains("fur") || lowercased.contains("coat") {
            return "Grooming"
        }
        
        // Mood keywords
        if lowercased.contains("mood") || lowercased.contains("happy") || lowercased.contains("sad") ||
           lowercased.contains("energetic") || lowercased.contains("energized") || lowercased.contains("tired") ||
           lowercased.contains("anxious") || lowercased.contains("calm") || lowercased.contains("playful") ||
           lowercased.contains("excited") || lowercased.contains("lethargic") || lowercased.contains("depressed") {
            return "Mood"
        }
        
        // Walk keywords
        if lowercased.contains("walk") || lowercased.contains("stroll") || lowercased.contains("hike") {
            return "Walk"
        }
        
        // Playtime keywords
        if lowercased.contains("play") || lowercased.contains("fetch") || lowercased.contains("tug") ||
           lowercased.contains("zoomies") || lowercased.contains("running around") {
            return "Playtime"
        }
        
        // Treat keywords
        if lowercased.contains("treat") || lowercased.contains("snack") || lowercased.contains("reward") ||
           lowercased.contains("biscuit") || lowercased.contains("chew") {
            return "Treat"
        }
        
        // Meals keywords
        if lowercased.contains("food") || lowercased.contains("fed") || lowercased.contains("feeding") ||
           lowercased.contains("breakfast") || lowercased.contains("lunch") || lowercased.contains("dinner") ||
           lowercased.contains("ate") || lowercased.contains("eating") || lowercased.contains("meal") {
            return "Meals"
        }
        
        // Water keywords
        if lowercased.contains("water") || lowercased.contains("drinking") || lowercased.contains("hydration") ||
           lowercased.contains("drank") {
            return "Water"
        }
        
        // Symptom keywords
        if lowercased.contains("vomit") || lowercased.contains("diarrhea") || lowercased.contains("cough") ||
           lowercased.contains("sneez") || lowercased.contains("limp") || lowercased.contains("scratch") ||
           lowercased.contains("sick") || lowercased.contains("pain") || lowercased.contains("swell") {
            return "Symptom"
        }
        
        // Digestion keywords
        if lowercased.contains("poop") || lowercased.contains("pee") || lowercased.contains("bowel") ||
           lowercased.contains("urination") || lowercased.contains("stool") || lowercased.contains("potty") {
            return "Digestion"
        }
        
        // Supplements keywords
        if lowercased.contains("vitamin") || lowercased.contains("supplement") || lowercased.contains("probiotic") ||
           lowercased.contains("fish oil") || lowercased.contains("joint supplement") {
            return "Supplements"
        }
        
        // Medication keywords
        if lowercased.contains("medicine") || lowercased.contains("medication") || lowercased.contains("pill") ||
           lowercased.contains("dose") || lowercased.contains("prescription") {
            return "Medication"
        }
        
        // Appointments keywords
        if lowercased.contains("vet") || lowercased.contains("appointment") || lowercased.contains("checkup") ||
           lowercased.contains("vaccination") {
            return "Appointments"
        }
        
        // Default to Notes if no match found
        return "Notes"
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
    var onFeedback: ((MessageFeedback) -> Void)?
    var onLogSuggestion: ((String, String) -> Void)?
    var onReminderSuggestion: ((String, String) -> Void)?
    var onWeightUpdate: ((Double) -> Void)?
    @State private var appeared = false
    @State private var showCopiedFeedback = false
    @State private var showFeedbackThanks = false
    @State private var currentFeedback: MessageFeedback?
    @State private var dismissedLogSuggestionIndices: Set<Int> = []
    @State private var reminderCreated = false
    @State private var weightUpdated = false
    
    private var dismissedSuggestionsKey: String {
        "dismissedLogSuggestions_\(message.id)"
    }
    
    private var dismissedReminderKey: String {
        "dismissedReminder_\(message.id)"
    }
    
    @ScaledMetric(relativeTo: .body) private var bubbleMaxWidth: CGFloat = 280
    @ScaledMetric(relativeTo: .body) private var avatarSize: CGFloat = 32
    @ScaledMetric(relativeTo: .body) private var imageSize: CGFloat = 120
    
    private var isUser: Bool { message.role == .user }
    
    private var displayContent: String {
        var content = message.content
        content = content.replacingOccurrences(of: #"\[LOG_SUGGESTION:[^\]]+\]"#, with: "", options: .regularExpression)
        content = content.replacingOccurrences(of: #"\[REMINDER:[^\]]+\]"#, with: "", options: .regularExpression)
        content = content.replacingOccurrences(of: #"\[WEIGHT_UPDATE:[^\]]+\]"#, with: "", options: .regularExpression)
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var logSuggestions: [(type: String, details: String)] {
        var suggestions: [(type: String, details: String)] = []
        let pattern = #"\[LOG_SUGGESTION:([^:]+):([^\]]+)\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let nsString = message.content as NSString
        let results = regex.matches(in: message.content, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in results {
            if match.numberOfRanges == 3 {
                let typeRange = match.range(at: 1)
                let detailsRange = match.range(at: 2)
                let type = nsString.substring(with: typeRange)
                let details = nsString.substring(with: detailsRange)
                suggestions.append((type: type, details: details))
            }
        }
        return suggestions
    }
    
    private var reminderSuggestion: (title: String, time: String)? {
        guard let match = message.content.range(of: #"\[REMINDER:([^:]+):([^\]]+)\]"#, options: .regularExpression) else { return nil }
        let matchStr = String(message.content[match])
        let parts = matchStr.dropFirst(10).dropLast(1).split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else { return nil }
        return (String(parts[0]), String(parts[1]))
    }
    
    private var weightUpdateSuggestion: Double? {
        guard let match = message.content.range(of: #"\[WEIGHT_UPDATE:([^\]]+)\]"#, options: .regularExpression) else { return nil }
        let matchStr = String(message.content[match])
        let valueStr = matchStr.dropFirst(15).dropLast(1) // Remove "[WEIGHT_UPDATE:" and "]"
        return Double(valueStr)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser {
                Spacer(minLength: 50)
            } else {
                aiAvatar
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                combinedBubble
                
                HStack(spacing: 8) {
                    Text(message.timestamp, style: .time)
                        .font(.petlyBody(10))
                        .foregroundColor(.petlyFormIcon)
                    
                    if showCopiedFeedback {
                        Text("Copied!")
                            .font(.petlyBody(10))
                            .foregroundColor(.petlyDarkGreen)
                            .transition(.opacity.combined(with: .scale))
                    }
                    
                    if showFeedbackThanks {
                        Text("Thanks for the feedback!")
                            .font(.petlyBody(10))
                            .foregroundColor(.petlyDarkGreen)
                            .transition(.opacity.combined(with: .scale))
                    }
                    
                    if !isUser {
                        HStack(spacing: 12) {
                            Button(action: copyMessage) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.petlyDarkGreen.opacity(0.7))
                            }
                            .frame(width: 32, height: 32)
                            .background(Color.petlyLightGreen.opacity(0.5))
                            .clipShape(Circle())
                            
                            Button(action: { toggleFeedback(.positive) }) {
                                Image(systemName: currentFeedback == .positive ? "hand.thumbsup.fill" : "hand.thumbsup")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(currentFeedback == .positive ? .white : .petlyDarkGreen.opacity(0.7))
                            }
                            .frame(width: 32, height: 32)
                            .background(currentFeedback == .positive ? Color.petlyDarkGreen : Color.petlyLightGreen.opacity(0.5))
                            .clipShape(Circle())
                            
                            Button(action: { toggleFeedback(.negative) }) {
                                Image(systemName: currentFeedback == .negative ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(currentFeedback == .negative ? .white : .petlyDarkGreen.opacity(0.7))
                            }
                            .frame(width: 32, height: 32)
                            .background(currentFeedback == .negative ? Color.red.opacity(0.8) : Color.petlyLightGreen.opacity(0.5))
                            .clipShape(Circle())
                        }
                        .padding(.leading, 4)
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
            currentFeedback = message.feedback
            
            if let savedIndices = UserDefaults.standard.array(forKey: dismissedSuggestionsKey) as? [Int] {
                dismissedLogSuggestionIndices = Set(savedIndices)
            }
            reminderCreated = UserDefaults.standard.bool(forKey: dismissedReminderKey)
        }
    }
    
    private func toggleFeedback(_ feedback: MessageFeedback) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        let wasAlreadySelected = currentFeedback == feedback
        
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            if wasAlreadySelected {
                currentFeedback = nil
            } else {
                currentFeedback = feedback
                showFeedbackThanks = true
            }
        }
        
        if !wasAlreadySelected {
            onFeedback?(feedback)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showFeedbackThanks = false
                }
            }
        }
    }
    
    @ViewBuilder
    private var combinedBubble: some View {
        let hasImages = message.imageData != nil && !message.imageData!.isEmpty
        let hasText = !displayContent.isEmpty && !displayContent.starts(with: "[Sent")
        let bubbleColor = isUser ? Color.petlyDarkGreen : Color.petlyLightGreen
        
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                if hasImages, let images = message.imageData {
                    imageContent(images: images, hasTextBelow: hasText, bubbleColor: bubbleColor)
                }
                
                if hasText {
                    Text(parseMarkdown(displayContent))
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
                
                ShareLink(item: displayContent) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            
            if !isUser {
                let suggestions = logSuggestions
                ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                    if !dismissedLogSuggestionIndices.contains(index) {
                        LogSuggestionCard(
                            logType: suggestion.type,
                            details: suggestion.details,
                            onLog: {
                                onLogSuggestion?(suggestion.type, suggestion.details)
                                withAnimation { 
                                    dismissedLogSuggestionIndices.insert(index)
                                    UserDefaults.standard.set(Array(dismissedLogSuggestionIndices), forKey: dismissedSuggestionsKey)
                                }
                            },
                            onDismiss: {
                                withAnimation { 
                                    dismissedLogSuggestionIndices.insert(index)
                                    UserDefaults.standard.set(Array(dismissedLogSuggestionIndices), forKey: dismissedSuggestionsKey)
                                }
                            }
                        )
                    }
                }
            }
            
            if !isUser, let reminder = reminderSuggestion, !reminderCreated {
                ReminderSuggestionCard(
                    title: reminder.title,
                    time: reminder.time,
                    onCreate: {
                        onReminderSuggestion?(reminder.title, reminder.time)
                        withAnimation { 
                            reminderCreated = true
                            UserDefaults.standard.set(true, forKey: dismissedReminderKey)
                        }
                    },
                    onDismiss: {
                        withAnimation { 
                            reminderCreated = true
                            UserDefaults.standard.set(true, forKey: dismissedReminderKey)
                        }
                    }
                )
            }
            
            if !isUser, let newWeight = weightUpdateSuggestion, !weightUpdated {
                WeightUpdateCard(
                    weight: newWeight,
                    onUpdate: {
                        onWeightUpdate?(newWeight)
                        withAnimation { weightUpdated = true }
                    },
                    onDismiss: {
                        withAnimation { weightUpdated = true }
                    }
                )
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
    
    private func parseMarkdown(_ text: String) -> AttributedString {
        var result = AttributedString()
        var currentIndex = text.startIndex
        
        while currentIndex < text.endIndex {
            if let boldStart = text[currentIndex...].range(of: "**") {
                if boldStart.lowerBound > currentIndex {
                    let normalText = String(text[currentIndex..<boldStart.lowerBound])
                    result.append(AttributedString(normalText))
                }
                
                let afterBoldStart = boldStart.upperBound
                if afterBoldStart < text.endIndex,
                   let boldEnd = text[afterBoldStart...].range(of: "**") {
                    let boldText = String(text[afterBoldStart..<boldEnd.lowerBound])
                    var boldAttr = AttributedString(boldText)
                    boldAttr.font = .system(size: 15, weight: .semibold)
                    result.append(boldAttr)
                    currentIndex = boldEnd.upperBound
                } else {
                    result.append(AttributedString("**"))
                    currentIndex = afterBoldStart
                }
            } else {
                let remainingText = String(text[currentIndex...])
                result.append(AttributedString(remainingText))
                break
            }
        }
        
        return result
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

struct LogSuggestionCard: View {
    let logType: String
    let details: String
    let onLog: () -> Void
    let onDismiss: () -> Void
    
    private var icon: String {
        switch logType.lowercased() {
        case "symptom": return "heart.text.square"
        case "meals": return "fork.knife"
        case "walk": return "figure.walk"
        case "water": return "drop.fill"
        case "medication": return "pills.fill"
        case "vet visit": return "cross.case.fill"
        default: return "plus.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.petlyDarkGreen)
                .frame(width: 36, height: 36)
                .background(Color.petlyLightGreen)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Log this?")
                    .font(.petlyBodyMedium(12))
                    .foregroundColor(.petlyDarkGreen)
                Text(details)
                    .font(.petlyBody(11))
                    .foregroundColor(.petlyFormIcon)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onLog) {
                Text("Log")
                    .font(.petlyBodyMedium(12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.petlyDarkGreen)
                    .cornerRadius(14)
            }
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.petlyFormIcon)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

struct ReminderSuggestionCard: View {
    let title: String
    let time: String
    let onCreate: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .font(.system(size: 20))
                .foregroundColor(.orange)
                .frame(width: 36, height: 36)
                .background(Color.orange.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Set reminder?")
                    .font(.petlyBodyMedium(12))
                    .foregroundColor(.petlyDarkGreen)
                Text("\(title) at \(time)")
                    .font(.petlyBody(11))
                    .foregroundColor(.petlyFormIcon)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onCreate) {
                Text("Set")
                    .font(.petlyBodyMedium(12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(14)
            }
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.petlyFormIcon)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

struct WeightUpdateCard: View {
    let weight: Double
    var onUpdate: () -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "scalemass.fill")
                .font(.system(size: 20))
                .foregroundColor(.petlyDarkGreen)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Update Weight")
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.petlyDarkGreen)
                Text("Set weight to \(String(format: "%.1f", weight)) lbs")
                    .font(.petlyBody(12))
                    .foregroundColor(.petlyFormIcon)
            }
            
            Spacer()
            
            Button(action: onUpdate) {
                Text("Update")
                    .font(.petlyBodyMedium(13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.petlyDarkGreen)
                    .cornerRadius(8)
            }
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.petlyFormIcon)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NewChatView()
        .environmentObject(AppState())
}
