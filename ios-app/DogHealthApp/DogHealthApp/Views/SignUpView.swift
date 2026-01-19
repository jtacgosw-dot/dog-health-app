import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var ownerName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.petlyDarkGreen)
                            .padding(12)
                            .background(Color.petlyLightGreen)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 0) {
                            HStack(alignment: .top, spacing: -20) {
                                SpeechBubble(text: "WOOF!", isLeft: true)
                                SpeechBubble(text: "MEOW!", isLeft: false)
                                    .offset(y: 20)
                            }
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 4) {
                            Text("Your pet's journey")
                                .font(.petlyTitle(28))
                                .foregroundColor(.petlyDarkGreen)
                            Text("starts here...")
                                .font(.petlyTitle(28))
                                .foregroundColor(.petlyDarkGreen)
                        }
                        .padding(.top, 10)
                        
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .foregroundColor(.petlyFormIcon)
                                    .frame(width: 24)
                                
                                TextField("E-Mail", text: $email)
                                    .font(.petlyBody(14))
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            .padding()
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "pawprint.fill")
                                    .foregroundColor(.petlyFormIcon)
                                    .frame(width: 24)
                                
                                TextField("Owner's Name", text: $ownerName)
                                    .font(.petlyBody(14))
                            }
                            .padding()
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.petlyFormIcon)
                                    .frame(width: 24)
                                
                                if showPassword {
                                    TextField("Password", text: $password)
                                        .font(.petlyBody(14))
                                } else {
                                    SecureField("Password", text: $password)
                                        .font(.petlyBody(14))
                                }
                            }
                            .padding()
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.petlyFormIcon)
                                    .frame(width: 24)
                                
                                if showPassword {
                                    TextField("Confirm Password", text: $confirmPassword)
                                        .font(.petlyBody(14))
                                } else {
                                    SecureField("Confirm Password", text: $confirmPassword)
                                        .font(.petlyBody(14))
                                }
                            }
                            .padding()
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
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
                            Text("SIGN UP")
                                .font(.petlyBodyMedium(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.petlyDarkGreen)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Rectangle()
                                .fill(Color.petlyFormIcon.opacity(0.3))
                                .frame(height: 1)
                            Text("Or")
                                .font(.petlyBody(14))
                                .foregroundColor(.petlyFormIcon)
                                .padding(.horizontal, 16)
                            Rectangle()
                                .fill(Color.petlyFormIcon.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 10)
                        
                        HStack(spacing: 24) {
                            Button(action: {}) {
                                Image(systemName: "f.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.petlyDarkGreen)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 32))
                                    .foregroundColor(.black)
                            }
                            
                            Button(action: {}) {
                                Text("G")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.petlyDarkGreen)
                            }
                        }
                        
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .font(.petlyBody(14))
                                .foregroundColor(.petlyFormIcon)
                            Button(action: {}) {
                                Text("Sign In")
                                    .font(.petlyBodyMedium(14))
                                    .foregroundColor(.petlyDarkGreen)
                                    .underline()
                            }
                        }
                        .padding(.top, 10)
                        
                        HStack(spacing: 8) {
                            ForEach(0..<4) { index in
                                Circle()
                                    .fill(index == 0 ? Color.petlyDarkGreen : Color.petlyFormIcon.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
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
                            let _ = appleIDCredential.user
                            let _ = appleIDCredential.email
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

struct SpeechBubble: View {
    let text: String
    let isLeft: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.petlyBodyMedium(16))
                .foregroundColor(.petlyDarkGreen)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.petlyDarkGreen, lineWidth: 1.5)
                        .background(Color.petlyBackground)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Path { path in
                if isLeft {
                    path.move(to: CGPoint(x: 30, y: 0))
                    path.addLine(to: CGPoint(x: 40, y: 15))
                    path.addLine(to: CGPoint(x: 50, y: 0))
                } else {
                    path.move(to: CGPoint(x: 20, y: 0))
                    path.addLine(to: CGPoint(x: 30, y: 15))
                    path.addLine(to: CGPoint(x: 40, y: 0))
                }
            }
            .stroke(Color.petlyDarkGreen, lineWidth: 1.5)
            .frame(width: 60, height: 15)
            .offset(x: isLeft ? -20 : 20)
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(AppState())
}
