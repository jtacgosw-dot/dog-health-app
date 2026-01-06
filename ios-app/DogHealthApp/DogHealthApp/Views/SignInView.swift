import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var appState: AppState
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.petlyCream
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Text("Petly")
                    .font(.system(size: 56, weight: .bold, design: .serif))
                    .foregroundColor(.petlyDarkGreen)
                
                Image(systemName: "pawprint.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.petlyDarkGreen)
                
                Text("Welcome Back")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.petlyDarkGreen)
                
                Text("Sign in to access your pet's personalized care plan")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
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
                
                VStack(spacing: 16) {
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
                    .cornerRadius(PetlyTheme.buttonCornerRadius)
                    .disabled(isLoading)
                    
                    Button(action: {
                        handleGuestSignIn()
                    }) {
                        Text("Continue as Guest")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .disabled(isLoading)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .padding()
            
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func handleGuestSignIn() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
                let response = try await APIService.shared.guestSignIn(deviceId: deviceId)
                
                APIService.shared.setAuthToken(response.token)
                
                await MainActor.run {
                    appState.currentUser = User(
                        id: response.user.id,
                        email: response.user.email,
                        fullName: response.user.fullName ?? "Guest User",
                        subscriptionStatus: response.user.subscriptionStatus ?? "free"
                    )
                    appState.isSignedIn = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Guest sign in failed: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let identityTokenData = appleIDCredential.identityToken,
                      let identityToken = String(data: identityTokenData, encoding: .utf8),
                      let authCodeData = appleIDCredential.authorizationCode,
                      let authCode = String(data: authCodeData, encoding: .utf8) else {
                    errorMessage = "Failed to get authentication credentials"
                    isLoading = false
                    return
                }
                
                let fullName = appleIDCredential.fullName.map { personName in
                    [personName.givenName, personName.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                }
                
                Task {
                    do {
                        let response = try await APIService.shared.signInWithApple(
                            identityToken: identityToken,
                            authorizationCode: authCode,
                            fullName: fullName
                        )
                        
                        APIService.shared.setAuthToken(response.token)
                        
                        await MainActor.run {
                            appState.currentUser = response.user
                            appState.isSignedIn = true
                            isLoading = false
                        }
                        
                        await appState.loadUserData()
                    } catch {
                        await MainActor.run {
                            errorMessage = "Sign in failed: \(error.localizedDescription)"
                            isLoading = false
                        }
                    }
                }
            }
            
        case .failure(let error):
            isLoading = false
            if let authError = error as? ASAuthorizationError,
               authError.code == .canceled {
                return
            }
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AppState())
}
