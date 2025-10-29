import Foundation

struct APIConfig {
    static let baseURL = "https://dog-health-app.onrender.com/api"
    
    enum Endpoint {
        case health
        case authApple
        case iapVerify
        case entitlements
        case chat
        
        var path: String {
            switch self {
            case .health:
                return "/health"
            case .authApple:
                return "/auth/apple"
            case .iapVerify:
                return "/iap/verify"
            case .entitlements:
                return "/entitlements"
            case .chat:
                return "/chat"
            }
        }
        
        var url: URL? {
            return URL(string: APIConfig.baseURL + path)
        }
    }
}
