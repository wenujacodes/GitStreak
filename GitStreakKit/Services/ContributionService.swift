import Foundation

public actor ContributionService {
    private let apiClient: GitHubAPIClient
    private let cacheManager: CacheManager

    public init(cacheManager: CacheManager = CacheManager()) {
        self.apiClient = GitHubAPIClient()
        self.cacheManager = cacheManager
    }

    public func fetchContributions(username: String, token: String) async throws -> ContributionData {
        let (user, weeks, totalContributions) = try await apiClient.fetchContributions(username: username, token: token)

        let allDays = weeks.flatMap { $0.contributionDays }
        let currentStreakCount = StreakCalculator.currentStreak(days: allDays)
        let longestStreakCount = StreakCalculator.longestStreak(days: allDays)

        let data = ContributionData(
            user: user,
            weeks: weeks,
            totalContributions: totalContributions,
            currentStreak: currentStreakCount,
            longestStreak: longestStreakCount,
            fetchedAt: Date()
        )

        try cacheManager.save(data)
        return data
    }

    nonisolated public func getCachedData() -> ContributionData? {
        return cacheManager.load()
    }

    nonisolated public func isCacheFresh() -> Bool {
        return cacheManager.isFresh()
    }

    public func refreshIfNeeded(username: String, token: String) async throws -> ContributionData {
        if isCacheFresh(), let cachedData = getCachedData() {
            return cachedData
        }
        return try await fetchContributions(username: username, token: token)
    }
}
