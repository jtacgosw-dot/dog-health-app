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
    let userId: String?
    var dogId: String?
    let createdAt: Date
    var title: String
    var messages: [Message]
    var messageCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case dogId = "dog_id"
        case createdAt = "created_at"
        case title
        case messages
        case messageCount
    }
    
    init(id: String = UUID().uuidString,
         userId: String? = nil,
         dogId: String? = nil,
         createdAt: Date = Date(),
         title: String = "New Conversation",
         messages: [Message] = [],
         messageCount: Int = 0) {
        self.id = id
        self.userId = userId
        self.dogId = dogId
        self.createdAt = createdAt
        self.title = title
        self.messages = messages
        self.messageCount = messageCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        dogId = try container.decodeIfPresent(String.self, forKey: .dogId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Chat"
        messages = try container.decodeIfPresent([Message].self, forKey: .messages) ?? []
        messageCount = try container.decodeIfPresent(Int.self, forKey: .messageCount) ?? messages.count
    }
}
