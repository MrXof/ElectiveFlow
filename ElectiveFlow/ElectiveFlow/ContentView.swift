import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if !appState.hasSeenOnboarding {
                OnboardingView()
            } else if appState.currentUser == nil {
                LoginView()
            } else {
                MainTabView()
            }
        }
        .preferredColorScheme(appState.isDarkMode ? .dark : .light)
    }
}
