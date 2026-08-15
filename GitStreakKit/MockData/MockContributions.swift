import Foundation

public enum MockContributions {
    public static let sampleUser = GitHubUser(
        username: "octocat",
        displayName: "The Octocat",
        avatarURL: URL(string: "https://avatars.githubusercontent.com/u/583231"),
        bio: "GitHub's mascot"
    )
    
    // MARK: - Date Helpers
    
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    
    private static func dateString(daysAgo: Int) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
        return dateFormatter.string(from: date)
    }
    
    private static func weekday(daysAgo: Int) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
        // Sunday=0 through Saturday=6
        let w = calendar.component(.weekday, from: date)
        return w - 1  // Calendar uses 1=Sunday
    }
    
    private static func levelForCount(_ count: Int) -> ContributionLevel {
        switch count {
        case 0: return .none
        case 1...2: return .firstQuartile
        case 3...5: return .secondQuartile
        case 6...8: return .thirdQuartile
        default: return .fourthQuartile
        }
    }
    
    // MARK: - Data Generation
    
    private static func generateData(
        totalOverride: Int? = nil,
        currentStreakOverride: Int? = nil,
        longestStreakOverride: Int? = nil,
        activeProbability: Double,
        seed startSeed: Int = 12345
    ) -> ContributionData {
        let totalDays = 91  // 13 weeks
        var seed = startSeed
        
        func nextRand() -> Double {
            seed = (seed &* 1103515245 &+ 12345) & 0x7fffffff
            return Double(seed) / Double(0x7fffffff)
        }
        
        var allDays: [ContributionDay] = []
        var totalContributions = 0
        
        for i in stride(from: totalDays - 1, through: 0, by: -1) {
            let active = nextRand() < activeProbability
            let count = active ? Int(nextRand() * 10) + 1 : 0
            totalContributions += count
            
            let day = ContributionDay(
                date: dateString(daysAgo: i),
                contributionCount: count,
                level: levelForCount(count),
                weekday: weekday(daysAgo: i)
            )
            allDays.append(day)
        }
        
        // Group into weeks of 7
        var weeks: [ContributionWeek] = []
        for chunkStart in stride(from: 0, to: allDays.count, by: 7) {
            let end = min(chunkStart + 7, allDays.count)
            let chunk = Array(allDays[chunkStart..<end])
            weeks.append(ContributionWeek(contributionDays: chunk))
        }
        
        let currentStreak = currentStreakOverride ?? StreakCalculator.currentStreak(days: allDays)
        let longestStreak = longestStreakOverride ?? StreakCalculator.longestStreak(days: allDays)
        
        return ContributionData(
            user: sampleUser,
            weeks: weeks,
            totalContributions: totalOverride ?? totalContributions,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            fetchedAt: Date()
        )
    }
    
    // MARK: - Datasets
    
    public static let empty: ContributionData = generateData(
        totalOverride: 0,
        currentStreakOverride: 0,
        longestStreakOverride: 0,
        activeProbability: 0.0
    )
    
    public static let lowActivity: ContributionData = generateData(
        activeProbability: 0.2,
        seed: 22222
    )
    
    public static let highActivity: ContributionData = generateData(
        activeProbability: 0.85,
        seed: 33333
    )
    
    public static let longStreak: ContributionData = generateData(
        activeProbability: 0.97,
        seed: 44444
    )
    
    public static let brokenStreak: ContributionData = generateData(
        activeProbability: 0.5,
        seed: 55555
    )
    
    public static let activeToday: ContributionData = generateData(
        activeProbability: 0.65,
        seed: 66666
    )
    
    public static let inactiveToday: ContributionData = generateData(
        activeProbability: 0.6,
        seed: 77777
    )
    
    public static let singleDay: ContributionData = generateData(
        activeProbability: 0.01,
        seed: 88888
    )
}
