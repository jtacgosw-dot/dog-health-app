import Foundation

class APIService {
    static let shared = APIService()
    
    private let baseURL = APIConfig.baseURL
    private var authToken: String?
    private var isRefreshingToken = false
    
    private init() {}
    
    func setAuthToken(_ token: String) {
        self.authToken = token
        UserDefaults.standard.set(token, forKey: "authToken")
    }
    
    func getAuthToken() -> String? {
        if let token = authToken {
            return token
        }
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    func clearAuthToken() {
        authToken = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
    }
    
    func setIsGuest(_ isGuest: Bool) {
        UserDefaults.standard.set(isGuest, forKey: "isGuestUser")
    }
    
    func getIsGuest() -> Bool {
        return UserDefaults.standard.bool(forKey: "isGuestUser")
    }
    
    private func refreshTokenIfGuest() async -> Bool {
        guard !isRefreshingToken else { return false }
        guard getIsGuest() else { return false }
        
        isRefreshingToken = true
        defer { isRefreshingToken = false }
        
        do {
            let deviceId = UserDefaults.standard.string(forKey: "guestDeviceId") ?? UUID().uuidString
            let response = try await guestSignIn(deviceId: deviceId)
            setAuthToken(response.token)
            print("[APIService] Token refreshed successfully for guest user")
            return true
        } catch {
            print("[APIService] Token refresh failed: \(error)")
            return false
        }
    }
    
    private func makeRequest<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        requiresAuth: Bool = true,
        isRetry: Bool = false
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth, let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
                guard (200...299).contains(httpResponse.statusCode) else {
                    if let errorBody = String(data: data, encoding: .utf8) {
                        print("[APIService] HTTP \(httpResponse.statusCode) error: \(errorBody)")
                    }
                    if httpResponse.statusCode == 401 && requiresAuth && !isRetry {
                        let refreshed = await refreshTokenIfGuest()
                        if refreshed {
                            return try await makeRequest(endpoint: endpoint, method: method, body: body, requiresAuth: requiresAuth, isRetry: true)
                        }
                    }
                    throw APIError.httpError(statusCode: httpResponse.statusCode)
                }
        
        let decoder = JSONDecoder()
        // Use custom date formatter to handle ISO8601 with fractional seconds (Supabase format)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            // Try with fractional seconds first
            if let date = formatter.date(from: dateString) {
                return date
            }
            // Fall back to standard ISO8601 without fractional seconds
            let standardFormatter = ISO8601DateFormatter()
            if let date = standardFormatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        return try decoder.decode(T.self, from: data)
    }
    
        func signInWithApple(identityToken: String, authorizationCode: String, fullName: String?) async throws -> AuthResponse {
            let body = SignInRequest(
                identityToken: identityToken,
                authorizationCode: authorizationCode,
                fullName: fullName
            )
            let data = try JSONEncoder().encode(body)
            return try await makeRequest(endpoint: "/auth/apple", method: "POST", body: data, requiresAuth: false)
        }
    
        func devSignIn() async throws -> DevAuthResponse {
            return try await makeRequest(endpoint: "/auth/dev", method: "POST", body: nil, requiresAuth: false)
        }
    
        func guestSignIn(deviceId: String? = nil) async throws -> GuestAuthResponse {
            let body = GuestSignInRequest(deviceId: deviceId ?? UUID().uuidString)
            let data = try JSONEncoder().encode(body)
            return try await makeRequest(endpoint: "/auth/guest", method: "POST", body: data, requiresAuth: false)
        }
    
        func ensureDevAuthenticated() async {
            #if DEBUG
            if getAuthToken() == nil {
                do {
                    let response = try await devSignIn()
                    setAuthToken(response.token)
                    print("Dev auth: Automatically signed in as \(response.user.email)")
                } catch {
                    print("Dev auth failed: \(error)")
                }
            }
            #endif
        }
    
