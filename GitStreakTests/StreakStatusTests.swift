import XCTest
@testable import GitStreakKit

final class StreakStatusTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func date(_ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
    }

    func testNothingTodayIsAtRiskButShowsDefaultText() {
        let status = StreakStatus(streak: 42, longest: 48, today: 0)
        XCTAssertTrue(status.isAtRisk)
        XCTAssertEqual(status.text, "0 today · best 48")
    }

    func testDoneToday() {
        let status = StreakStatus(streak: 42, longest: 48, today: 5)
        XCTAssertFalse(status.isAtRisk)
        XCTAssertEqual(status.text, "5 today · best 48")
    }

    func testRecord() {
        XCTAssertEqual(StreakStatus(streak: 49, longest: 49, today: 3).text, "Best streak ever")
    }

    func testOneDayStreakIsNotARecord() {
        XCTAssertEqual(StreakStatus(streak: 1, longest: 1, today: 2).text, "2 today · best 1")
    }

    func testNoStreak() {
        let status = StreakStatus(streak: 0, longest: 48, today: 0)
        XCTAssertFalse(status.isAtRisk)
        XCTAssertEqual(status.text, "Start a streak today")
    }

    func testWeekStartsOnSunday() {
        // Thursday 12 Nov 2026 → Sun 8 … Sat 14.
        let week = StreakStatus.weekDates(containing: date(12), calendar: calendar)
        XCTAssertEqual(week.first, "2026-11-08")
        XCTAssertEqual(week.last, "2026-11-14")
        XCTAssertEqual(week.count, 7)
    }

    func testWeekStartsOnSundayEvenWhenLocaleStartsOnMonday() {
        var monday = calendar
        monday.firstWeekday = 2
        XCTAssertEqual(StreakStatus.weekDates(containing: date(8), calendar: monday).first, "2026-11-08")
    }
}
