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
}