                func sendChatMessage(message: String, conversationId: String?, dogId: String?, dogProfile: ChatDogProfile?, healthLogs: [ChatHealthLog]?, images: [String]? = nil) async throws -> ChatResponse {
                    let body = ChatRequest(message: message, conversationId: conversationId, dogId: dogId, dogProfile: dogProfile, healthLogs: healthLogs, images: images)
                    let data = try JSONEncoder().encode(body)
                    #if DEBUG
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("[APIService] sendChatMessage request: \(jsonString)")
                    }
                    #endif
                    return try await makeRequest(endpoint: "/chat", method: "POST", body: data)
                }
    
    func getConversations() async throws -> [Conversation] {
        let response: ConversationsResponse = try await makeRequest(endpoint: "/chat/conversations")
        return response.conversations.map { $0.toConversation() }
    }
    
    func getConversationMessages(conversationId: String) async throws -> [Message] {
        let response: ConversationMessagesResponse = try await makeRequest(endpoint: "/chat/conversations/\(conversationId)/messages")
        
        // Create formatter with fractional seconds support (matches server format)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let standardFormatter = ISO8601DateFormatter()
        standardFormatter.formatOptions = [.withInternetDateTime]
        
        return response.messages.map { serverMsg in
            // Try fractional seconds first, then fall back to standard
            let timestamp = formatter.date(from: serverMsg.createdAt) 
                ?? standardFormatter.date(from: serverMsg.createdAt) 
                ?? Date()
            
            return Message(
                id: serverMsg.id,
                conversationId: conversationId,
                role: serverMsg.role == "user" ? .user : .assistant,
                content: serverMsg.content,
                timestamp: timestamp,
                feedback: serverMsg.feedback.flatMap { MessageFeedback(rawValue: $0) }
            )
        }
    }
    
    func deleteConversation(conversationId: String) async throws {
        let _: DeleteResponse = try await makeRequest(endpoint: "/chat/conversations/\(conversationId)", method: "DELETE")
    }
    
    func renameConversation(conversationId: String, title: String) async throws {
        let body = ["title": title]
        let data = try JSONEncoder().encode(body)
        let _: ConversationUpdateResponse = try await makeRequest(endpoint: "/chat/conversations/\(conversationId)", method: "PATCH", body: data)
    }
    
    func updateConversation(conversationId: String, isPinned: Bool? = nil, isArchived: Bool? = nil) async throws {
        var body: [String: Any] = [:]
        if let isPinned = isPinned { body["is_pinned"] = isPinned }
        if let isArchived = isArchived { body["is_archived"] = isArchived }
        let data = try JSONSerialization.data(withJSONObject: body)
        let _: ConversationUpdateResponse = try await makeRequest(endpoint: "/chat/conversations/\(conversationId)", method: "PATCH", body: data)
    }
    
    func getDogs() async throws -> [Dog] {
        let response: DogsResponse = try await makeRequest(endpoint: "/dogs")
        return response.dogs
    }
    
    func createDog(dog: Dog) async throws -> Dog {
        let data = try JSONEncoder().encode(dog)
        let response: DogResponse = try await makeRequest(endpoint: "/dogs", method: "POST", body: data)
        return response.dog
    }
    
    func updateDog(dog: Dog) async throws -> Dog {
        let data = try JSONEncoder().encode(dog)
        let response: DogResponse = try await makeRequest(endpoint: "/dogs/\(dog.id)", method: "PUT", body: data)
        return response.dog
    }
    
    func checkEntitlements() async throws -> EntitlementsResponse {
        return try await makeRequest(endpoint: "/entitlements")
    }
    
    // MARK: - Health Logs
    
    func getHealthLogs(dogId: String, since: Date? = nil) async throws -> HealthLogsResponse {
        var endpoint = "/health-logs?dogId=\(dogId)"
        if let since = since {
            let formatter = ISO8601DateFormatter()
            endpoint += "&since=\(formatter.string(from: since))"
        }
        return try await makeRequest(endpoint: endpoint)
    }
    
    func createHealthLog(log: HealthLogRequest) async throws -> HealthLogResponse {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(log)
        return try await makeRequest(endpoint: "/health-logs", method: "POST", body: data)
    }
    
    func syncHealthLogs(dogId: String, lastSyncAt: Date?, localLogs: [HealthLogRequest]) async throws -> HealthLogSyncResponse {
        var body: [String: Any] = ["dogId": dogId, "localLogs": []]
        
        if let lastSyncAt = lastSyncAt {
            let formatter = ISO8601DateFormatter()
            body["lastSyncAt"] = formatter.string(from: lastSyncAt)
        }
        
        // Convert local logs to dictionaries
        let logsArray = localLogs.map { log -> [String: Any?] in
            var dict: [String: Any?] = [
                "dogId": log.dogId,
                "logType": log.logType,
                "clientId": log.clientId
            ]
            
            let formatter = ISO8601DateFormatter()
            dict["timestamp"] = formatter.string(from: log.timestamp)
            
            if let notes = log.notes { dict["notes"] = notes }
            if let mealType = log.mealType { dict["mealType"] = mealType }
            if let amount = log.amount { dict["amount"] = amount }
            if let duration = log.duration { dict["duration"] = duration }
            if let moodLevel = log.moodLevel { dict["moodLevel"] = moodLevel }
            if let symptomType = log.symptomType { dict["symptomType"] = symptomType }
            if let severityLevel = log.severityLevel { dict["severityLevel"] = severityLevel }
            if let digestionQuality = log.digestionQuality { dict["digestionQuality"] = digestionQuality }
            if let activityType = log.activityType { dict["activityType"] = activityType }
            if let supplementName = log.supplementName { dict["supplementName"] = supplementName }
            if let dosage = log.dosage { dict["dosage"] = dosage }
            if let appointmentType = log.appointmentType { dict["appointmentType"] = appointmentType }
            if let location = log.location { dict["location"] = location }
            if let groomingType = log.groomingType { dict["groomingType"] = groomingType }
            if let treatName = log.treatName { dict["treatName"] = treatName }
            if let waterAmount = log.waterAmount { dict["waterAmount"] = waterAmount }
            
            return dict
        }
        body["localLogs"] = logsArray
        
        let data = try JSONSerialization.data(withJSONObject: body)
        return try await makeRequest(endpoint: "/health-logs/sync", method: "POST", body: data)
    }
    
    func deleteHealthLog(id: String) async throws -> DeleteResponse {
        return try await makeRequest(endpoint: "/health-logs/\(id)", method: "DELETE")
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    case networkError(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL. Please try again."
        case .invalidResponse:
            return "Invalid response from server. Please try again."
        case .httpError(let statusCode):
            switch statusCode {
            case 401:
                return "Authentication required. Please sign in again."
            case 403:
                return "Access denied. Please check your subscription."
            case 404:
                return "Service not found. Please try again later."
            case 500...599:
                return "Server error. Please try again later."
            default:
                return "Request failed (error \(statusCode)). Please try again."
            }
        case .decodingError:
            return "Failed to process server response. Please try again."
        case .networkError(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        }
    }
}

