import Foundation

class EntitlementsService {
    static let shared = EntitlementsService()
    
    private init() {}
    
    func checkEntitlements(token: String) async throws -> Bool {
        guard let url = URL(string: "\(APIConfig.baseURL)/entitlements") else {
            throw EntitlementsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EntitlementsError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw EntitlementsError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            throw EntitlementsError.serverError
        }
        
        let entitlementResponse = try JSONDecoder().decode(EntitlementResponse.self, from: data)
        return entitlementResponse.isActive
    }
}

struct EntitlementResponse: Codable {
    let isActive: Bool
    let productId: String?
    let renewsAt: String?
    let updatedAt: String?
}

enum EntitlementsError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError
}
