import Foundation

/// The status line of the Streak widget.
/// No streak wins over a record, a record over the default "N today · best L".
public struct StreakStatus: Equatable, Sendable {
    public let text: String
    public let systemImage: String
    /// Today has no contribution yet while a streak is running (the widget greys its flame).
    public let isAtRisk: Bool

    public init(streak: Int, longest: Int, today: Int) {
        isAtRisk = today == 0 && streak > 0
        if streak == 0 {
            text = "Start a streak today"
            systemImage = "sparkles"
        } else if streak >= longest && streak > 1 {
            text = "Best streak ever"
            systemImage = "trophy.fill"
        } else {
            text = "\(today) today · best \(longest)"
            systemImage = "checkmark.circle.fill"
        }
    }

    /// The dates ("yyyy-MM-dd") of the week containing `now`, Sunday first.
    public static func weekDates(containing now: Date, calendar: Calendar = .current) -> [String] {
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
