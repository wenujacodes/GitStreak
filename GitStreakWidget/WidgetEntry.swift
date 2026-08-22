import Foundation
import WidgetKit
import GitStreakKit

public enum WidgetState: Sendable {
    case loaded
    case noData
    case noUser
    case error(String)
}

public struct GitStreakEntry: TimelineEntry, Sendable {
    public let date: Date
    public let contributionData: ContributionData?
    public let theme: ThemeColors
    public let state: WidgetState
    public let username: String?

    public init(date: Date, contributionData: ContributionData?, theme: ThemeColors, state: WidgetState, username: String?) {
        self.date = date
        self.contributionData = contributionData
        self.theme = theme
        self.state = state
        self.username = username
    }

    public static var placeholder: GitStreakEntry {
        GitStreakEntry(
            date: Date(),
            contributionData: MockContributions.highActivity,
            theme: ThemeRegistry.github,
            state: .loaded,
            username: "jappleseed"
        )
    }
}
