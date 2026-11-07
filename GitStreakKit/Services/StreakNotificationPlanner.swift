import Foundation

/// Which streak notifications the user wants. Stored by the app; passed in here.
public struct StreakNotificationSettings: Equatable, Sendable {
    public var enabled = true
    public var atRisk = true
    /// Minutes after midnight for the "streak at risk" reminder (default 6 PM).
    public var atRiskMinutes = 18 * 60
    public var lastCall = true
    public var extended = true
    public var record = true
    public var milestones = true
    public var streakLost = true
    public var weeklyRecap = true

    public init() {}
}

/// What the planner remembers between refreshes, so each notification fires once.
public struct StreakNotificationState: Codable, Equatable, Sendable {
    public var lastStreak: Int
    public var lastLongest: Int
    /// Days ("yyyy-MM-dd") on which each notification was already handled.
    public var extendedDate: String?
    public var atRiskDate: String?
    public var lastCallDate: String?
    public var streakLostDate: String?
    public var weeklyRecapDate: String?
    /// Start day of the streak a "new record" was already sent for.
    public var recordStreakStart: String?
    /// When today's reminders were scheduled with macOS. Once that time has passed, macOS has shown them.
    public var atRiskScheduledFor: Date?
    public var lastCallScheduledFor: Date?

    public init(lastStreak: Int, lastLongest: Int) {
        self.lastStreak = lastStreak
        self.lastLongest = lastLongest
    }
}

public enum StreakNotificationKind: String, CaseIterable, Sendable {
    case atRisk, lastCall, extended, record, milestone, streakLost, weeklyRecap

    /// One identifier per kind, so a new notification replaces the previous one of the same kind.
    public var identifier: String { "com.gitstreak.notification.\(rawValue)" }
}

public struct StreakNotification: Equatable, Sendable {
    public let kind: StreakNotificationKind
    public let title: String
    public let body: String
    /// When to show it. `nil` means right away. At-risk reminders are scheduled ahead so macOS
    /// shows them on time even while GitStreak is napping in the background.
    public let deliverAt: Date?

    public init(kind: StreakNotificationKind, title: String, body: String, deliverAt: Date?) {
        self.kind = kind
        self.title = title
        self.body = body
        self.deliverAt = deliverAt
    }
}

public struct StreakNotificationPlan: Equatable, Sendable {
    public var notifications: [StreakNotification] = []
    /// True once there is a contribution today: pending reminders should be removed
    /// and delivered "at risk" banners cleared. Pending at-risk and last-call reminders that
    /// aren't in `notifications` should always be removed (they are re-added on every refresh).
    public var contributedToday = false
    /// False when the streak is broken. When true, a pending "streak lost" must be removed
    /// (GitHub can show a late contribution for yesterday after midnight).
    public var streakAlive = false
    public var state: StreakNotificationState
}

/// Decides which streak notifications to send after each data refresh.
/// Pure logic (no system calls) so it can be unit tested.
public enum StreakNotificationPlanner {
    public static let milestones = [7, 30, 50, 100, 150, 200, 365, 500, 1000]
    static let lastCallMinutes = 23 * 60
    static let streakLostDeliveryHour = 9
    static let weeklyRecapMinutes = 20 * 60
    /// Sunday in Calendar's weekday numbering.
    static let weeklyRecapWeekday = 1

