import SwiftUI
import GitStreakKit

@main
struct GitStreakApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        
        Settings {
            SettingsView()
        }
    }
}

struct ContentView: View {
    @State private var hasCompletedOnboarding = UserPreferences.shared.hasCompletedOnboarding
    
    var body: some View {
        if hasCompletedOnboarding {
            DashboardView()
        } else {
            OnboardingView(onComplete: {
                UserPreferences.shared.hasCompletedOnboarding = true
                hasCompletedOnboarding = true
            })
        }
    }
}
