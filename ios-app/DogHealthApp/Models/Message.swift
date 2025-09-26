import Foundation

struct Message: Identifiable, Codable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let hasDisclaimer: Bool
    
    init(content: String, isFromUser: Bool, hasDisclaimer: Bool = false) {
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.hasDisclaimer = hasDisclaimer
    }
}

struct ChatResponse: Codable {
    let response: String
    let timestamp: String
    let conversationId: String?
}

struct ChatRequest: Codable {
    let message: String
    let conversationHistory: [ChatMessage]
    let conversationId: String?
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}