    /// - Parameters:
    ///   - currentStreak, longestStreak: the numbers including older years (see `StreakHistory`).
    ///     When nil they are counted from `days` alone.
    public static func plan(
        days: [ContributionDay],
        currentStreak: Int? = nil,
        longestStreak: Int? = nil,
        previous: StreakNotificationState?,
        settings: StreakNotificationSettings,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> StreakNotificationPlan {
        let today = dateString(now, calendar: calendar)
        let todayCount = days.first(where: { $0.date == today })?.contributionCount ?? 0
        let streak = currentStreak ?? StreakCalculator.currentStreak(days: days, referenceDate: today)
        let longest = longestStreak ?? StreakCalculator.longestStreak(days: days)

        var state = previous ?? StreakNotificationState(lastStreak: streak, lastLongest: longest)
        var plan = StreakNotificationPlan(contributedToday: todayCount > 0, streakAlive: streak > 0, state: state)

        // First run: just remember the current numbers, so nothing old gets announced.
        guard previous != nil else {
            if todayCount > 0 { state.extendedDate = today }
            plan.state = state
            return plan
        }

        var notes: [StreakNotification] = []
        let minutesNow = minutesSinceMidnight(now, calendar: calendar)

        // 1. A contribution today: extended / new record / milestone (one notification).
        if todayCount > 0 && state.extendedDate != today {
            state.extendedDate = today
            let streakStart = addDays(today, -(streak - 1))
            let isRecord = streak >= 3 && streak > state.lastLongest && state.recordStreakStart != streakStart
            let milestone = milestones.last { state.lastStreak < $0 && $0 <= streak }

            if isRecord && settings.record {
                state.recordStreakStart = streakStart
                notes.append(StreakNotification(
                    kind: .record,
                    title: "🏆 New longest streak: \(dayCount(streak))!",
                    body: "You beat your previous best of \(dayCount(state.lastLongest)). Keep it going tomorrow.",
                    deliverAt: nil))
            } else if let m = milestone, settings.milestones {
                if isRecord { state.recordStreakStart = streakStart }
                notes.append(StreakNotification(
                    kind: .milestone,
                    title: "🎉 \(m)-day streak!",
                    body: "You've contributed \(m) days in a row. Nice work.",
                    deliverAt: nil))
            } else if settings.extended {
                if isRecord { state.recordStreakStart = streakStart }
                notes.append(streak <= 1
                    ? StreakNotification(
                        kind: .extended,
                        title: "New streak started",
                        body: "Day 1 done. Contribute again tomorrow to make it 2 days.",
                        deliverAt: nil)
                    : StreakNotification(
                        kind: .extended,
                        title: "Streak extended to \(dayCount(streak))",
                        body: "Today's contribution is in. See you tomorrow.",
                        deliverAt: nil))
            } else if isRecord {
                state.recordStreakStart = streakStart
            }
        }

        // 2. No contribution yet today and a streak to lose: at risk / last call.
        //    Before their time they are scheduled with macOS (so they arrive on the minute);
        //    if their time has already passed (Mac was asleep, app just started) they go out now.
        if todayCount == 0 && streak > 0 {
            if let t = state.atRiskScheduledFor, t <= now, dateString(t, calendar: calendar) == today {
                state.atRiskDate = today
            }
            if let t = state.lastCallScheduledFor, t <= now, dateString(t, calendar: calendar) == today {
                state.lastCallDate = today
                state.atRiskDate = today
            }

            let lastCallAt = time(lastCallMinutes, on: now, calendar: calendar)
            let atRiskAt = time(settings.atRiskMinutes, on: now, calendar: calendar)
            // Within a minute of the time, send now rather than schedule a moment that may already be gone.
            let soon = now.addingTimeInterval(60)
            let lastCallText = "Push a contribution before midnight to keep your \(dayLabel(streak)) streak."

            if settings.lastCall && state.lastCallDate != today {
                if soon >= lastCallAt {
                    // Covers the at-risk reminder too if the Mac was asleep until now.
                    state.lastCallDate = today
                    state.atRiskDate = today
                    notes.append(StreakNotification(kind: .lastCall, title: "Less than an hour left", body: lastCallText, deliverAt: nil))
                } else {
                    state.lastCallScheduledFor = lastCallAt
                    notes.append(StreakNotification(kind: .lastCall, title: "Less than an hour left", body: lastCallText, deliverAt: lastCallAt))
                }
            }

            if settings.atRisk && state.atRiskDate != today {
                let title = "🔥 Your \(dayLabel(streak)) streak is at risk"
                let body = "No contributions yet today. Push a commit before midnight to keep it going."
                if soon >= atRiskAt {
                    state.atRiskDate = today
                    notes.append(StreakNotification(kind: .atRisk, title: title, body: body, deliverAt: nil))
                } else {
                    state.atRiskScheduledFor = atRiskAt
                    notes.append(StreakNotification(kind: .atRisk, title: title, body: body, deliverAt: atRiskAt))
                }
            }
        }

        // 3. Streak broken (nothing yesterday or today): gentle note in the morning.
        if streak == 0 && todayCount == 0 && state.lastStreak >= 2 && state.streakLostDate != today {
            state.streakLostDate = today
            if settings.streakLost {
                notes.append(StreakNotification(
                    kind: .streakLost,
                    title: "Your \(dayLabel(state.lastStreak)) streak ended",
                    body: "Every streak starts with day 1. Make a contribution today to start a new one.",
                    deliverAt: morningDelivery(now, calendar: calendar)))
            }
        }

        // 4. Weekly recap on Sunday evening.
        if calendar.component(.weekday, from: now) == weeklyRecapWeekday
            && minutesNow >= weeklyRecapMinutes
            && state.weeklyRecapDate != today {
            state.weeklyRecapDate = today
            if settings.weeklyRecap {
                notes.append(weeklyRecap(days: days, today: today, calendar: calendar))
            }
        }

        state.lastStreak = streak
        state.lastLongest = longest
        plan.state = state
        plan.notifications = settings.enabled ? notes : []
        return plan
    }

    // MARK: - Weekly recap

    static func weeklyRecap(days: [ContributionDay], today: String, calendar: Calendar) -> StreakNotification {
        let counts = Dictionary(days.map { ($0.date, $0.contributionCount) }, uniquingKeysWith: max)
        let thisWeek = (0..<7).map { addDays(today, -$0) }
        let lastWeek = (7..<14).map { addDays(today, -$0) }
        let thisTotal = thisWeek.reduce(0) { $0 + (counts[$1] ?? 0) }
        let lastTotal = lastWeek.reduce(0) { $0 + (counts[$1] ?? 0) }

        guard thisTotal > 0 else {
            return StreakNotification(
                kind: .weeklyRecap,
                title: "Your week on GitHub",
                body: "No contributions this week. A fresh week starts tomorrow.",
                deliverAt: nil)
        }

        var parts = ["\(thisTotal) contribution\(thisTotal == 1 ? "" : "s") this week"]
        if lastTotal > 0 {
            let change = Int((Double(thisTotal - lastTotal) / Double(lastTotal) * 100).rounded())
            if change > 0 { parts.append("up \(change)% from last week") }
            else if change < 0 { parts.append("down \(-change)% from last week") }
            else { parts.append("same as last week") }
        }
        var body = parts.joined(separator: ", ") + "."

        // Best day: highest count, latest day wins a tie.
        if let best = thisWeek.reversed().max(by: { (counts[$0] ?? 0) < (counts[$1] ?? 0) }),
           let bestDate = parseDay(best) {
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.timeZone = TimeZone(identifier: "UTC")
            formatter.dateFormat = "EEEE"
            body += " Best day: \(formatter.string(from: bestDate)) (\(counts[best] ?? 0))."
        }

        return StreakNotification(kind: .weeklyRecap, title: "Your week on GitHub", body: body, deliverAt: nil)
    }

    // MARK: - Helpers

    static func dayLabel(_ n: Int) -> String { n == 1 ? "1-day" : "\(n)-day" }
    static func dayCount(_ n: Int) -> String { n == 1 ? "1 day" : "\(n) days" }

    /// `minutes` after midnight on the day of `now`.
    static func time(_ minutes: Int, on now: Date, calendar: Calendar) -> Date {
        calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: now) ?? now
    }

    static func morningDelivery(_ now: Date, calendar: Calendar) -> Date? {
        guard let morning = calendar.date(bySettingHour: streakLostDeliveryHour, minute: 0, second: 0, of: now),
              morning > now else { return nil }
        return morning
    }

    static func minutesSinceMidnight(_ date: Date, calendar: Calendar) -> Int {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    static func dateString(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private static let utcCalendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    static func parseDay(_ day: String) -> Date? {
        let parts = day.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return utcCalendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    /// Adds days to a "yyyy-MM-dd" string.
    static func addDays(_ day: String, _ offset: Int) -> String {
        guard let date = parseDay(day),
              let moved = utcCalendar.date(byAdding: .day, value: offset, to: date) else { return day }
        return dateString(moved, calendar: utcCalendar)
    }
}
