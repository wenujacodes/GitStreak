import XCTest
@testable import GitStreakKit

final class StreakWeekTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func date(_ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: 12))!
    }

    func testWeekStartsOnSunday() {
        // Thursday 12 Nov 2026 → Sun 8 … Sat 14.
        let week = StreakWeek.dates(containing: date(12), calendar: calendar)
        XCTAssertEqual(week.count, 7)
        XCTAssertEqual(week.first, "2026-11-08")
        XCTAssertEqual(week.last, "2026-11-14")
    }

    func testWeekStartsOnSundayEvenWhenLocaleStartsOnMonday() {
        var monday = calendar
        monday.firstWeekday = 2
        XCTAssertEqual(StreakWeek.dates(containing: date(8), calendar: monday).first, "2026-11-08")
    }
}
