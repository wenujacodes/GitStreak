import XCTest
@testable import GitStreakKit

final class StreakStatusTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func date(_ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 11, hour: hour, minute: minute))!
    }

    func testAtRiskWhenNothingToday() {
        let status = StreakStatus(streak: 42, longest: 48, today: 0, now: date(18), calendar: calendar)
        XCTAssertTrue(status.isAtRisk)
        XCTAssertEqual(status.text, "Commit today · 6h left")
    }

    func testAtRiskWinsOverRecord() {
        let status = StreakStatus(streak: 48, longest: 48, today: 0, now: date(18), calendar: calendar)
        XCTAssertTrue(status.isAtRisk)
    }

    func testMinutesInLastHour() {
        XCTAssertEqual(StreakStatus.timeLeft(from: date(23, 15), calendar: calendar), "45m left")
    }

    func testDoneToday() {
        let status = StreakStatus(streak: 42, longest: 48, today: 5, now: date(18), calendar: calendar)
        XCTAssertFalse(status.isAtRisk)
        XCTAssertEqual(status.text, "5 today · best 48")
    }

    func testRecord() {
        let status = StreakStatus(streak: 49, longest: 49, today: 3, now: date(18), calendar: calendar)
        XCTAssertEqual(status.text, "Best streak ever")
    }

    func testOneDayStreakIsNotARecord() {
        let status = StreakStatus(streak: 1, longest: 1, today: 2, now: date(18), calendar: calendar)
        XCTAssertEqual(status.text, "2 today · best 1")
    }

    func testNoStreak() {
        let status = StreakStatus(streak: 0, longest: 48, today: 0, now: date(18), calendar: calendar)
        XCTAssertFalse(status.isAtRisk)
        XCTAssertEqual(status.text, "Start a streak today")
    }
}
