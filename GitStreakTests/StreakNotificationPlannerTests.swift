import XCTest
@testable import GitStreakKit

final class StreakNotificationPlannerTests: XCTestCase {

    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Colombo")!
        return c
    }()

    /// Local time on a given day (2026-11-06 is a Friday, 2026-11-08 a Sunday).
    private func at(_ day: String, _ hour: Int, _ minute: Int = 0) -> Date {
        let p = day.split(separator: "-").map { Int($0)! }
        return calendar.date(from: DateComponents(year: p[0], month: p[1], day: p[2], hour: hour, minute: minute))!
    }

    /// Daily counts, the last one being `endDay`.
    private func days(_ counts: [Int], endingOn endDay: String = "2026-11-06") -> [ContributionDay] {
        counts.enumerated().map { i, count in
            ContributionDay(
                date: StreakNotificationPlanner.addDays(endDay, i - (counts.count - 1)),
                contributionCount: count,
                level: count > 0 ? .firstQuartile : .none,
                weekday: 0)
        }
    }

    private func state(streak: Int, longest: Int) -> StreakNotificationState {
        StreakNotificationState(lastStreak: streak, lastLongest: longest)
    }

    private func plan(_ d: [ContributionDay], _ s: StreakNotificationState?, at now: Date,
                      settings: StreakNotificationSettings = StreakNotificationSettings()) -> StreakNotificationPlan {
        StreakNotificationPlanner.plan(days: d, previous: s, settings: settings, now: now, calendar: calendar)
    }

    // MARK: - First run

    func testFirstRunOnlyRecordsBaseline() {
        let d = days([0, 1, 1, 1, 1])
        let result = plan(d, nil, at: at("2026-11-06", 19))
        XCTAssertTrue(result.notifications.isEmpty)
        XCTAssertEqual(result.state.lastStreak, 4)
        XCTAssertEqual(result.state.extendedDate, "2026-11-06")
    }

    // MARK: - At risk / last call

    func testRemindersScheduledAheadForExactTime() {
        let d = days([0, 1, 1, 1, 0]) // 3-day streak, nothing today
        let morning = plan(d, state(streak: 3, longest: 3), at: at("2026-11-06", 10))
        XCTAssertEqual(morning.notifications.map(\.kind), [.lastCall, .atRisk])
        XCTAssertEqual(morning.notifications.first { $0.kind == .atRisk }?.deliverAt, at("2026-11-06", 18))
        XCTAssertEqual(morning.notifications.first { $0.kind == .lastCall }?.deliverAt, at("2026-11-06", 23))
        XCTAssertEqual(morning.notifications.first { $0.kind == .atRisk }?.title, "🔥 Your 3-day streak is at risk")

        // After 6 PM macOS has shown it: not sent again, only the last call stays scheduled.
        let evening = plan(d, morning.state, at: at("2026-11-06", 18, 5))
        XCTAssertEqual(evening.notifications.map(\.kind), [.lastCall])
        XCTAssertNotNil(evening.notifications.first?.deliverAt)

        // After 11 PM both were shown: nothing more.
        XCTAssertTrue(plan(d, evening.state, at: at("2026-11-06", 23, 5)).notifications.isEmpty)
    }

    func testAtRiskSentNowWhenTimeAlreadyPassed() {
        let d = days([0, 1, 1, 1, 0])
        let result = plan(d, state(streak: 3, longest: 3), at: at("2026-11-06", 19))
        XCTAssertEqual(result.notifications.first { $0.kind == .atRisk }?.deliverAt, nil)
        XCTAssertTrue(plan(d, result.state, at: at("2026-11-06", 19, 5)).notifications.allSatisfy { $0.kind == .lastCall })
    }

    func testAtRiskSentNowWithinAMinuteOfTime() {
        let d = days([0, 1, 1, 0])
        let result = plan(d, state(streak: 2, longest: 2), at: at("2026-11-06", 17, 59))
        let atRisk = result.notifications.first { $0.kind == .atRisk }
        XCTAssertNotNil(atRisk)
        XCTAssertNil(atRisk?.deliverAt)
    }

    func testCustomReminderTime() {
        var settings = StreakNotificationSettings()
        settings.atRiskMinutes = 20 * 60 + 30
        let d = days([0, 1, 1, 0])
        let result = plan(d, state(streak: 2, longest: 2), at: at("2026-11-06", 12), settings: settings)
        XCTAssertEqual(result.notifications.first { $0.kind == .atRisk }?.deliverAt, at("2026-11-06", 20, 30))
    }

    func testNoRemindersAfterContributing() {
        let d = days([0, 1, 1, 1]) // contributed today
        var s = state(streak: 2, longest: 10)
        s.extendedDate = "2026-11-06"
        let result = plan(d, s, at: at("2026-11-06", 12))
        XCTAssertTrue(result.notifications.isEmpty)
        XCTAssertTrue(result.contributedToday)
    }

    func testNoAtRiskWithoutStreak() {
        let d = days([1, 0, 0])
        XCTAssertTrue(plan(d, state(streak: 0, longest: 1), at: at("2026-11-06", 19)).notifications.isEmpty)
    }

    func testLastCallSentNowIfNeverScheduled() {
        var settings = StreakNotificationSettings()
        settings.lastCall = false
        let d = days([0, 1, 1, 0])
        let risk = plan(d, state(streak: 2, longest: 2), at: at("2026-11-06", 18), settings: settings)
        XCTAssertEqual(risk.notifications.map(\.kind), [.atRisk])

        // Last call turned on later in the evening: nothing was scheduled, so it goes out now.
        let last = plan(d, risk.state, at: at("2026-11-06", 23, 2))
        XCTAssertEqual(last.notifications.map(\.kind), [.lastCall])
        XCTAssertNil(last.notifications.first?.deliverAt)
        XCTAssertTrue(plan(d, last.state, at: at("2026-11-06", 23, 30)).notifications.isEmpty)
    }

    func testLastCallReplacesAtRiskWhenMacWakesLate() {
        let d = days([0, 1, 1, 0])
        let result = plan(d, state(streak: 2, longest: 2), at: at("2026-11-06", 23, 10))
        XCTAssertEqual(result.notifications.map(\.kind), [.lastCall])
        XCTAssertEqual(result.state.atRiskDate, "2026-11-06")
    }

    // MARK: - Extended / record / milestone

    func testExtendedOncePerDay() {
        let d = days([0, 1, 1, 1, 1]) // today counted: 4 days
        let first = plan(d, state(streak: 3, longest: 10), at: at("2026-11-06", 10))
        XCTAssertEqual(first.notifications.map(\.kind), [.extended])
        XCTAssertEqual(first.notifications.first?.title, "Streak extended to 4 days")
        XCTAssertTrue(first.contributedToday)
        XCTAssertTrue(plan(d, first.state, at: at("2026-11-06", 11)).notifications.isEmpty)
    }

    func testNewStreakStarted() {
        let d = days([1, 0, 1])
        let result = plan(d, state(streak: 0, longest: 5), at: at("2026-11-06", 10))
        XCTAssertEqual(result.notifications.first?.title, "New streak started")
    }

    func testNewRecordOncePerStreak() {
        let today = days([0, 1, 1, 1, 1, 1]) // 5 days, old best 4
        let record = plan(today, state(streak: 4, longest: 4), at: at("2026-11-06", 10))
        XCTAssertEqual(record.notifications.map(\.kind), [.record])
        XCTAssertEqual(record.notifications.first?.title, "🏆 New longest streak: 5 days!")

        // Next day the streak grows again: plain "extended", not another record.
        let tomorrow = days([0, 1, 1, 1, 1, 1, 1], endingOn: "2026-11-07")
        let next = plan(tomorrow, record.state, at: at("2026-11-07", 10))
        XCTAssertEqual(next.notifications.map(\.kind), [.extended])
    }

    func testMilestone() {
        let d = days([0] + Array(repeating: 1, count: 7))
        let result = plan(d, state(streak: 6, longest: 20), at: at("2026-11-06", 10))
        XCTAssertEqual(result.notifications.map(\.kind), [.milestone])
        XCTAssertEqual(result.notifications.first?.title, "🎉 7-day streak!")
    }

    func testRecordWinsOverMilestone() {
        let d = days([0] + Array(repeating: 1, count: 7))
        let result = plan(d, state(streak: 6, longest: 6), at: at("2026-11-06", 10))
        XCTAssertEqual(result.notifications.map(\.kind), [.record])
    }

    func testDisabledExtendedDoesNotFireLaterSameDay() {
        var off = StreakNotificationSettings()
        off.extended = false
        let d = days([0, 1, 1, 1])
        let first = plan(d, state(streak: 2, longest: 10), at: at("2026-11-06", 10), settings: off)
        XCTAssertTrue(first.notifications.isEmpty)
        XCTAssertTrue(plan(d, first.state, at: at("2026-11-06", 11)).notifications.isEmpty)
    }

    func testUsesStreakIncludingOlderYears() {
        // The window only shows 5 days, but with older years the streak is 400 days (record was 399).
        let d = days([1, 1, 1, 1, 1])
        let result = StreakNotificationPlanner.plan(
            days: d, currentStreak: 400, longestStreak: 400,
            previous: state(streak: 399, longest: 399),
            settings: StreakNotificationSettings(), now: at("2026-11-06", 10), calendar: calendar)
        XCTAssertEqual(result.notifications.first?.title, "🏆 New longest streak: 400 days!")
    }

    func testNoFalseRecordWhenOlderBestIsHigher() {
        let d = days([0, 1, 1, 1, 1, 1]) // 5 days; best in this window was 4, but 60 two years ago
        let result = StreakNotificationPlanner.plan(
            days: d, currentStreak: 5, longestStreak: 60,
            previous: state(streak: 4, longest: 60),
            settings: StreakNotificationSettings(), now: at("2026-11-06", 10), calendar: calendar)
        XCTAssertEqual(result.notifications.map(\.kind), [.extended])
    }

    // MARK: - Streak lost

    func testStreakLostDeliveredInTheMorning() {
        let d = days([1, 1, 1, 0, 0]) // yesterday and today empty
        let result = plan(d, state(streak: 3, longest: 3), at: at("2026-11-06", 0, 5))
        XCTAssertEqual(result.notifications.map(\.kind), [.streakLost])
        XCTAssertEqual(result.notifications.first?.deliverAt, at("2026-11-06", 9))
        XCTAssertFalse(result.streakAlive)
        XCTAssertTrue(plan(d, result.state, at: at("2026-11-06", 0, 10)).notifications.isEmpty)
    }

    func testStreakLostImmediateAfterMorning() {
        let d = days([1, 1, 1, 0, 0])
        let result = plan(d, state(streak: 3, longest: 3), at: at("2026-11-06", 12))
        XCTAssertNil(result.notifications.first?.deliverAt)
    }

    func testNoStreakLostForOneDayStreak() {
        let d = days([1, 0, 0])
        XCTAssertTrue(plan(d, state(streak: 1, longest: 1), at: at("2026-11-06", 12)).notifications.isEmpty)
    }

    // MARK: - Weekly recap

    func testWeeklyRecapOnSundayEvening() {
        // Previous week: 10 total; this week (Mon–Sun): 15 total, best day Wednesday (5).
        let counts: [Int] = [1, 1, 2, 2, 1, 2, 1, 2, 1, 5, 2, 2, 2, 1]
        let d = days(counts, endingOn: "2026-11-08")
        var s = state(streak: 14, longest: 14)
        s.extendedDate = "2026-11-08"

        XCTAssertTrue(plan(d, s, at: at("2026-11-08", 19, 59)).notifications.isEmpty)

        let recap = plan(d, s, at: at("2026-11-08", 20))
        XCTAssertEqual(recap.notifications.map(\.kind), [.weeklyRecap])
        XCTAssertEqual(recap.notifications.first?.body,
                       "15 contributions this week, up 50% from last week. Best day: Wednesday (5).")
        XCTAssertTrue(plan(d, recap.state, at: at("2026-11-08", 21)).notifications.isEmpty)
    }

    func testNoWeeklyRecapOnOtherDays() {
        let d = days(Array(repeating: 1, count: 14))
        var s = state(streak: 14, longest: 14)
        s.extendedDate = "2026-11-06"
        XCTAssertTrue(plan(d, s, at: at("2026-11-06", 21)).notifications.isEmpty)
    }

    // MARK: - Master switch

    func testMasterSwitchOffSendsNothingButKeepsTrack() {
        var off = StreakNotificationSettings()
        off.enabled = false
        let d = days([0, 1, 1, 1, 0])
        let result = plan(d, state(streak: 3, longest: 3), at: at("2026-11-06", 19), settings: off)
        XCTAssertTrue(result.notifications.isEmpty)
        XCTAssertEqual(result.state.atRiskDate, "2026-11-06")
    }
}
