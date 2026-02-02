import SwiftUI

struct NewOnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedInterests: Set<String> = []
    @State private var currentPage = 0
    @State private var ownerName: String = ""
    
    let interests = [
        ("leaf.fill", "Nutrition"),
        ("pawprint.fill", "Behavior"),
        ("heart.fill", "Wellness"),
        ("fork.knife", "Recipes"),
        ("scissors", "Grooming"),
        ("figure.run", "Training"),
        ("chart.bar.fill", "Tracking"),
        ("mouth.fill", "Dental"),
        ("pills.fill", "Supplements"),
        ("dumbbell.fill", "Fitness"),
        ("leaf.circle.fill", "Longevity"),
        ("stethoscope", "Vet-Care")
    ]
    
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                if currentPage == 0 {
                    welcomePage
                } else if currentPage == 1 {
                    nameInputPage
                } else {
                    interestsPage
                }
                
                Spacer()
                
                pageIndicator
                    .padding(.bottom, 40)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
    
    var welcomePage: some View {
        VStack(spacing: 20) {
            Text("Petly")
                .font(.petlyTitle(48))
                .foregroundColor(.petlyDarkGreen)
            
            Image(systemName: "pawprint.fill")
                .font(.system(size: 80))
                .foregroundColor(.petlyDarkGreen)
                .padding(.vertical, 20)
            
            Text("Smart care tailored with love")
                .font(.petlyBodyMedium(18))
                .foregroundColor(.petlyDarkGreen)
                .multilineTextAlignment(.center)
            
            Text("AI THAT KNOWS YOUR PET")
                .font(.petlyBodyMedium(12))
                .foregroundColor(.petlyDarkGreen)
                .padding(.top, 10)
            
            Text("Using AI, Petly tailors food, supplement, and lifestyle recommendations to your pet's unique age, breed, size, and health needs — helping them live longer, happier, and healthier lives.")
                .font(.petlyBody(14))
                .foregroundColor(.petlyFormIcon)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 5)
            
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    currentPage = 1
                }
            }) {
                Text("Get Started")
                    .font(.petlyBodyMedium(16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.petlyDarkGreen)
                    .cornerRadius(25)
            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
    }
    
    var nameInputPage: some View {
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
            .padding(.bottom, 20)
            
            Text("What's your name?")
                .font(.petlyTitle(28))
                .foregroundColor(.petlyDarkGreen)
                .padding(.bottom, 10)
            
            Text("We'll use this to personalize your experience")
                .font(.petlyBody(14))
                .foregroundColor(.petlyFormIcon)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 30)
            
            TextField("Your name", text: $ownerName)
                .font(.petlyBody(18))
                .padding()
                .background(Color.petlyLightGreen)
                .cornerRadius(12)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: {
                // Save the name to the user
                if var user = appState.currentUser {
                    user.fullName = ownerName.isEmpty ? nil : ownerName
                    appState.currentUser = user
                    // Save to UserDefaults for persistence
                    UserDefaults.standard.set(ownerName, forKey: "ownerName")
                } else if !ownerName.isEmpty {
                    // Create a user with the name if one doesn't exist
                    UserDefaults.standard.set(ownerName, forKey: "ownerName")
                }
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    currentPage = 2
                }
            }) {
                Text("CONTINUE")
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.petlyDarkGreen)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .onAppear {
            // Pre-fill with existing name if available
            if let existingName = appState.currentUser?.fullName {
                ownerName = existingName
            } else if let savedName = UserDefaults.standard.string(forKey: "ownerName") {
                ownerName = savedName
            }
        }
    }
    
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
            
            Text("Now, let's pick")
                .font(.petlyTitle(28))
                .foregroundColor(.petlyDarkGreen)
            
            Text("your interests.")
                .font(.petlyTitle(28))
                .foregroundColor(.petlyDarkGreen)
                .padding(.bottom, 10)
            
            Text("Personalize your experience to make sure")
                .font(.petlyBody(13))
                .foregroundColor(.petlyFormIcon)
            
            Text("the needs of your furry-friend are met!")
                .font(.petlyBody(13))
                .foregroundColor(.petlyFormIcon)
                .padding(.bottom, 20)
            
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
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 0) {
                Image("dogCatOutline")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(height: 200)
                    .foregroundColor(.petlyDarkGreen)
                    .opacity(0.7)
                    .padding(.bottom, -72)
                
                Button(action: {
                    UserDefaults.standard.set(Array(selectedInterests), forKey: "userInterests")
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        appState.hasCompletedOnboarding = true
                    }
                }) {
                    Text("NEXT STEP")
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedInterests.isEmpty ? Color.petlyFormIcon : Color.petlyDarkGreen)
                        .cornerRadius(8)
                }
                .disabled(selectedInterests.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index == currentPage ? Color.petlyDarkGreen : Color.petlyFormIcon.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
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
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : .petlyDarkGreen)
                Text(title)
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(isSelected ? .white : .petlyDarkGreen)
                    .lineLimit(1)
                    .layoutPriority(1)
                Spacer(minLength: 4)
            }
            .overlay(alignment: .trailing) {
                if isSelected {
                    Text("x")
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.white)
                        .padding(.trailing, 16)
                } else {
                    Text("+")
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.petlyDarkGreen)
                        .padding(.trailing, 16)
                }
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

#Preview {
    NewOnboardingView()
        .environmentObject(AppState())
}
