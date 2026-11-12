import Foundation

/// Dates for the Streak widget's row of week dots.
public enum StreakWeek {
    /// The dates ("yyyy-MM-dd") of the week containing `now`, Sunday first.
    public static func dates(containing now: Date, calendar: Calendar = .current) -> [String] {
        var calendar = calendar
        calendar.firstWeekday = 1
        guard let sunday = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: sunday).map(formatter.string(from:))
        }
    }
}
