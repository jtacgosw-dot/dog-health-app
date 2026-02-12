import Foundation

struct APIConfig {
    #if targetEnvironment(simulator)
    static let baseURL = "http://localhost:3000/api"
    #else
    static let baseURL = "https://dog-health-app.onrender.com/api"
    #endif

    static let googleClientId = ""
}
