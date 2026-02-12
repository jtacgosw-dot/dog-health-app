import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.petlyLightGreen)
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .fill(Color.petlyDarkGreen)
                                .frame(width: 96, height: 96)
                            
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 60)
                        
                        VStack(spacing: 4) {
                            Text("Welcome back")
                                .font(.petlyTitle(28))
                                .foregroundColor(.petlyDarkGreen)
                            Text("to Petly.")
                                .font(.petlyTitle(28))
                                .foregroundColor(.petlyDarkGreen)
                        }
                        .padding(.top, 10)
                        
                        Text("Sign in to access your pet\u{2019}s care")
                            .font(.petlyBody(14))
                            .foregroundColor(.petlyFormIcon)
                        
                        VStack(spacing: 14) {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .foregroundColor(.petlyFormIcon)
                                    .frame(width: 24)
                                TextField("E-Mail", text: $email)
                                    .font(.petlyBody(16))
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            .padding()
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.petlyFormIcon)
                                    .frame(width: 24)
                                SecureField("Password", text: $password)
                                    .font(.petlyBody(16))
                                    .textContentType(.password)
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
                        
                        Button(action: handleEmailSignIn) {
                            Text("SIGN IN")
                                .font(.petlyBodyMedium(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.petlyDarkGreen)
                                .cornerRadius(12)
                                .shadow(color: Color.petlyDarkGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal)
                        .disabled(isLoading)
                        
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
                            Button(action: { triggerAppleSignIn() }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.petlyLightGreen)
                                        .frame(width: 56, height: 56)
                                    Circle()
                                        .fill(Color.petlyDarkGreen)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                }
                            }
                            .disabled(isLoading)
                            
                            Button(action: { handleGoogleSignIn() }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.petlyLightGreen)
                                        .frame(width: 56, height: 56)
                                    Circle()
                                        .fill(Color.petlyDarkGreen)
                                        .frame(width: 44, height: 44)
                                    Text("G")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .disabled(isLoading)
                        }
                        
                        Button(action: handleGuestSignIn) {
                            Text("Continue as Guest")
                                .font(.petlyBody(14))
                                .foregroundColor(.petlyFormIcon)
                                .underline()
                        }
                        .disabled(isLoading)
                        .padding(.top, 8)
                        
                        HStack(spacing: 4) {
                            Text("Don\u{2019}t have an account?")
                                .font(.petlyBody(14))
                                .foregroundColor(.petlyFormIcon)
                            Button(action: {
                                appState.hasCompletedOnboarding = false
                            }) {
                                Text("Sign Up")
                                    .font(.petlyBodyMedium(14))
                                    .foregroundColor(.petlyDarkGreen)
                            }
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 40)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        .buttonStyle(.plain)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    private func handleEmailSignIn() {
        let emailPattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        guard email.range(of: emailPattern, options: .regularExpression) != nil else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                let response = try await APIService.shared.login(email: email, password: password)
                APIService.shared.setAuthToken(response.token)
                APIService.shared.setIsGuest(false)
                
                await MainActor.run {
                    let statusString = response.user.subscriptionStatus ?? "free"
                    let status = SubscriptionStatus(rawValue: statusString) ?? .free
                    appState.currentUser = User(
                        id: response.user.id,
                        email: response.user.email,
                        fullName: response.user.fullName ?? "User",
                        subscriptionStatus: status
                    )
                    UserDefaults.standard.set(email, forKey: "userEmail")
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
    
    private func triggerAppleSignIn() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let authorization = try await AppleSignInManager.shared.signIn()
                if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                    guard let identityTokenData = appleIDCredential.identityToken,
                          let identityToken = String(data: identityTokenData, encoding: .utf8),
                          let authCodeData = appleIDCredential.authorizationCode,
                          let authCode = String(data: authCodeData, encoding: .utf8) else {
                        await MainActor.run {
                            errorMessage = "Failed to get authentication credentials"
                            isLoading = false
                        }
                        return
                    }
                    let fullName = appleIDCredential.fullName.map { personName in
                        [personName.givenName, personName.familyName]
                            .compactMap { $0 }
                            .joined(separator: " ")
                    }
                    let response = try await APIService.shared.signInWithApple(
                        identityToken: identityToken,
                        authorizationCode: authCode,
                        fullName: fullName
                    )
                    APIService.shared.setAuthToken(response.token)
                    APIService.shared.setIsGuest(false)
                    await MainActor.run {
                        appState.currentUser = response.user
                        appState.isSignedIn = true
                        isLoading = false
                    }
                    await appState.loadUserData()
                }
            } catch {
                await MainActor.run {
                    if let authError = error as? ASAuthorizationError,
                       authError.code == .canceled {
                        isLoading = false
                        return
                    }
                    errorMessage = "Apple sign-in failed: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func handleGoogleSignIn() {
        guard !APIConfig.googleClientId.isEmpty else {
            errorMessage = "Google Sign-In is not configured yet. Please set your Google Client ID in APIConfig."
            return
        }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let idToken = try await GoogleSignInManager.shared.signIn()
                let response = try await APIService.shared.signInWithGoogle(idToken: idToken)
                APIService.shared.setAuthToken(response.token)
                APIService.shared.setIsGuest(false)
                await MainActor.run {
                    let statusString = response.user.subscriptionStatus ?? "free"
                    let status = SubscriptionStatus(rawValue: statusString) ?? .free
                    appState.currentUser = User(
                        id: response.user.id,
                        email: response.user.email,
                        fullName: response.user.fullName ?? "User",
                        subscriptionStatus: status
                    )
                    UserDefaults.standard.set(response.user.email, forKey: "userEmail")
                    appState.isSignedIn = true
                    isLoading = false
                }
                await appState.loadUserData()
            } catch {
                await MainActor.run {
                    if let webError = error as? ASWebAuthenticationSessionError,
                       webError.code == .canceledLogin {
                        isLoading = false
                        return
                    }
                    errorMessage = "Google sign-in failed: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }

    private func handleGuestSignIn() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
                UserDefaults.standard.set(deviceId, forKey: "guestDeviceId")
                let response = try await APIService.shared.guestSignIn(deviceId: deviceId)
                
                APIService.shared.setAuthToken(response.token)
                APIService.shared.setIsGuest(true)
                
                await MainActor.run {
                    let statusString = response.user.subscriptionStatus ?? "free"
                    let status = SubscriptionStatus(rawValue: statusString) ?? .free
                    appState.currentUser = User(
                        id: response.user.id,
                        email: response.user.email,
                        fullName: response.user.fullName ?? "Guest User",
                        subscriptionStatus: status
                    )
                    appState.isSignedIn = true
                    isLoading = false
                }
                
                await appState.loadUserData()
            } catch {
                await MainActor.run {
                    errorMessage = "Guest sign in failed: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
}

#Preview {
    SignInView()
        .environmentObject(AppState())
}
