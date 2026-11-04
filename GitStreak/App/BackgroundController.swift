import AppKit
import ServiceManagement
import GitStreakKit

/// Keeps GitStreak running in the background so the widgets stay up to date.
///
/// - Refreshes GitHub data every 5 minutes and after the Mac wakes from sleep.
/// - Hides the Dock icon when the window is closed; reopening the app brings it back.
/// - Manages launch at login (turned on once by default for installed copies).
@MainActor
final class BackgroundController {
    static let shared = BackgroundController()

    private static let refreshInterval: TimeInterval = 5 * 60
    private static let didSetUpLaunchAtLoginKey = "didSetUpLaunchAtLogin"

    private var scheduler: NSBackgroundActivityScheduler?
    private var observers: [NSObjectProtocol] = []

    private init() {}

    // MARK: - Background refresh

    func start() {
        guard scheduler == nil else { return }

        let scheduler = NSBackgroundActivityScheduler(identifier: "com.gitstreak.GitStreak.refresh")
        scheduler.repeats = true
        scheduler.interval = Self.refreshInterval
        scheduler.tolerance = 60
        scheduler.qualityOfService = .utility
        scheduler.schedule { completion in
            let box = CompletionBox(completion)
            Task { @MainActor in
                await BackgroundController.refresh()
                box.completion(.finished)
            }
        }
        self.scheduler = scheduler

        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { _ in
            Task { @MainActor in await BackgroundController.refresh() }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification, object: nil, queue: .main
        ) { _ in
            // Wait until the window has actually closed before checking.
            DispatchQueue.main.async {
                MainActor.assumeIsolated { BackgroundController.shared.hideDockIconIfNoWindows() }
            }
        })
    }

    private static func refresh() async {
        let prefs = UserPreferences.shared
        guard prefs.hasCompletedOnboarding, let username = prefs.username, !username.isEmpty else { return }
        // Errors (offline, rate limit) are fine: widgets keep showing the last cached data.
        _ = try? await SharedDataStore.shared.refreshData(force: false)
    }

    // MARK: - Window and Dock icon

    /// Called when the app was launched at login: run without a window or Dock icon.
    func startHidden() {
        NSApp.setActivationPolicy(.accessory)
        DispatchQueue.main.async {
            for window in NSApp.windows where window.isVisible {
                window.close()
            }
        }
    }

    /// Called when the user opens the app again while it runs in the background.
    func showApp() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }

    private func hideDockIconIfNoWindows() {
        guard UserPreferences.shared.hasCompletedOnboarding else { return }
        let hasVisibleWindow = NSApp.windows.contains { $0.isVisible && $0.canBecomeMain }
        if !hasVisibleWindow {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    /// True when macOS started the app as a login item (as opposed to the user opening it).
    /// Must be called while the launch event is being handled (applicationWillFinishLaunching).
    static func wasLaunchedAtLogin() -> Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent,
              event.eventID == kAEOpenApplication else {
            return false
        }
        return event.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }

    // MARK: - Launch at login

    var launchAtLoginStatus: SMAppService.Status {
        SMAppService.mainApp.status
    }

    func setLaunchAtLogin(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    /// Turns launch at login on the first time an installed copy runs.
    /// If the user later turns it off, it stays off.
    func setUpLaunchAtLoginIfNeeded() {
        guard Self.isInstalledCopy,
              !UserDefaults.standard.bool(forKey: Self.didSetUpLaunchAtLoginKey) else {
            return
        }
        UserDefaults.standard.set(true, forKey: Self.didSetUpLaunchAtLoginKey)
        try? SMAppService.mainApp.register()
    }

    /// Only register copies in an Applications folder, never test or build-folder copies.
    private static var isInstalledCopy: Bool {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return false
        }
        let path = Bundle.main.bundlePath
        return path.hasPrefix("/Applications/") || path.hasPrefix(NSHomeDirectory() + "/Applications/")
    }
}

private final class CompletionBox: @unchecked Sendable {
    let completion: NSBackgroundActivityScheduler.CompletionHandler

    init(_ completion: @escaping NSBackgroundActivityScheduler.CompletionHandler) {
        self.completion = completion
    }
}