struct SignInRequest: Codable {
    let identityToken: String
    let authorizationCode: String
    let fullName: String?
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct DevAuthResponse: Codable {
    let success: Bool
    let token: String
    let user: DevUser
}

struct DevUser: Codable {
    let id: String
    let email: String
    let fullName: String?
    let subscriptionStatus: String?
}

struct GuestSignInRequest: Codable {
    let deviceId: String
}

struct GuestAuthResponse: Codable {
    let success: Bool
    let token: String
    let user: GuestUser
}

struct GuestUser: Codable {
    let id: String
    let email: String
    let fullName: String?
    let subscriptionStatus: String?
}

struct ChatRequest: Codable {
    let message: String
    let conversationId: String?
    let dogId: String?
    let dogProfile: ChatDogProfile?
    let healthLogs: [ChatHealthLog]?
    let images: [String]?
}

struct ChatDogProfile: Codable {
    let name: String
    let breed: String?
    let age: Double?
    let weight: Double?
    let healthConcerns: [String]?
    let allergies: [String]?
    
    // Personality fields
    let energyLevel: Int?
    let friendliness: Int?
    let trainability: Int?
    let personalityTraits: [String]?
    
    // Nutrition fields
    let feedingSchedule: String?
    let foodType: String?
    let portionSize: String?
    let foodAllergies: String?
    
    // Medical fields
    let sex: String?
    let isNeutered: Bool?
    let medicalHistory: String?
    let currentMedications: String?
}

struct ChatHealthLog: Codable {
    let logType: String
    let timestamp: String
    let notes: String?
    let mealType: String?
    let amount: String?
    let duration: String?
    let moodLevel: Int?
    let symptomType: String?
    let severityLevel: Int?
    let digestionQuality: String?
    let activityType: String?
    let supplementName: String?
    let dosage: String?
    let appointmentType: String?
    let location: String?
    let groomingType: String?
    let treatName: String?
    let waterAmount: String?
}

struct ChatResponse: Codable {
    let success: Bool
    let conversationId: String
    let message: ChatMessage
}

struct ChatMessage: Codable {
    let id: String
    let role: String
    let content: String
    let createdAt: String
}

struct ConversationsResponse: Codable {
    let success: Bool?
    let conversations: [ServerConversation]
}

struct ServerConversation: Codable {
    let id: String
    let title: String?
    let createdAt: String
    let updatedAt: String?
    let isPinned: Bool?
    let isArchived: Bool?
    let dogId: String?
    let dogs: ServerDogInfo?
    let messageCount: Int?
    let lastMessagePreview: String?
    let lastMessageRole: String?
    let lastMessageCreatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isPinned = "is_pinned"
        case isArchived = "is_archived"
        case dogId = "dog_id"
        case dogs
        case messageCount
        case lastMessagePreview
        case lastMessageRole
        case lastMessageCreatedAt
    }
    
