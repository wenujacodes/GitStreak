import XCTest
@testable import GitStreakKit

final class StreakCalculatorTests: XCTestCase {

    func testEmptyDays() {
        let result = StreakCalculator.currentStreak(days: [], referenceDate: "2025-08-15")
        XCTAssertEqual(result, 0)
    }

    func testAllZeroDays() {
        let days = (0..<7).map { i in
            ContributionDay(
                date: "2025-08-\(String(format: "%02d", 9 + i))",
                contributionCount: 0,
                level: .none,
                weekday: i
            )
        }
        let result = StreakCalculator.currentStreak(days: days, referenceDate: "2025-08-15")
        XCTAssertEqual(result, 0)
    }

    func testSingleActiveDay() {
        let days = [
            ContributionDay(date: "2025-08-15", contributionCount: 3, level: .firstQuartile, weekday: 5)
        ]
        let result = StreakCalculator.currentStreak(days: days, referenceDate: "2025-08-15")
        XCTAssertEqual(result, 1)
    }

    func testSevenConsecutiveDays() {
        let days = (0..<7).map { i in
            ContributionDay(
                date: "2025-08-\(String(format: "%02d", 9 + i))",
                contributionCount: i + 1,
                level: .firstQuartile,
                weekday: i
            )
        }
        let result = StreakCalculator.currentStreak(days: days, referenceDate: "2025-08-15")
        XCTAssertEqual(result, 7)
    }

    func testStreakEndingYesterday() {

        let days = [
            ContributionDay(date: "2025-08-13", contributionCount: 2, level: .firstQuartile, weekday: 3),
            ContributionDay(date: "2025-08-14", contributionCount: 5, level: .secondQuartile, weekday: 4),
            ContributionDay(date: "2025-08-15", contributionCount: 0, level: .none, weekday: 5),
        ]
        let result = StreakCalculator.currentStreak(days: days, referenceDate: "2025-08-15")
        XCTAssertEqual(result, 2)
    }

    func testStreakContinuingToday() {
        let days = [
            ContributionDay(date: "2025-08-13", contributionCount: 2, level: .firstQuartile, weekday: 3),
            ContributionDay(date: "2025-08-14", contributionCount: 5, level: .secondQuartile, weekday: 4),
            ContributionDay(date: "2025-08-15", contributionCount: 1, level: .firstQuartile, weekday: 5),
        ]
        let result = StreakCalculator.currentStreak(days: days, referenceDate: "2025-08-15")
        XCTAssertEqual(result, 3)
    }

    func testStreakBrokenByGap() {
        let days = [
            ContributionDay(date: "2025-08-12", contributionCount: 3, level: .firstQuartile, weekday: 2),
            ContributionDay(date: "2025-08-13", contributionCount: 0, level: .none, weekday: 3),
            ContributionDay(date: "2025-08-14", contributionCount: 5, level: .secondQuartile, weekday: 4),
            ContributionDay(date: "2025-08-15", contributionCount: 1, level: .firstQuartile, weekday: 5),
        ]
        let result = StreakCalculator.currentStreak(days: days, referenceDate: "2025-08-15")
        XCTAssertEqual(result, 2)
    }

    func testNoContributionsTodayOrYesterday() {
        let days = [
            ContributionDay(date: "2025-08-13", contributionCount: 5, level: .secondQuartile, weekday: 3),
            ContributionDay(date: "2025-08-14", contributionCount: 0, level: .none, weekday: 4),
            ContributionDay(date: "2025-08-15", contributionCount: 0, level: .none, weekday: 5),
        ]
        let result = StreakCalculator.currentStreak(days: days, referenceDate: "2025-08-15")
        XCTAssertEqual(result, 0)
    }

    func testLongestStreakEmpty() {
        let result = StreakCalculator.longestStreak(days: [])
        XCTAssertEqual(result, 0)
    }

    func testLongestStreakAllZeros() {
        let days = (0..<7).map { i in
            ContributionDay(
                date: "2025-08-\(String(format: "%02d", 9 + i))",
                contributionCount: 0,
                level: .none,
                weekday: i
            )
        }
        let result = StreakCalculator.longestStreak(days: days)
        XCTAssertEqual(result, 0)
    }

    func testLongestStreakSingleDay() {
        let days = [
            ContributionDay(date: "2025-08-15", contributionCount: 1, level: .firstQuartile, weekday: 5)
        ]
        let result = StreakCalculator.longestStreak(days: days)
        XCTAssertEqual(result, 1)
    }

