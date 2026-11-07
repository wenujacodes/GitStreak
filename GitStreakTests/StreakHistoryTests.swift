import XCTest
@testable import GitStreakKit

final class StreakHistoryTests: XCTestCase {

    /// Daily counts, the last one being `endDay`.
    private func days(_ counts: [Int], endingOn endDay: String) -> [ContributionDay] {
        counts.enumerated().map { i, count in
            ContributionDay(
                date: StreakHistory.addDays(endDay, i - (counts.count - 1)),
                contributionCount: count,
                level: count > 0 ? .firstQuartile : .none,
                weekday: 0)
        }
    }

    // Window: 2026-01-01 ... 2026-01-10 (10 days), today = 2026-01-10.
    private let today = "2026-01-10"

    func testShortStreakNeedsNothingOlder() {
        let window = days([1, 1, 0, 0, 0, 0, 0, 1, 1, 1], endingOn: today)
        let r = StreakHistory(username: "a").resolve(windowDays: window, today: today)
        XCTAssertEqual(r.currentStreak, 3)
        XCTAssertEqual(r.longestStreak, 3)
        XCTAssertFalse(r.needsBackfill)
    }

    func testStreakReachingWindowStartNeedsOlderYears() {
        let window = days(Array(repeating: 1, count: 10), endingOn: today)
        let r = StreakHistory(username: "a").resolve(windowDays: window, today: today)
        XCTAssertEqual(r.currentStreak, 10)
        XCTAssertTrue(r.needsBackfill)
    }

    func testBackfillExtendsStreakPastWindow() {
        let window = days(Array(repeating: 1, count: 10), endingOn: today)
        // 5 older active days right before the window, after a gap.
        let older = days([1, 0, 1, 1, 1, 1, 1], endingOn: "2025-12-31")
        let history = StreakHistory.backfilled(username: "a", olderDays: older, windowDays: window, attemptedAt: Date())
        let r = history.resolve(windowDays: window, today: today)
        XCTAssertEqual(r.currentStreak, 15)
        XCTAssertEqual(r.longestStreak, 15)
        XCTAssertFalse(r.needsBackfill)
    }

    func testStreakKeepsGrowingAsWindowMoves() {
        let window = days(Array(repeating: 1, count: 10), endingOn: today)
        let older = days([0, 1, 1, 1, 1, 1], endingOn: "2025-12-31")
        var history = StreakHistory.backfilled(username: "a", olderDays: older, windowDays: window, attemptedAt: Date())
        history = history.resolve(windowDays: window, today: today).history

        // Next day: the window starts one day later and has one new active day.
        let nextToday = "2026-01-11"
        let nextWindow = days(Array(repeating: 1, count: 10), endingOn: nextToday)
        let r = history.resolve(windowDays: nextWindow, today: nextToday)
        XCTAssertEqual(r.currentStreak, 16)
        XCTAssertFalse(r.needsBackfill)
    }

    func testTodayNotYetCountedKeepsYesterdaysStreak() {
        let window = days(Array(repeating: 1, count: 9) + [0], endingOn: today)
        let older = days([0, 1, 1], endingOn: "2025-12-31")
        let history = StreakHistory.backfilled(username: "a", olderDays: older, windowDays: window, attemptedAt: Date())
        XCTAssertEqual(history.resolve(windowDays: window, today: today).currentStreak, 11)
    }

    func testAllTimeBestFromOlderYears() {
        let window = days([1, 1, 0, 0, 0, 0, 0, 0, 1, 1], endingOn: today)
        let older = days(Array(repeating: 1, count: 30) + [0, 0], endingOn: "2025-12-31")
        let history = StreakHistory.backfilled(username: "a", olderDays: older, windowDays: window, attemptedAt: Date())
        let r = history.resolve(windowDays: window, today: today)
        XCTAssertEqual(r.currentStreak, 2)
        XCTAssertEqual(r.longestStreak, 30)
        XCTAssertTrue(history.includesOlderYears)
    }

    func testBestIncludesStreakCrossingIntoWindow() {
        // 4 older days + first 2 window days = 6, then a break.
        let window = days([1, 1, 0, 0, 0, 0, 0, 0, 0, 1], endingOn: today)
        let older = days([0, 1, 1, 1, 1], endingOn: "2025-12-31")
        let history = StreakHistory.backfilled(username: "a", olderDays: older, windowDays: window, attemptedAt: Date())
        XCTAssertEqual(history.resolve(windowDays: window, today: today).longestStreak, 6)
    }

    func testGapAfterOldRunIsNotJoined() {
        // History from an old streak; later a gap, and a new streak now fills the whole window.
        var history = StreakHistory(username: "a")
        history.runEnd = "2025-11-30"
        history.runLength = 50
        history.verifiedThrough = "2025-12-10"
        let window = days(Array(repeating: 1, count: 10), endingOn: today)
        let r = history.resolve(windowDays: window, today: today)
        XCTAssertEqual(r.currentStreak, 10)
        XCTAssertTrue(r.needsBackfill)
    }

    func testTrailingRun() {
        let d = days([1, 0, 1, 1, 1], endingOn: "2025-12-31")
        XCTAssertEqual(StreakHistory.trailingRun(days: d, endingOn: "2025-12-31"), 3)
        XCTAssertEqual(StreakHistory.trailingRun(days: d, endingOn: "2025-12-28"), 0)
    }
}
