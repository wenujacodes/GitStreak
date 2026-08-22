import Foundation

public struct ContributionData: Codable, Sendable, Equatable {
    public let user: GitHubUser
    public let weeks: [ContributionWeek]
    public let totalContributions: Int
    public let currentStreak: Int
    public let longestStreak: Int
    public let fetchedAt: Date

    public init(user: GitHubUser, weeks: [ContributionWeek], totalContributions: Int, currentStreak: Int, longestStreak: Int, fetchedAt: Date = Date()) {
        self.user = user
        self.weeks = weeks
        self.totalContributions = totalContributions
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.fetchedAt = fetchedAt
    }

    public var allDays: [ContributionDay] {
        return weeks.flatMap { $0.contributionDays }
    }

    public func recentDays(count: Int) -> [ContributionDay] {
        let days = allDays
        guard count < days.count else { return days }
        return Array(days.suffix(count))
    }
}
