import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "pawprint.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Dog Health App")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("AI-Powered Guidance for Dog Owners")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 20) {
                DisclaimerText()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Button(action: {
                appState.hasCompletedOnboarding = true
            }) {
                Text("I Understand")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct DisclaimerText: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("Important Disclaimer", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.orange)
            
            Text("This app provides educational guidance and information only.")
                .font(.subheadline)
            
            Text("It is NOT a substitute for professional veterinary care and does NOT provide medical diagnoses or veterinary advice.")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Always consult with a licensed veterinarian for medical concerns about your pet.")
                .font(.subheadline)
            
            Text("By continuing, you acknowledge that you understand this app is for educational purposes only.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
