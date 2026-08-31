import Foundation

/// Core service actor for fetching, calculating, and caching GitHub user contribution data.
public actor ContributionService {
    private let apiClient: GitHubAPIClient
    private let cacheManager: CacheManager

    public init(cacheManager: CacheManager = CacheManager()) {
        self.apiClient = GitHubAPIClient()
        self.cacheManager = cacheManager
    }

    /// Fetches contribution statistics from GitHub GraphQL API, processes streaks and stats, and updates local cache.
    /// - Parameters:
    ///   - username: GitHub account login name.
    ///   - token: GitHub access token string.
    ///   - year: Optional target calendar year filter.
    /// - Returns: Fully processed `ContributionData` domain object.
    public func fetchContributions(username: String, token: String, year: Int? = nil) async throws -> ContributionData {
        let (user, rawWeeks, totalContributions, activityStats, contributionYears) = try await apiClient.fetchContributions(username: username, token: token, year: year)

        let currentYear = Calendar.current.component(.year, from: Date())
        let weeks: [ContributionWeek]
        if year == nil || year == currentYear {
            weeks = Self.ensureDaysUpToToday(weeks: rawWeeks)
        } else {
            weeks = rawWeeks
        }

        let allDays = weeks.flatMap { $0.contributionDays }
        if allDays.isEmpty, let cached = cacheManager.load() {
            return cached
        }

        let cached = cacheManager.load()
        let calculatedTotal = allDays.reduce(0) { $0 + $1.contributionCount }
        let finalTotal = max(totalContributions, calculatedTotal)
        let currentStreakCount = StreakCalculator.currentStreak(days: allDays)
        let longestStreakCount = StreakCalculator.longestStreak(days: allDays)

        let accurateCommits = max(activityStats.commits, finalTotal - (activityStats.issues + activityStats.pullRequests + activityStats.reviews))
        let accurateStats = UserActivityStats(
            commits: max(accurateCommits, activityStats.commits),
            issues: activityStats.issues,
            pullRequests: activityStats.pullRequests,
            reviews: activityStats.reviews,
            repositories: activityStats.repositories,
            prAllCreated: activityStats.prAllCreated,
            prOpenCreated: activityStats.prOpenCreated,
            prCreated: activityStats.prCreated,
            prAssigned: activityStats.prAssigned,
            prMentioned: activityStats.prMentioned,
            prReviewRequested: activityStats.prReviewRequested,
            issuesAllCreated: activityStats.issuesAllCreated,
            issuesOpenCreated: activityStats.issuesOpenCreated,
            issuesAssigned: activityStats.issuesAssigned
        )

        let yearsList = contributionYears.isEmpty ? (cached?.availableYears ?? [2026, 2025, 2024, 2023, 2022]) : contributionYears

        let data = ContributionData(
            user: user,
            weeks: weeks,
            totalContributions: finalTotal,
            currentStreak: currentStreakCount,
            longestStreak: longestStreakCount,
            activityStats: accurateStats,
            availableYears: yearsList,
            selectedYear: year,
            fetchedAt: Date()
        )

        if year == nil {
            try? cacheManager.save(data)
        }
        return data
    }

    /// Ensures that the weeks array includes all days up to today's date in local time, adding empty cells for uncommitted days.
    public static func ensureDaysUpToToday(weeks: [ContributionWeek], timeZone: TimeZone = .current) -> [ContributionWeek] {
        guard !weeks.isEmpty else { return weeks }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = timeZone
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let todayString = formatter.string(from: Date())
        let allDays = weeks.flatMap { $0.contributionDays }
        guard let lastDay = allDays.last, lastDay.date < todayString else {
            return weeks
        }

        let utcFormatter = DateFormatter()
        utcFormatter.dateFormat = "yyyy-MM-dd"
        utcFormatter.timeZone = TimeZone(identifier: "UTC")
        utcFormatter.calendar = Calendar(identifier: .gregorian)
        utcFormatter.locale = Locale(identifier: "en_US_POSIX")

        guard var startDate = utcFormatter.date(from: lastDay.date),
              let endDate = utcFormatter.date(from: todayString) else {
            return weeks
        }

        var updatedWeeks = weeks
        let calendar = Calendar(identifier: .gregorian)

        while true {
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: startDate),
                  nextDate <= endDate else {
                break
            }
            startDate = nextDate
            let dateString = utcFormatter.string(from: nextDate)

            let weekdayComponent = calendar.component(.weekday, from: nextDate)
            let weekday = weekdayComponent - 1

            let newDay = ContributionDay(
                date: dateString,
                contributionCount: 0,
                level: .none,
                weekday: weekday
            )

            if var lastWeek = updatedWeeks.last, lastWeek.contributionDays.count < 7 && weekday != 0 {
                var updatedDays = lastWeek.contributionDays
                updatedDays.append(newDay)
                updatedWeeks[updatedWeeks.count - 1] = ContributionWeek(contributionDays: updatedDays)
            } else {
                updatedWeeks.append(ContributionWeek(contributionDays: [newDay]))
            }
        }

        return updatedWeeks
    }

    /// Returns locally cached `ContributionData` synchronously without hitting the network.
    nonisolated public func getCachedData() -> ContributionData? {
        guard let cached = cacheManager.load() else { return nil }
        let currentYear = Calendar.current.component(.year, from: Date())
        if cached.selectedYear == nil || cached.selectedYear == currentYear {
            let updatedWeeks = Self.ensureDaysUpToToday(weeks: cached.weeks)
            if updatedWeeks != cached.weeks {
                let allDays = updatedWeeks.flatMap { $0.contributionDays }
                return ContributionData(
                    user: cached.user,
                    weeks: updatedWeeks,
                    totalContributions: cached.totalContributions,
                    currentStreak: StreakCalculator.currentStreak(days: allDays),
                    longestStreak: StreakCalculator.longestStreak(days: allDays),
                    activityStats: cached.activityStats,
                    availableYears: cached.availableYears,
                    selectedYear: cached.selectedYear,
                    fetchedAt: cached.fetchedAt
                )
            }
        }
        return cached
    }

    /// Checks if local cache is still fresh within expiration window.
    nonisolated public func isCacheFresh() -> Bool {
        return cacheManager.isFresh()
    }

    /// Returns cached data if fresh, or fetches updated data from GitHub if cache has expired.
    public func refreshIfNeeded(username: String, token: String) async throws -> ContributionData {
        if isCacheFresh(), let cachedData = getCachedData() {
            return cachedData
        }
        return try await fetchContributions(username: username, token: token)
    }
}
