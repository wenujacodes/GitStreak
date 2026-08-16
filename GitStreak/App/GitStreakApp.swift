import SwiftUI
import AppKit
import GitStreakKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct GitStreakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        Settings {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    SparkleUpdaterViewModel.shared.checkForUpdates()
                }
            }
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
