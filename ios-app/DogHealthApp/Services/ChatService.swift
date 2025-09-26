import Foundation

@MainActor
class ChatService: ObservableObject {
    @Published var messages: [Message] = []
    
    private let baseURL = "http://localhost:3000/api"
    private var conversationHistory: [ChatMessage] = []
    
    func addWelcomeMessage() {
        let welcomeMessage = Message(
            content: "Hello! I'm your dog health assistant. I can help answer questions about your dog's symptoms, nutrition, care, and general wellness. What would you like to know?",
            isFromUser: false,
            hasDisclaimer: true
        )
        messages.append(welcomeMessage)
    }
    
    func sendMessage(_ content: String) async {
        let userMessage = Message(content: content, isFromUser: true)
        messages.append(userMessage)
        
        conversationHistory.append(ChatMessage(role: "user", content: content))
        
        do {
            let response = try await sendChatRequest(content)
            let aiMessage = Message(
                content: response.response,
                isFromUser: false,
                hasDisclaimer: true
            )
            messages.append(aiMessage)
            
            conversationHistory.append(ChatMessage(role: "assistant", content: response.response))
            
            if conversationHistory.count > 20 {
                conversationHistory = Array(conversationHistory.suffix(20))
            }
            
        } catch {
            let errorMessage = Message(
                content: "I'm sorry, I'm having trouble connecting right now. Please check your internet connection and try again. If the problem persists, please contact support.",
                isFromUser: false,
                hasDisclaimer: true
            )
            messages.append(errorMessage)
            print("Chat error: \(error)")
        }
    }
    
    private func sendChatRequest(_ message: String) async throws -> ChatResponse {
        guard let url = URL(string: "\(baseURL)/chat") else {
            throw ChatError.invalidURL
        }
        
        let request = ChatRequest(
            message: message,
            conversationHistory: conversationHistory,
            conversationId: nil
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ChatError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(ChatResponse.self, from: data)
    }
}

enum ChatError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}
