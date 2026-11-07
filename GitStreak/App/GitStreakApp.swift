import SwiftUI
import AppKit
import GitStreakKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var launchedAtLogin = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        // The launch event is only readable at this point.
        launchedAtLogin = BackgroundController.wasLaunchedAtLogin()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        StreakNotifier.shared.setUp()
        if UserPreferences.shared.hasCompletedOnboarding && StreakNotificationPreferences.load().enabled {
            Task { await StreakNotifier.shared.requestAuthorization() }
        }

        Task { @MainActor in
            SparkleUpdaterViewModel.shared.checkForUpdatesInBackground()
        }

        let background = BackgroundController.shared
        background.start()
        background.setUpLaunchAtLoginIfNeeded()
        if launchedAtLogin && UserPreferences.shared.hasCompletedOnboarding {
            background.startHidden()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        StreakNotifier.shared.removeScheduledReminders()
    }

    /// The user opened GitStreak again while it was running in the background.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        BackgroundController.shared.showApp()
        return true
    }

    /// Keep running after the window closes so widgets stay fresh,
    /// unless onboarding isn't finished yet (nothing to refresh).
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return !UserPreferences.shared.hasCompletedOnboarding
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
                    if StreakNotificationPreferences.load().enabled {
                        Task { await StreakNotifier.shared.requestAuthorization() }
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
