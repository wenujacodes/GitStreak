import Foundation

/// The status line of the Streak widget.
/// At risk wins over no streak, no streak over a record, a record over "done today".
public struct StreakStatus: Equatable, Sendable {
    public let text: String
    public let systemImage: String
    public let isAtRisk: Bool

    public init(streak: Int, longest: Int, today: Int, now: Date, calendar: Calendar = .current) {
        if today == 0 && streak > 0 {
            text = "Commit today · \(Self.timeLeft(from: now, calendar: calendar))"
            systemImage = "exclamationmark.triangle.fill"
            isAtRisk = true
        } else if streak == 0 {
            text = "Start a streak today"
            systemImage = "sparkles"
            isAtRisk = false
        } else if streak >= longest && streak > 1 {
            text = "Best streak ever"
            systemImage = "trophy.fill"
            isAtRisk = false
        } else {
            text = "\(today) today · best \(longest)"
            systemImage = "checkmark.circle.fill"
            isAtRisk = false
        }
    }

    /// "6h left" or "45m left" until midnight.
    public static func timeLeft(from now: Date, calendar: Calendar = .current) -> String {
        let midnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime)
            ?? now.addingTimeInterval(3600)
        let minutes = max(0, Int(midnight.timeIntervalSince(now) / 60))
        return minutes >= 60 ? "\(minutes / 60)h left" : "\(minutes)m left"
    }
}
