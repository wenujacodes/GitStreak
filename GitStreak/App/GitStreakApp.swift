import SwiftUI
import AppKit
import GitStreakKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var backgroundRefreshTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        startBackgroundRefreshTimer()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    private func startBackgroundRefreshTimer() {
        backgroundRefreshTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { _ in
            Task {
                _ = try? await SharedDataStore.shared.refreshData(force: false)
            }
        }
    }
}

@main
struct GitStreakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

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
            if !hasCompletedOnboarding {
                CommandGroup(replacing: .appSettings) { }
            }
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
        ZStack {
            if hasCompletedOnboarding {
                DashboardView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                OnboardingView(onComplete: {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        UserPreferences.shared.hasCompletedOnboarding = true
                        hasCompletedOnboarding = true
                    }
                })
                .transition(.opacity.combined(with: .scale(scale: 1.02)))
            }
        }
        .animation(.easeInOut(duration: 0.45), value: hasCompletedOnboarding)
        .onReceive(NotificationCenter.default.publisher(for: .userPreferencesDidChange)) { _ in
            withAnimation(.easeInOut(duration: 0.45)) {
                self.hasCompletedOnboarding = UserPreferences.shared.hasCompletedOnboarding
            }
        }
    }
}
