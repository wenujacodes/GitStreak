import Foundation

/// What GitStreak knows about contributions older than the 12-month window it fetches every 5 minutes.
///
/// Without it, a streak longer than a year would be cut off at the window's first day, and the
/// longest streak would only be the longest of the past year. It is filled once from older years
/// (`backfilled`) and then kept up to date from the normal window data (`resolve`).
public struct StreakHistory: Codable, Equatable, Sendable {
    public var username: String
    /// Best streak ever seen, including older years.
    public var allTimeLongest: Int = 0
    /// Active days in a row ending on `runEnd`, the day before the window started.
    public var runEnd: String?
    public var runLength: Int = 0
    /// Every day after `runEnd` up to this day was seen active, so the old run still connects.
    public var verifiedThrough: String?
    /// Last time older years were fetched (successfully or not), to avoid retrying too often.
    public var lastBackfillAttempt: Date?
    /// True once older years were read successfully, so `allTimeLongest` covers the whole history.
    public var includesOlderYears = false

    public init(username: String) {
        self.username = username
    }

    public struct Resolution: Equatable, Sendable {
        public let currentStreak: Int
        public let longestStreak: Int
        /// The streak reaches the window's first day but the older part is unknown: fetch older years.
        public let needsBackfill: Bool
        public let history: StreakHistory
    }

    /// Current and longest streak for the window, extended with the older data this history holds.
    public func resolve(windowDays: [ContributionDay], today: String) -> Resolution {
        let days = windowDays.sorted { $0.date < $1.date }
        let windowStreak = StreakCalculator.currentStreak(days: days, referenceDate: today)
        let windowLongest = StreakCalculator.longestStreak(days: days)
        var updated = self

        var current = windowStreak
        var needsBackfill = false

        if let windowStart = days.first?.date, windowStreak > 0 {
            let todayCount = days.first(where: { $0.date == today })?.contributionCount ?? 0
            let streakEnd = todayCount > 0 ? today : Self.addDays(today, -1)
            let streakStart = Self.addDays(streakEnd, -(windowStreak - 1))

            if streakStart <= windowStart {
                if let earlier = earlierRunLength(before: windowStart) {
                    current = windowStreak + earlier
                    updated.runEnd = Self.addDays(windowStart, -1)
                    updated.runLength = earlier
                    updated.verifiedThrough = streakEnd
                } else {
                    needsBackfill = true
                }
            }
        }

        let longest = max(allTimeLongest, windowLongest, current)
        updated.allTimeLongest = longest
        return Resolution(currentStreak: current, longestStreak: longest, needsBackfill: needsBackfill, history: updated)
    }

    /// Active days in a row ending the day before `windowStart`, if this history can tell.
    func earlierRunLength(before windowStart: String) -> Int? {
        guard let runEnd, let verifiedThrough, runEnd < windowStart else { return nil }
        let dayBefore = Self.addDays(windowStart, -1)
        guard verifiedThrough >= dayBefore || runEnd == dayBefore else { return nil }
        return runLength + Self.daysBetween(runEnd, dayBefore)
    }

    /// A history built from older years (`olderDays`) plus the current window.
    public static func backfilled(username: String, olderDays: [ContributionDay], windowDays: [ContributionDay], attemptedAt: Date) -> StreakHistory {
        var history = StreakHistory(username: username)
        history.lastBackfillAttempt = attemptedAt
        history.includesOlderYears = true
        guard let windowStart = windowDays.map(\.date).min() else { return history }

        // Window data wins where both have the same day.
        var byDate: [String: ContributionDay] = [:]
        for day in olderDays where day.date < windowStart { byDate[day.date] = day }
        for day in windowDays { byDate[day.date] = day }
        let merged = byDate.values.sorted { $0.date < $1.date }

        let dayBefore = addDays(windowStart, -1)
        history.allTimeLongest = StreakCalculator.longestStreak(days: merged)
        history.runEnd = dayBefore
        history.runLength = trailingRun(days: merged, endingOn: dayBefore)
        history.verifiedThrough = dayBefore
        return history
    }

    /// Active days in a row ending on `day` (0 if that day had no contributions).
    static func trailingRun(days: [ContributionDay], endingOn day: String) -> Int {
        let counts = Dictionary(days.map { ($0.date, $0.contributionCount) }, uniquingKeysWith: max)
        var run = 0
        var cursor = day
        while (counts[cursor] ?? 0) > 0 {
            run += 1
            cursor = addDays(cursor, -1)
        }
        return run
    }

    // MARK: - Day strings ("yyyy-MM-dd")

    private static let utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private static func parse(_ day: String) -> Date? {
        let p = day.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return nil }
        return utc.date(from: DateComponents(year: p[0], month: p[1], day: p[2]))
    }

    static func addDays(_ day: String, _ offset: Int) -> String {
        guard let date = parse(day), let moved = utc.date(byAdding: .day, value: offset, to: date) else { return day }
        let c = utc.dateComponents([.year, .month, .day], from: moved)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func daysBetween(_ from: String, _ to: String) -> Int {
        guard let a = parse(from), let b = parse(to) else { return 0 }
        return utc.dateComponents([.day], from: a, to: b).day ?? 0
    }
}
