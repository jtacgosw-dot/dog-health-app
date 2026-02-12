import AuthenticationServices
import CryptoKit
import Foundation

enum GoogleSignInError: LocalizedError {
    case notConfigured
    case noAuthCode
    case noIdToken
    case exchangeFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Google Sign-In is not configured. Please set your Google Client ID in APIConfig."
        case .noAuthCode: return "Failed to get authorization code from Google"
        case .noIdToken: return "Failed to get ID token from Google"
        case .exchangeFailed(let msg): return "Token exchange failed: \(msg)"
        }
    }
}

class GoogleSignInManager: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = GoogleSignInManager()
    private var currentSession: ASWebAuthenticationSession?

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }

    func signIn() async throws -> String {
        guard !APIConfig.googleClientId.isEmpty else {
            throw GoogleSignInError.notConfigured
        }

        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        let reversedClientId = reverseClientId(APIConfig.googleClientId)
        let redirectURI = "\(reversedClientId):/oauthredirect"

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: APIConfig.googleClientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid email profile"),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ]

        let authCode: String = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let session = ASWebAuthenticationSession(
                    url: components.url!,
                    callbackURLScheme: reversedClientId
                ) { callbackURL, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let callbackURL = callbackURL,
                          let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                            .queryItems?.first(where: { $0.name == "code" })?.value else {
                        continuation.resume(throwing: GoogleSignInError.noAuthCode)
                        return
                    }
                    continuation.resume(returning: code)
                }
                session.presentationContextProvider = self
                session.prefersEphemeralWebBrowserSession = true
                self.currentSession = session
                session.start()
            }
        }

        self.currentSession = nil
        let idToken = try await exchangeCodeForIdToken(authCode: authCode, codeVerifier: codeVerifier, redirectURI: redirectURI)
        return idToken
    }

    private func exchangeCodeForIdToken(authCode: String, codeVerifier: String, redirectURI: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params: [String: String] = [
            "grant_type": "authorization_code",
            "code": authCode,
            "redirect_uri": redirectURI,
            "client_id": APIConfig.googleClientId,
            "code_verifier": codeVerifier
        ]

        request.httpBody = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GoogleSignInError.noIdToken
        }

        if let errorMsg = json["error_description"] as? String {
            throw GoogleSignInError.exchangeFailed(errorMsg)
        }

        guard let idToken = json["id_token"] as? String else {
            throw GoogleSignInError.noIdToken
        }

        return idToken
    }

    private func reverseClientId(_ clientId: String) -> String {
        return clientId.components(separatedBy: ".").reversed().joined(separator: ".")
    }

    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
