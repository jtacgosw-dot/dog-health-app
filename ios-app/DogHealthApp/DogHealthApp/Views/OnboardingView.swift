import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedInterests: Set<String> = []
    @State private var currentPage = 0
    
    let interests = [
        "Increasing My Pet's Wellbeing",
        "Nutrition",
        "Tips & Tricks",
        "Activity & Energy"
    ]
    
    var body: some View {
        ZStack {
            Color.petlyCream
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
                .font(.system(size: 48, weight: .bold, design: .serif))
                .foregroundColor(.petlyDarkGreen)
            
            Image(systemName: "pawprint.fill")
                .font(.system(size: 80))
                .foregroundColor(.petlyDarkGreen)
                .padding(.vertical, 20)
            
            Text("Smart care tailored with love")
                .font(.title3)
                .foregroundColor(.petlyDarkGreen)
                .multilineTextAlignment(.center)
            
            Text("AI THAT KNOWS YOUR PET")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.petlyDarkGreen)
                .padding(.top, 10)
            
            Text("Using AI, Petly tailors food, supplement, and lifestyle recommendations to your pet's unique age, breed, size, and health needs — helping them live longer, happier, and healthier lives.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 5)
            
            Button(action: {
                withAnimation {
                    currentPage = 1
                }
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.petlyDarkGreen)
                    .cornerRadius(PetlyTheme.buttonCornerRadius)
            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
    }
    
    var interestsPage: some View {
        VStack(spacing: 20) {
            Text("What areas of")
                .font(.title2)
                .foregroundColor(.black)
            
            HStack(spacing: 0) {
                Text("Petly")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .underline()
                Text(" are you most")
                    .font(.title2)
                    .foregroundColor(.black)
            }
            
            Text("excited to use?")
                .font(.title2)
                .foregroundColor(.black)
            
            Text("Let's personalize your experience!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 10)
            
            VStack(spacing: 12) {
                ForEach(interests, id: \.self) { interest in
                    InterestButton(
                        title: interest,
                        isSelected: selectedInterests.contains(interest)
                    ) {
                        if selectedInterests.contains(interest) {
                            selectedInterests.remove(interest)
                        } else {
                            selectedInterests.insert(interest)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            Image(systemName: "pawprint.fill")
                .font(.system(size: 60))
                .foregroundColor(.petlyDarkGreen.opacity(0.3))
                .padding(.top, 20)
            
            Button(action: {
                appState.hasCompletedOnboarding = true
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedInterests.isEmpty ? Color.gray : Color.petlyDarkGreen)
                    .cornerRadius(PetlyTheme.buttonCornerRadius)
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
                    .fill(index == currentPage ? Color.petlyDarkGreen : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

struct InterestButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : .petlyDarkGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSelected ? Color.petlySageGreen : Color.white)
                .cornerRadius(PetlyTheme.buttonCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: PetlyTheme.buttonCornerRadius)
                        .stroke(Color.petlySageGreen, lineWidth: 1)
                )
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
