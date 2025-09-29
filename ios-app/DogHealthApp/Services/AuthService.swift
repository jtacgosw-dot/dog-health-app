import Foundation
import AuthenticationServices

class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    private override init() {
        super.init()
    }
    
    func signInWithApple() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = AuthDelegate(continuation: continuation)
            authorizationController.presentationContextProvider = PresentationContextProvider()
            authorizationController.performRequests()
        }
    }
}

class AuthDelegate: NSObject, ASAuthorizationControllerDelegate {
    private let continuation: CheckedContinuation<String, Error>
    
    init(continuation: CheckedContinuation<String, Error>) {
        self.continuation = continuation
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let identityTokenString = String(data: identityToken, encoding: .utf8) else {
            continuation.resume(throwing: AuthError.invalidCredentials)
            return
        }
        
        Task {
            do {
                let token = try await self.exchangeTokenWithBackend(identityToken: identityTokenString)
                continuation.resume(returning: token)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
    
    private func exchangeTokenWithBackend(identityToken: String) async throws -> String {
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/apple") else {
            throw AuthError.invalidURL
        }
        
        let requestBody = ["identityToken": identityToken]
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.serverError
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        return authResponse.token
    }
}

class PresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

struct AuthResponse: Codable {
    let success: Bool
    let token: String
    let user: User
    
    struct User: Codable {
        let id: String
        let appleSub: String
        let createdAt: String
    }
}

enum AuthError: Error {
    case invalidCredentials
    case invalidURL
    case serverError
}
