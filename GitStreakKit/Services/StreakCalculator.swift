import Foundation

public enum StreakCalculator {
    /// Calculate the current streak ending at referenceDate.
    /// A streak continues if:
    /// - Today has contributions, OR
    /// - Today has no contributions but yesterday did (streak = days up to yesterday)
    /// Days must be in YYYY-MM-DD string format.
    public static func currentStreak(
        days: [ContributionDay],
        referenceDate: String = todayDateString()
    ) -> Int {
        let sortedDays = days.sorted { $0.date < $1.date }
        
        guard let refIndex = sortedDays.firstIndex(where: { $0.date == referenceDate }) else {
            // If the reference date is missing entirely, check if it's before or after our range
            guard let last = sortedDays.last else { return 0 }
            if referenceDate > last.date {
                // If referenceDate is after the latest date we have, and they are consecutive, 
                // we could check, but safely we can return 0 if there's no data for referenceDate or previous.
                return 0
            }
            return 0
        }
        
        var streak = 0
        var currentIndex = refIndex
        
        // If reference date has 0 contributions, try starting from the day before referenceDate
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
        
        // Walk backwards counting continuous contributions
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
    
    /// Calculate the longest streak in the entire contribution history.
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
                        currentRun = 1 // Start new run due to gap
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
    
    /// Get today's date as YYYY-MM-DD string.
    public static func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }
    
    /// Check if two YYYY-MM-DD date strings are consecutive days.
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