    func toConversation() -> Conversation {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let standardFormatter = ISO8601DateFormatter()
        standardFormatter.formatOptions = [.withInternetDateTime]
        
        let createdDate = formatter.date(from: createdAt) ?? standardFormatter.date(from: createdAt) ?? Date()
        let updatedDate = updatedAt.flatMap { formatter.date(from: $0) ?? standardFormatter.date(from: $0) }
        let lastMsgDate = lastMessageCreatedAt.flatMap { formatter.date(from: $0) ?? standardFormatter.date(from: $0) }
        
        return Conversation(
            id: id,
            userId: nil,
            dogId: dogId,
            createdAt: createdDate,
            updatedAt: updatedDate,
            title: title ?? "Chat",
            messages: [],
            messageCount: messageCount ?? 0,
            lastMessagePreview: lastMessagePreview,
            lastMessageRole: lastMessageRole,
            lastMessageCreatedAt: lastMsgDate,
            isPinned: isPinned ?? false,
            isArchived: isArchived ?? false
        )
    }
}

struct ServerDogInfo: Codable {
    let id: String?
    let name: String?
    let breed: String?
}

struct ConversationMessagesResponse: Codable {
    let success: Bool
    let messages: [ServerMessage]
}

struct ServerMessage: Codable {
    let id: String
    let role: String
    let content: String
    let createdAt: String
    let feedback: String?
    
    enum CodingKeys: String, CodingKey {
        case id, role, content, feedback
        case createdAt = "created_at"
    }
}

struct DogsResponse: Codable {
    let dogs: [Dog]
}

struct DogResponse: Codable {
    let dog: Dog
}

struct EntitlementsResponse: Codable {
    let hasActiveSubscription: Bool
    let subscriptionStatus: String
}

// MARK: - Health Log Types

struct HealthLogRequest: Codable {
    let dogId: String
    let logType: String
    let timestamp: Date
    let clientId: String
    let notes: String?
    let mealType: String?
    let amount: String?
    let duration: String?
    let moodLevel: Int?
    let symptomType: String?
    let severityLevel: Int?
    let digestionQuality: String?
    let activityType: String?
    let supplementName: String?
    let dosage: String?
    let appointmentType: String?
    let location: String?
    let groomingType: String?
    let treatName: String?
    let waterAmount: String?
    
    init(from entry: HealthLogEntry) {
        self.dogId = entry.dogId
        self.logType = entry.logType
        self.timestamp = entry.timestamp
        self.clientId = entry.id.uuidString
        self.notes = entry.notes.isEmpty ? nil : entry.notes
        self.mealType = entry.mealType
        self.amount = entry.amount
        self.duration = entry.duration
        self.moodLevel = entry.moodLevel
        self.symptomType = entry.symptomType
        self.severityLevel = entry.severityLevel
        self.digestionQuality = entry.digestionQuality
        self.activityType = entry.activityType
        self.supplementName = entry.supplementName
        self.dosage = entry.dosage
        self.appointmentType = entry.appointmentType
        self.location = entry.location
        self.groomingType = entry.groomingType
        self.treatName = entry.treatName
        self.waterAmount = entry.waterAmount
    }
}

struct HealthLogsResponse: Codable {
    let success: Bool
    let logs: [ServerHealthLog]
    let syncedAt: String
}

struct HealthLogResponse: Codable {
    let success: Bool
    let log: ServerHealthLog
    let duplicate: Bool?
}

struct HealthLogSyncResponse: Codable {
    let success: Bool
    let serverLogs: [ServerHealthLog]
    let uploadedCount: Int
    let duplicateClientIds: [String]
    let syncedAt: String
}

struct DeleteResponse: Codable {
    let success: Bool
    let message: String?
}

struct ConversationUpdateResponse: Codable {
    let success: Bool
    let conversation: ServerConversation?
}

struct ServerHealthLog: Codable {
    let id: String
    let userId: String
    let dogId: String
    let logType: String
    let timestamp: String
    let notes: String?
    let mealType: String?
    let amount: String?
    let duration: String?
    let moodLevel: Int?
    let symptomType: String?
    let severityLevel: Int?
    let digestionQuality: String?
    let activityType: String?
    let supplementName: String?
    let dosage: String?
    let appointmentType: String?
    let location: String?
    let groomingType: String?
    let treatName: String?
    let waterAmount: String?
    let clientId: String?
    let isDeleted: Bool?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case dogId = "dog_id"
        case logType = "log_type"
        case timestamp
        case notes
        case mealType = "meal_type"
        case amount
        case duration
        case moodLevel = "mood_level"
        case symptomType = "symptom_type"
        case severityLevel = "severity_level"
        case digestionQuality = "digestion_quality"
        case activityType = "activity_type"
        case supplementName = "supplement_name"
        case dosage
        case appointmentType = "appointment_type"
        case location
        case groomingType = "grooming_type"
        case treatName = "treat_name"
        case waterAmount = "water_amount"
        case clientId = "client_id"
        case isDeleted = "is_deleted"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
