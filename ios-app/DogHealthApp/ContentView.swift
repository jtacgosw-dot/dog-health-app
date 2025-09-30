import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else if !appState.hasAcceptedDisclaimer {
                DisclaimerView()
            } else if !appState.isAuthenticated {
                SignInView()
            } else if appState.isLoading {
                LoadingView()
            } else if !appState.hasActiveSubscription {
                PaywallView()
            } else {
                ChatView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}
