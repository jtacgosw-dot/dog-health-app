import Foundation

struct Message: Identifiable, Codable {
    let id: String
    let conversationId: String
    let role: MessageRole
    let content: String
    let timestamp: Date
    var feedback: MessageFeedback?
    var imageData: [Data]?
    
    init(id: String = UUID().uuidString,
         conversationId: String,
         role: MessageRole,
         content: String,
         timestamp: Date = Date(),
         feedback: MessageFeedback? = nil,
         imageData: [Data]? = nil) {
        self.id = id
        self.conversationId = conversationId
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.feedback = feedback
        self.imageData = imageData
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
    var updatedAt: Date?
    var title: String
    var messages: [Message]
    var messageCount: Int
    var lastMessagePreview: String?
    var lastMessageRole: String?
    var lastMessageCreatedAt: Date?
    var isPinned: Bool
    var isArchived: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case dogId = "dog_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case title
        case messages
        case messageCount
        case lastMessagePreview
        case lastMessageRole
        case lastMessageCreatedAt
        case isPinned = "is_pinned"
        case isArchived = "is_archived"
    }
    
    init(id: String = UUID().uuidString,
         userId: String? = nil,
         dogId: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date? = nil,
         title: String = "New Conversation",
         messages: [Message] = [],
         messageCount: Int = 0,
         lastMessagePreview: String? = nil,
         lastMessageRole: String? = nil,
         lastMessageCreatedAt: Date? = nil,
         isPinned: Bool = false,
         isArchived: Bool = false) {
        self.id = id
        self.userId = userId
        self.dogId = dogId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.messages = messages
        self.messageCount = messageCount
        self.lastMessagePreview = lastMessagePreview
        self.lastMessageRole = lastMessageRole
        self.lastMessageCreatedAt = lastMessageCreatedAt
        self.isPinned = isPinned
        self.isArchived = isArchived
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        dogId = try container.decodeIfPresent(String.self, forKey: .dogId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Chat"
        messages = try container.decodeIfPresent([Message].self, forKey: .messages) ?? []
        messageCount = try container.decodeIfPresent(Int.self, forKey: .messageCount) ?? messages.count
        lastMessagePreview = try container.decodeIfPresent(String.self, forKey: .lastMessagePreview)
        lastMessageRole = try container.decodeIfPresent(String.self, forKey: .lastMessageRole)
        lastMessageCreatedAt = try container.decodeIfPresent(Date.self, forKey: .lastMessageCreatedAt)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
    }
}
