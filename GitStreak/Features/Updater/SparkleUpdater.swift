import SwiftUI
import Sparkle

@MainActor
public final class SparkleUpdaterViewModel: NSObject, ObservableObject, SPUUpdaterDelegate {
    public static let shared = SparkleUpdaterViewModel()

    public static let defaultFeedURL = "https://raw.githubusercontent.com/wenujacodes/GitStreak/main/appcast.xml"

    public private(set) var updaterController: SPUStandardUpdaterController!

    override private init() {
        super.init()
        self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
    }

    public func feedURLString(for updater: SPUUpdater) -> String? {
        return SparkleUpdaterViewModel.defaultFeedURL
    }

    public func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    public var automaticallyChecksForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }
}
