import XCTest
@testable import GitStreakKit

final class MockContributionsTests: XCTestCase {
    
    func testEmptyMockData() {
        let empty = MockContributions.empty
        XCTAssertEqual(empty.totalContributions, 0)
        XCTAssertEqual(empty.currentStreak, 0)
        XCTAssertEqual(empty.longestStreak, 0)
        XCTAssertFalse(empty.weeks.isEmpty)
    }
    
    func testHighActivityMockData() {
        let high = MockContributions.highActivity
        XCTAssertGreaterThan(high.totalContributions, 0)
        XCTAssertGreaterThan(high.currentStreak, 0)
        XCTAssertGreaterThanOrEqual(high.longestStreak, high.currentStreak)
        XCTAssertEqual(high.weeks.count, 13)
    }
    
    func testAllDaysHelper() {
        let sample = MockContributions.highActivity
        XCTAssertEqual(sample.allDays.count, 91)
    }
    
    func testRecentDaysHelper() {
        let sample = MockContributions.highActivity
        let recent14 = sample.recentDays(count: 14)
        XCTAssertEqual(recent14.count, 14)
    }
}
