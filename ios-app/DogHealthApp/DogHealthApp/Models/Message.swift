import Foundation

struct Message: Identifiable, Codable {
    let id: String
    let conversationId: String
    let role: MessageRole
    let content: String
    let timestamp: Date
    var feedback: MessageFeedback?
    
    init(id: String = UUID().uuidString,
         conversationId: String,
         role: MessageRole,
         content: String,
         timestamp: Date = Date(),
         feedback: MessageFeedback? = nil) {
        self.id = id
        self.conversationId = conversationId
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.feedback = feedback
    }
}

enum MessageRole: String, Codable {
    case user
    case assistant
}

enum MessageFeedback: String, Codable {
    case positive
    case negative
}

struct Conversation: Identifiable, Codable {
    let id: String
    let userId: String
    var dogId: String?
    let createdAt: Date
    var title: String
    var messages: [Message]
    
    init(id: String = UUID().uuidString,
         userId: String,
         dogId: String? = nil,
         createdAt: Date = Date(),
         title: String = "New Conversation",
         messages: [Message] = []) {
        self.id = id
        self.userId = userId
        self.dogId = dogId
        self.createdAt = createdAt
        self.title = title
        self.messages = messages
    }
}
