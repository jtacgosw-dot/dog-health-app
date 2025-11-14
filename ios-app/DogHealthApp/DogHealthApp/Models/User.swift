import Foundation

struct User: Codable {
    let id: String
    var email: String?
    var fullName: String?
    var appleUserId: String?
    var createdAt: Date
    var subscriptionStatus: SubscriptionStatus
    
    init(id: String = UUID().uuidString,
         email: String? = nil,
         fullName: String? = nil,
         appleUserId: String? = nil,
         createdAt: Date = Date(),
         subscriptionStatus: SubscriptionStatus = .free) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.appleUserId = appleUserId
        self.createdAt = createdAt
        self.subscriptionStatus = subscriptionStatus
    }
}

enum SubscriptionStatus: String, Codable {
    case free
    case active
    case expired
    case cancelled
}
