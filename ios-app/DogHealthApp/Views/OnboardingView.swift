import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                OnboardingPageView(
                    title: "Welcome to Dog Health",
                    subtitle: "Your AI companion for dog care questions",
                    imageName: "heart.fill",
                    description: "Get helpful information about your dog's health, nutrition, and care from our AI assistant."
                )
                .tag(0)
                
                OnboardingPageView(
                    title: "Ask Questions",
                    subtitle: "Symptoms, food, vaccines & more",
                    imageName: "questionmark.circle.fill",
                    description: "Type any questions about your dog's symptoms, diet, vaccinations, or general care."
                )
                .tag(1)
                
                OnboardingPageView(
                    title: "Important Notice",
                    subtitle: "AI guidance, not medical advice",
                    imageName: "exclamationmark.triangle.fill",
                    description: "Our AI provides general information only. Always consult your veterinarian for medical concerns."
                )
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            
            Button(action: {
                if currentPage < 2 {
                    currentPage += 1
                } else {
                    appState.completeOnboarding()
                }
            }) {
                Text(currentPage < 2 ? "Next" : "Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
    }
}

struct OnboardingPageView: View {
    let title: String
    let subtitle: String
    let imageName: String
    let description: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: imageName)
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}
