import Foundation

public enum StreakCalculator {

    public static func currentStreak(
        days: [ContributionDay],
        referenceDate: String = todayDateString()
    ) -> Int {
        let sortedDays = days.sorted { $0.date < $1.date }
        guard !sortedDays.isEmpty else { return 0 }

        var streak = 0
        var currentIndex: Int

        if let refIndex = sortedDays.firstIndex(where: { $0.date == referenceDate }) {
            currentIndex = refIndex
            if sortedDays[currentIndex].contributionCount == 0 {
                if currentIndex > 0 {
                    let prevDay = sortedDays[currentIndex - 1]
                    if areConsecutiveDays(prevDay.date, referenceDate) {
                        currentIndex -= 1
                    } else {
                        return 0
                    }
                } else {
                    return 0
                }
            }
        } else {
            guard let last = sortedDays.last,
                  areConsecutiveDays(last.date, referenceDate),
                  last.contributionCount > 0 else {
                return 0
            }
            currentIndex = sortedDays.count - 1
        }

        while currentIndex >= 0 {
            let day = sortedDays[currentIndex]
            if day.contributionCount > 0 {
                streak += 1
                if currentIndex > 0 {
                    let prevDay = sortedDays[currentIndex - 1]
                    if !areConsecutiveDays(prevDay.date, day.date) {
                        break
                    }
                    currentIndex -= 1
                } else {
                    break
                }
            } else {
                break
            }
        }

        return streak
    }

    public static func longestStreak(days: [ContributionDay]) -> Int {
        let sortedDays = days.sorted { $0.date < $1.date }

        var maxStreak = 0
        var currentRun = 0
        var previousDate: String?

        for day in sortedDays {
            if day.contributionCount > 0 {
                if let prev = previousDate {
                    if areConsecutiveDays(prev, day.date) {
                        currentRun += 1
                    } else {
                        currentRun = 1
                    }
                } else {
                    currentRun = 1
                }
            } else {
                currentRun = 0
            }

            previousDate = day.date
            maxStreak = max(maxStreak, currentRun)
        }

        return maxStreak
    }

    public static func todayDateString(timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = timeZone
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    internal static func areConsecutiveDays(_ earlier: String, _ later: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")

        guard let earlierDate = formatter.date(from: earlier),
              let laterDate = formatter.date(from: later) else {
            return false
        }

        guard let dayAfterEarlier = formatter.calendar.date(byAdding: .day, value: 1, to: earlierDate) else {
            return false
        }

        return dayAfterEarlier == laterDate
    }
}
