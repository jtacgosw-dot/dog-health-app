import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var ownerName = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 40)
                    
                    Text("Create Account")
                        .font(.petlyTitle(32))
                        .foregroundColor(.petlyDarkGreen)
                    
                    Text("Join Petly today")
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyFormIcon)
                    
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope")
                                .foregroundColor(.petlyFormIcon)
                                .frame(width: 20)
                            
                            TextField("Email", text: $email)
                                .font(.petlyBody(14))
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding()
                        .background(Color.petlyLightGreen)
                        .cornerRadius(16)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "person")
                                .foregroundColor(.petlyFormIcon)
                                .frame(width: 20)
                            
                            TextField("Owner's Name", text: $ownerName)
                                .font(.petlyBody(14))
                        }
                        .padding()
                        .background(Color.petlyLightGreen)
                        .cornerRadius(16)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "lock")
                                .foregroundColor(.petlyFormIcon)
                                .frame(width: 20)
                            
                            if showPassword {
                                TextField("Password", text: $password)
                                    .font(.petlyBody(14))
                            } else {
                                SecureField("Password", text: $password)
                                    .font(.petlyBody(14))
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.petlyFormIcon)
                            }
                        }
                        .padding()
                        .background(Color.petlyLightGreen)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.petlyBody(12))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    Button(action: signUp) {
                        Text("Sign Up")
                            .font(.petlyBodyMedium(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.petlyDarkGreen)
                            .cornerRadius(25)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    Text("or continue with")
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                        .padding(.top, 20)
                    
                    HStack(spacing: 16) {
                        SocialLoginButton(icon: "facebook", color: Color(hex: "1877F2")) {
                        }
                        
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.email, .fullName]
                        } onCompletion: { result in
                            handleAppleSignIn(result)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(25)
                        
                        SocialLoginButton(icon: "google", color: Color(hex: "DB4437")) {
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
        }
    }
    
    private func signUp() {
        guard !email.isEmpty, !ownerName.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        errorMessage = nil
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userIdentifier = appleIDCredential.user
                let email = appleIDCredential.email
                let fullName = appleIDCredential.fullName
                
                Task {
                    do {
                        let response = try await APIService.shared.signInWithApple(
                            identityToken: String(data: appleIDCredential.identityToken ?? Data(), encoding: .utf8) ?? "",
                            authorizationCode: String(data: appleIDCredential.authorizationCode ?? Data(), encoding: .utf8) ?? "",
                            fullName: fullName?.givenName
                        )
                        
                        await MainActor.run {
                            appState.currentUser = response.user
                            appState.isSignedIn = true
                            APIService.shared.setAuthToken(response.token)
                        }
                    } catch {
                        await MainActor.run {
                            errorMessage = "Sign in failed: \(error.localizedDescription)"
                        }
                    }
                }
            }
        case .failure(let error):
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }
}

struct SocialLoginButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            Image(systemName: icon == "facebook" ? "f.circle.fill" : "g.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(Color.petlyLightGreen)
                .cornerRadius(25)
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

#Preview {
    SignUpView()
        .environmentObject(AppState())
}
