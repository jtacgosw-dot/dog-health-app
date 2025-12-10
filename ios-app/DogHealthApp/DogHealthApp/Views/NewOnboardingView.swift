import SwiftUI

struct NewOnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedInterests: Set<String> = []
    @State private var currentPage = 0
    
    let interests = [
        ("carrot", "Nutrition"),
        ("pawprint", "Behavior"),
        ("heart", "Wellness"),
        ("figure.walk", "Recipes"),
        ("shower", "Grooming"),
        ("figure.run", "Training"),
        ("chart.bar", "Tracking"),
        ("tooth", "Dental"),
        ("pills", "Supplements"),
        ("dumbbell", "Fitness"),
        ("leaf", "Longevity"),
        ("cross.case", "Vet-Care")
    ]
    
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                if currentPage == 0 {
                    welcomePage
                } else {
                    interestsPage
                }
                
                Spacer()
                
                pageIndicator
                    .padding(.bottom, 40)
            }
            .padding()
        }
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
    
    var interestsPage: some View {
        VStack(spacing: 20) {
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
            
            Text("Now, let's pick")
                .font(.petlyTitle(28))
                .foregroundColor(.petlyDarkGreen)
            
            Text("your interests.")
                .font(.petlyTitle(28))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Personalize your experience to make sure")
                .font(.petlyBody(13))
                .foregroundColor(.petlyFormIcon)
            
            Text("the needs of your furry-friend are met!")
                .font(.petlyBody(13))
                .foregroundColor(.petlyFormIcon)
                .padding(.bottom, 10)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(interests, id: \.1) { emoji, title in
                    InterestChip(
                        emoji: emoji,
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
            
            VStack(spacing: 16) {
                Image("dogCatOutline")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(height: 90)
                    .foregroundColor(.petlyDarkGreen)
                    .opacity(0.4)
                
                Button(action: {
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
            .padding(.top, 10)
        }
    }
    
    var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<2) { index in
                Circle()
                    .fill(index == currentPage ? Color.petlyDarkGreen : Color.petlyFormIcon.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
}

struct InterestChip: View {
    let emoji: String
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
                Image(systemName: emoji)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : .petlyDarkGreen)
                Text(title)
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(isSelected ? .white : .petlyDarkGreen)
                Spacer()
                if isSelected {
                    Text("x")
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.white)
                } else {
                    Text("+")
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.petlyDarkGreen)
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
