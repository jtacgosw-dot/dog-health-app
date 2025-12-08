import SwiftUI

struct NewOnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedInterests: Set<String> = []
    @State private var currentPage = 0
    
    let interests = [
        ("🍖", "Nutrition"),
        ("🐕", "Behavior"),
        ("💚", "Wellness"),
        ("🎾", "Training"),
        ("🏃", "Activity"),
        ("🧠", "Mental Health"),
        ("🦷", "Dental Care"),
        ("👴", "Senior Care")
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
            
            Text("🐾")
                .font(.system(size: 80))
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
            Text("What areas are you most")
                .font(.petlyTitle(24))
                .foregroundColor(.petlyDarkGreen)
            
            Text("excited to use?")
                .font(.petlyTitle(24))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Select all that apply")
                .font(.petlyBody(14))
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
            
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    appState.hasCompletedOnboarding = true
                }
            }) {
                Text("Continue")
                    .font(.petlyBodyMedium(16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedInterests.isEmpty ? Color.petlyFormIcon : Color.petlyDarkGreen)
                    .cornerRadius(25)
            }
            .disabled(selectedInterests.isEmpty)
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
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 32))
                Text(title)
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.petlyDarkGreen)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? Color.petlyLightGreen : Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.petlyDarkGreen : Color.petlyLightGreen, lineWidth: isSelected ? 2 : 1)
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

#Preview {
    NewOnboardingView()
        .environmentObject(AppState())
}
