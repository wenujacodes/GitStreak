import SwiftUI
import AppKit
import GitStreakKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            SparkleUpdaterViewModel.shared.checkForUpdatesInBackground()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
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
            CommandGroup(replacing: .appInfo) {
                Button("About GitStreak") {
                    showAboutPanel()
                }
            }
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    SparkleUpdaterViewModel.shared.checkForUpdates()
                }
            }
        }
    }

    @MainActor
    private func showAboutPanel() {
        NSApplication.shared.orderFrontStandardAboutPanel(options: [
            .applicationName: "GitStreak",
            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "Copyright © 2026 Wenuja Liyanamana. All rights reserved."
        ])
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
