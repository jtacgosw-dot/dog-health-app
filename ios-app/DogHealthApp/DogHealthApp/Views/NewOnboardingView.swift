import SwiftUI
import AuthenticationServices

struct NewOnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var selectedInterests: Set<String> = []
    @State private var email = ""
    @State private var ownerName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var petName = ""
    @State private var petAge = ""
    @State private var petBreed = ""
    @State private var petWeight = ""
    @State private var petPersonality = ""
    @State private var petGender = "Male"
    @State private var petAllergies = ""
    @State private var petHealthConditions = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let interests: [(String, String)] = [
        ("fork.knife", "Nutrition"),
        ("pawprint.fill", "Behavior"),
        ("heart.fill", "Wellness"),
        ("fork.knife.circle.fill", "Recipes"),
        ("scissors", "Grooming"),
        ("figure.walk", "Training"),
        ("chart.bar.fill", "Tracking"),
        ("mouth.fill", "Dental"),
        ("pill.fill", "Supplements"),
        ("bolt.heart.fill", "Fitness"),
        ("tree.fill", "Longevity"),
        ("stethoscope", "Vet-Care")
    ]
    
    let genders = ["Male", "Female"]
    
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if currentPage == 0 {
                    signUpPage
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else if currentPage == 1 {
                    petProfilePage
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    interestsPage
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
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
    
    // MARK: - Page 0: Sign Up
    
    var signUpPage: some View {
        VStack(spacing: 0) {
            HStack { Spacer() }
                .padding(.horizontal)
                .padding(.top, 10)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Image("woofMeow")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 160)
                        .padding(.top, 30)
                    
                    VStack(spacing: 4) {
                        Text("Your pet\u{2019}s journey")
                            .font(.petlyTitle(28))
                            .foregroundColor(.petlyDarkGreen)
                        Text("starts here.")
                            .font(.petlyTitle(28))
                            .foregroundColor(.petlyDarkGreen)
                    }
                    .padding(.top, 10)
                    
                    Text("Create an account to get started")
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyFormIcon)
                    
                    VStack(spacing: 14) {
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
                        .shadow(color: Color.petlyDarkGreen.opacity(0.06), radius: 4, x: 0, y: 2)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .foregroundColor(.petlyFormIcon)
                                .frame(width: 24)
                            TextField("Owner's Name", text: $ownerName)
                                .font(.petlyBody(14))
                        }
                        .padding()
                        .background(Color.petlyLightGreen)
                        .cornerRadius(12)
                        .shadow(color: Color.petlyDarkGreen.opacity(0.06), radius: 4, x: 0, y: 2)
                        
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
                        .shadow(color: Color.petlyDarkGreen.opacity(0.06), radius: 4, x: 0, y: 2)
                        
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
                        .shadow(color: Color.petlyDarkGreen.opacity(0.06), radius: 4, x: 0, y: 2)
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
                    
                    Button(action: handleSignUp) {
                        Text("SIGN UP")
                            .font(.petlyBodyMedium(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.petlyDarkGreen)
                            .cornerRadius(12)
                            .shadow(color: Color.petlyDarkGreen.opacity(0.3), radius: 8, x: 0, y: 4)
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
                                    .offset(y: -1)
                            }
                        }
                        
                        Button(action: {}) {
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
                    }
                    
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.petlyBody(14))
                            .foregroundColor(.petlyFormIcon)
                        Button(action: {
                            appState.hasCompletedOnboarding = true
                        }) {
                            Text("Sign In")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                                .underline()
                        }
                    }
                    .padding(.top, 10)
                    
                    pageIndicator
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    // MARK: - Page 1: Pet Profile
    
    var petProfilePage: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        currentPage = 0
                    }
                }) {
                    Circle()
                        .fill(Color.petlyLightGreen)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.petlyDarkGreen)
                        )
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.petlyLightGreen)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .fill(Color.petlyDarkGreen)
                            .frame(width: 96, height: 96)
                        
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 4) {
                        Text("Tell us about")
                            .font(.petlyTitle(28))
                            .foregroundColor(.petlyDarkGreen)
                        Text("your pet!")
                            .font(.petlyTitle(28))
                            .foregroundColor(.petlyDarkGreen)
                    }
                    .padding(.top, 10)
                    
                    Text("We\u{2019}ll personalize their experience")
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyFormIcon)
                    
                    VStack(spacing: 12) {
                        PetFormField(icon: "pawprint.fill", placeholder: "Your Pet's Name", text: $petName)
                        PetFormField(icon: "clock", placeholder: "Age (years)", text: $petAge, keyboardType: .decimalPad)
                        PetFormField(icon: "dog", placeholder: "Breed", text: $petBreed)
                        PetFormField(icon: "scalemass", placeholder: "Weight (lbs)", text: $petWeight, keyboardType: .decimalPad)
                        PetFormField(icon: "face.smiling", placeholder: "Personality", text: $petPersonality)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "figure.stand.line.dotted.figure.stand")
                                .foregroundColor(.petlyFormIcon)
                                .frame(width: 24)
                            
                            Picker("Gender", selection: $petGender) {
                                ForEach(genders, id: \.self) { g in
                                    Text(g).tag(g)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.petlyDarkGreen)
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.petlyLightGreen)
                        .cornerRadius(12)
                        
                        PetFormField(icon: "allergens", placeholder: "Allergies", text: $petAllergies)
                        PetFormField(icon: "cross.case", placeholder: "Health Conditions", text: $petHealthConditions)
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
                    
                    Button(action: handlePetProfile) {
                        Text("NEXT STEP")
                            .font(.petlyBodyMedium(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.petlyDarkGreen)
                            .cornerRadius(12)
                            .shadow(color: Color.petlyDarkGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                    
                    pageIndicator
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    // MARK: - Page 2: Interests
    
    var interestsPage: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        currentPage = 1
                    }
                }) {
                    Circle()
                        .fill(Color.petlyLightGreen)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.petlyDarkGreen)
                        )
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 20)
            
            VStack(spacing: 4) {
                Text("Now, let\u{2019}s pick")
                    .font(.petlyTitle(28))
                    .foregroundColor(.petlyDarkGreen)
                
                Text("your interests.")
                    .font(.petlyTitle(28))
                    .foregroundColor(.petlyDarkGreen)
            }
            .padding(.bottom, 8)
            
            Text("Personalize your experience to make sure")
                .font(.petlyBody(13))
                .foregroundColor(.petlyFormIcon)
            
            Text("the needs of your furry-friend are met!")
                .font(.petlyBody(13))
                .foregroundColor(.petlyFormIcon)
                .padding(.bottom, 20)
            
            ScrollView(showsIndicators: false) {
            LazyVGrid(columns: [GridItem(.flexible(minimum: 150)), GridItem(.flexible(minimum: 150))], spacing: 12) {
                ForEach(interests, id: \.1) { icon, title in
                    InterestChip(
                        icon: icon,
                        title: title,
                        isSelected: selectedInterests.contains(title)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if selectedInterests.contains(title) {
                                selectedInterests.remove(title)
                            } else {
                                selectedInterests.insert(title)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            }
            
            Spacer()
            
            HStack {
                Image("dogCatOutline")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 165)
                Spacer()
            }
            .padding(.leading, 8)
            .padding(.bottom, -47)
            
            Button(action: {
                UserDefaults.standard.set(Array(selectedInterests), forKey: "userInterests")
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    appState.hasCompletedOnboarding = true
                }
            }) {
                Text("NEXT STEP")
                    .font(.petlyBodyMedium(16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedInterests.isEmpty ? Color.petlyFormIcon : Color.petlyDarkGreen)
                    .cornerRadius(12)
                    .shadow(color: (selectedInterests.isEmpty ? Color.petlyFormIcon : Color.petlyDarkGreen).opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(selectedInterests.isEmpty)
            .padding(.horizontal)
            .padding(.bottom, 10)
            
            pageIndicator
                .padding(.bottom, 30)
        }
    }
    
    // MARK: - Page Indicator
    
    var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4) { index in
                Circle()
                    .fill(index == currentPage ? Color.petlyDarkGreen : Color.petlyFormIcon.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
    
    // MARK: - Auth Handlers
    
    private func handleSignUp() {
        guard !ownerName.isEmpty else {
            errorMessage = "Please enter your name"
            return
        }
        
        let emailPattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        guard email.range(of: emailPattern, options: .regularExpression) != nil else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        errorMessage = nil
        isLoading = true
        UserDefaults.standard.set(ownerName, forKey: "ownerName")
        UserDefaults.standard.set(email, forKey: "userEmail")
        
        Task {
            do {
                let response = try await APIService.shared.register(email: email, password: password, fullName: ownerName)
                APIService.shared.setAuthToken(response.token)
                APIService.shared.setIsGuest(false)
                
                await MainActor.run {
                    let statusString = response.user.subscriptionStatus ?? "free"
                    let status = SubscriptionStatus(rawValue: statusString) ?? .free
                    appState.currentUser = User(
                        id: response.user.id,
                        email: response.user.email,
                        fullName: ownerName,
                        subscriptionStatus: status
                    )
                    appState.isSignedIn = true
                    isLoading = false
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        currentPage = 1
                    }
                }
                await appState.loadUserData()
            } catch {
                await MainActor.run {
                    errorMessage = "Sign up failed: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func triggerAppleSignIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        let delegate = AppleSignInDelegate { result in
            handleAppleSignIn(result)
        }
        controller.delegate = delegate
        controller.presentationContextProvider = delegate
        objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        controller.performRequests()
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
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
                        APIService.shared.setIsGuest(false)
                        
                        await MainActor.run {
                            appState.currentUser = response.user
                            appState.isSignedIn = true
                            isLoading = false
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                currentPage = 1
                            }
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
               authError.code == .canceled { return }
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }
    
    private func handlePetProfile() {
        guard !petName.isEmpty, !petBreed.isEmpty else {
            errorMessage = "Please fill in at least name and breed"
            return
        }
        
        errorMessage = nil
        isLoading = true
        
        let ageDouble = Double(petAge) ?? 0
        let weightDouble = Double(petWeight)
        let allergiesArray = petAllergies.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let healthConcernsArray = petHealthConditions.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let personalityArray = petPersonality.isEmpty ? nil : petPersonality.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        let localDog = Dog(
            name: petName,
            breed: petBreed,
            age: ageDouble,
            weight: weightDouble,
            healthConcerns: healthConcernsArray,
            allergies: allergiesArray,
            personalityTraits: personalityArray,
            sex: petGender
        )
        
        appState.saveDogLocally(localDog)
        
        if let w = weightDouble {
            WeightTrackingManager.shared.switchDog(localDog.id)
            let entry = WeightEntry(weight: w, date: Date(), note: "Initial profile weight")
            WeightTrackingManager.shared.addEntry(entry)
        }
        
        isLoading = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            currentPage = 2
        }
        
        Task {
            do {
                try await APIService.shared.createDogProfile(
                    name: petName,
                    breed: petBreed,
                    ageYears: Int(ageDouble),
                    weightLbs: weightDouble,
                    sex: petGender,
                    allergies: petAllergies.isEmpty ? nil : petAllergies,
                    medicalHistory: petHealthConditions.isEmpty ? nil : petHealthConditions
                )
            } catch {
                print("[Onboarding] Background dog sync failed: \(error)")
            }
        }
    }
}

struct InterestChip: View {
    let icon: String
    let title: String
    let isSelected: Bool
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
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : .petlyDarkGreen)
                    .frame(width: 20, height: 20)
                    .fixedSize()
                Text(title)
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(isSelected ? .white : .petlyDarkGreen)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 2)
                Text(isSelected ? "x" : "+")
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(isSelected ? .white : .petlyDarkGreen)
                    .frame(width: 20)
                    .fixedSize()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isSelected ? Color.petlyDarkGreen : Color.petlyLightGreen)
            .cornerRadius(8)
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    let completion: (Result<ASAuthorization, Error>) -> Void
    
    init(completion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.completion = completion
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
}

#Preview {
    NewOnboardingView()
        .environmentObject(AppState())
}
