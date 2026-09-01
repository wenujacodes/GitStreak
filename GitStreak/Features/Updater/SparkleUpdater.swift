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

    public func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        isCheckingForUpdates = false
        lastStatusMessage = "Found update: Version \(item.displayVersionString)"
        #if DEBUG
        print("[SparkleUpdater] Found valid update version \(item.displayVersionString)")
        #endif
    }
}
