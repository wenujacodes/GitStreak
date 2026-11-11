import SwiftUI
import Sparkle

@MainActor
public final class SparkleUpdaterViewModel: NSObject, ObservableObject, SPUUpdaterDelegate {
    public static let shared = SparkleUpdaterViewModel()

    public static let defaultFeedURL = "https://raw.githubusercontent.com/wenujacodes/GitStreak/main/appcast.xml"

    public private(set) var updaterController: SPUStandardUpdaterController!

    @Published public var isCheckingForUpdates: Bool = false
    @Published public var lastStatusMessage: String?

    override private init() {
        super.init()
        self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
    }

    public func feedURLString(for updater: SPUUpdater) -> String? {
        #if DEBUG
        // Release testing only: point a Debug build at a local feed with
        // `defaults write com.gitstreak.GitStreak GitStreakTestFeedURL http://127.0.0.1:8765/appcast.xml`.
        // Release builds always use the real feed.
        if let testFeed = UserDefaults.standard.string(forKey: "GitStreakTestFeedURL"), !testFeed.isEmpty {
            return testFeed
        }
        #endif
        return SparkleUpdaterViewModel.defaultFeedURL
    }

    public func checkForUpdates() {
        lastStatusMessage = nil
        isCheckingForUpdates = true
        updaterController.checkForUpdates(nil)
    }

    public func checkForUpdatesInBackground() {
        updaterController.updater.checkForUpdatesInBackground()
    }

    public var canCheckForUpdates: Bool {
        updaterController.updater.canCheckForUpdates
    }

    public var automaticallyChecksForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }

    // MARK: - SPUUpdaterDelegate

    public func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        isCheckingForUpdates = false
        let nsError = error as NSError
        if nsError.code == 1001 || error.localizedDescription.localizedCaseInsensitiveContains("up to date") {
            lastStatusMessage = "GitStreak is up to date."
        } else {
            lastStatusMessage = "Update check failed: \(error.localizedDescription)"
        }
        #if DEBUG
        print("[SparkleUpdater] Update check finished: \(error.localizedDescription)")
        #endif
    }

    public func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        isCheckingForUpdates = false
        lastStatusMessage = "GitStreak is up to date."
        #if DEBUG
        print("[SparkleUpdater] No updates available.")
        #endif
    }

    // MARK: - Installing without the user

    /// Set by Sparkle once an update has downloaded; calling it installs and relaunches.
    private var pendingInstall: (() -> Void)?

    /// When set, the next launch is the relaunch after a silent update and should stay hidden.
    public static let relaunchHiddenKey = "relaunchHiddenAfterUpdate"

    /// Sparkle installs downloaded updates when the app quits, but GitStreak keeps running
    /// in the background. Install right away instead, unless the user has the window open;
    /// then wait until they close it.
    public func updater(
        _ updater: SPUUpdater,
        willInstallUpdateOnQuit item: SUAppcastItem,
        immediateInstallationBlock immediateInstallHandler: @escaping () -> Void
    ) -> Bool {
        pendingInstall = immediateInstallHandler
        installPendingUpdateIfIdle()
        return true
    }

    /// Installs a downloaded update if no GitStreak window is open. Called again when a window closes.
    public func installPendingUpdateIfIdle() {
        guard let install = pendingInstall else { return }
        let hasOpenWindow = NSApp.windows.contains { $0.isVisible && $0.canBecomeMain }
        guard !hasOpenWindow else { return }
        pendingInstall = nil
        UserDefaults.standard.set(true, forKey: Self.relaunchHiddenKey)
        install()
    }

    public func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        isCheckingForUpdates = false
        lastStatusMessage = "Found update: Version \(item.displayVersionString)"
        #if DEBUG
        print("[SparkleUpdater] Found valid update version \(item.displayVersionString)")
        #endif
    }
}
