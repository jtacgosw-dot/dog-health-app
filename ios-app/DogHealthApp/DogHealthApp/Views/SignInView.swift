import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var appState: AppState
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Welcome Back")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Sign in to access your dog health guidance")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    handleSignInWithApple(result)
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal)
            .disabled(isLoading)
            
            Button(action: {
                appState.isSignedIn = true
            }) {
                Text("Continue as Guest (Demo)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
    }
    
    private func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userIdentifier = appleIDCredential.user
                let identityToken = appleIDCredential.identityToken
                let authorizationCode = appleIDCredential.authorizationCode
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    appState.isSignedIn = true
                    isLoading = false
                }
            }
            
        case .failure(let error):
            isLoading = false
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AppState())
}