    func testLongestVsCurrentStreak() {

        let days = [

            ContributionDay(date: "2025-08-05", contributionCount: 1, level: .firstQuartile, weekday: 2),
            ContributionDay(date: "2025-08-06", contributionCount: 2, level: .firstQuartile, weekday: 3),
            ContributionDay(date: "2025-08-07", contributionCount: 3, level: .firstQuartile, weekday: 4),
            ContributionDay(date: "2025-08-08", contributionCount: 4, level: .secondQuartile, weekday: 5),
            ContributionDay(date: "2025-08-09", contributionCount: 5, level: .secondQuartile, weekday: 6),

            ContributionDay(date: "2025-08-10", contributionCount: 0, level: .none, weekday: 0),
            ContributionDay(date: "2025-08-11", contributionCount: 0, level: .none, weekday: 1),
            ContributionDay(date: "2025-08-12", contributionCount: 0, level: .none, weekday: 2),
            ContributionDay(date: "2025-08-13", contributionCount: 0, level: .none, weekday: 3),

            ContributionDay(date: "2025-08-14", contributionCount: 1, level: .firstQuartile, weekday: 4),
            ContributionDay(date: "2025-08-15", contributionCount: 2, level: .firstQuartile, weekday: 5),
        ]
        let longest = StreakCalculator.longestStreak(days: days)
        let current = StreakCalculator.currentStreak(days: days, referenceDate: "2025-08-15")
        XCTAssertEqual(longest, 5)
        XCTAssertEqual(current, 2)
    }

    func testConsecutiveDays() {
        XCTAssertTrue(StreakCalculator.areConsecutiveDays("2025-08-14", "2025-08-15"))
        XCTAssertFalse(StreakCalculator.areConsecutiveDays("2025-08-13", "2025-08-15"))
        XCTAssertTrue(StreakCalculator.areConsecutiveDays("2025-08-31", "2025-09-01"))
        XCTAssertTrue(StreakCalculator.areConsecutiveDays("2025-12-31", "2026-01-01"))
    }

    func testStreakWhenTodayNotInDatasetYet() {
        // Cached data ends yesterday (2025-08-14) with active streak
        let days = [
            ContributionDay(date: "2025-08-13", contributionCount: 2, level: .firstQuartile, weekday: 3),
            ContributionDay(date: "2025-08-14", contributionCount: 5, level: .secondQuartile, weekday: 4),
        ]
        // Today is 2025-08-15 (not in dataset yet because new day just started)
        let result = StreakCalculator.currentStreak(days: days, referenceDate: "2025-08-15")
        XCTAssertEqual(result, 2, "Streak should continue from yesterday if today is not in dataset yet")

        // If reference date is 2 days later, streak should be broken
        let brokenResult = StreakCalculator.currentStreak(days: days, referenceDate: "2025-08-16")
        XCTAssertEqual(brokenResult, 0)
    }

    func testTodayDateStringWithTimezone() {
        let utcDate = StreakCalculator.todayDateString(timeZone: TimeZone(identifier: "UTC")!)
        XCTAssertFalse(utcDate.isEmpty)
        XCTAssertEqual(utcDate.count, 10)
    }

    func testTodayContributionsOnlyMatchesToday() {
        let today = StreakCalculator.todayDateString()
        let yesterday = "2020-01-01"

        let user = GitHubUser(username: "test", displayName: nil, avatarURL: nil, bio: nil)
        let daysWithYesterday = [
            ContributionDay(date: yesterday, contributionCount: 99, level: .fourthQuartile, weekday: 0)
        ]
        let week1 = ContributionWeek(contributionDays: daysWithYesterday)
        let dataYesterday = ContributionData(user: user, weeks: [week1], totalContributions: 99, currentStreak: 1, longestStreak: 1)

        XCTAssertEqual(dataYesterday.todayContributions, 0, "Should return 0 if dataset only has yesterday's commits")

        let daysWithToday = [
            ContributionDay(date: today, contributionCount: 7, level: .secondQuartile, weekday: 0)
        ]
        let week2 = ContributionWeek(contributionDays: daysWithToday)
        let dataToday = ContributionData(user: user, weeks: [week2], totalContributions: 7, currentStreak: 1, longestStreak: 1)

        XCTAssertEqual(dataToday.todayContributions, 7, "Should return exact count when today matches")
    }
}
