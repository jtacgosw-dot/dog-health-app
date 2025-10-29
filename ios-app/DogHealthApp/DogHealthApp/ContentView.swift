import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else if !appState.isSignedIn {
                SignInView()
            } else if !appState.hasActiveSubscription {
                PaywallView()
            } else {
                ChatView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
