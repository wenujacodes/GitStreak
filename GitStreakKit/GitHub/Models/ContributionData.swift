import Foundation

public struct ContributionData: Codable, Sendable, Equatable {
    public let user: GitHubUser
    public let weeks: [ContributionWeek]
    public let totalContributions: Int
    public let currentStreak: Int
    public let longestStreak: Int
    public let activityStats: UserActivityStats
    public let fetchedAt: Date

    public init(
        user: GitHubUser,
        weeks: [ContributionWeek],
        totalContributions: Int,
        currentStreak: Int,
        longestStreak: Int,
        activityStats: UserActivityStats = UserActivityStats(),
        fetchedAt: Date = Date()
    ) {
        self.user = user
        self.weeks = weeks
        self.totalContributions = totalContributions
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.activityStats = activityStats
        self.fetchedAt = fetchedAt
    }

    enum CodingKeys: String, CodingKey {
        case user, weeks, totalContributions, currentStreak, longestStreak, activityStats, fetchedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.user = try container.decode(GitHubUser.self, forKey: .user)
        self.weeks = try container.decode([ContributionWeek].self, forKey: .weeks)
        self.totalContributions = try container.decode(Int.self, forKey: .totalContributions)
        self.currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        self.longestStreak = try container.decode(Int.self, forKey: .longestStreak)
        self.activityStats = try container.decodeIfPresent(UserActivityStats.self, forKey: .activityStats) ?? UserActivityStats(commits: self.totalContributions)
        self.fetchedAt = try container.decodeIfPresent(Date.self, forKey: .fetchedAt) ?? Date()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user, forKey: .user)
        try container.encode(weeks, forKey: .weeks)
        try container.encode(totalContributions, forKey: .totalContributions)
        try container.encode(currentStreak, forKey: .currentStreak)
        try container.encode(longestStreak, forKey: .longestStreak)
        try container.encode(activityStats, forKey: .activityStats)
        try container.encode(fetchedAt, forKey: .fetchedAt)
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
