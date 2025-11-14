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
    
    func sendChatMessage(message: String, conversationId: String?, dogId: String?) async throws -> ChatResponse {
        let body = ChatRequest(message: message, conversationId: conversationId, dogId: dogId)
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

struct ChatRequest: Codable {
    let message: String
    let conversationId: String?
    let dogId: String?
}

struct ChatResponse: Codable {
    let message: Message
    let conversationId: String
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
