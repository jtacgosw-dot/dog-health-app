import Foundation

class APIService {
    static let shared = APIService()
    
    private let baseURL = APIConfig.baseURL
    private var authToken: String?
    
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
    
    private func makeRequest<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        requiresAuth: Bool = true
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
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
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
    
        func sendChatMessage(message: String, conversationId: String?, dogId: String?, dogProfile: ChatDogProfile?, healthLogs: [ChatHealthLog]?) async throws -> ChatResponse {
            let body = ChatRequest(message: message, conversationId: conversationId, dogId: dogId, dogProfile: dogProfile, healthLogs: healthLogs)
            let data = try JSONEncoder().encode(body)
            return try await makeRequest(endpoint: "/chat", method: "POST", body: data)
        }
    
    func getConversations() async throws -> [Conversation] {
        let response: ConversationsResponse = try await makeRequest(endpoint: "/chat/conversations")
        return response.conversations
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

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
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

struct ChatRequest: Codable {
    let message: String
    let conversationId: String?
    let dogId: String?
    let dogProfile: ChatDogProfile?
    let healthLogs: [ChatHealthLog]?
}

struct ChatDogProfile: Codable {
    let name: String
    let breed: String?
    let ageYears: Int?
    let ageMonths: Int?
    let weightLbs: Double?
    let sex: String?
    let medicalHistory: String?
    let allergies: String?
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
    let conversations: [Conversation]
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
