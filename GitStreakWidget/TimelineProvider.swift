import WidgetKit
import SwiftUI
import GitStreakKit

struct GitStreakTimelineProvider: TimelineProvider {
    typealias Entry = GitStreakEntry

    func placeholder(in context: Context) -> GitStreakEntry {
        return GitStreakEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (GitStreakEntry) -> Void) {
        let entry = createEntry()
        if case .noUser = entry.state {
            completion(GitStreakEntry.placeholder)
        } else {
            completion(entry)
        }
    }

    /// The widget never calls GitHub itself. The app fetches in the background and writes
    /// the shared cache, then reloads the widgets; here we only read that cache.
    func getTimeline(in context: Context, completion: @escaping (Timeline<GitStreakEntry>) -> Void) {
        let entry = createEntry()

        let now = Date()
        let fiveMinutesLater = Calendar.current.date(byAdding: .minute, value: 5, to: now) ?? now.addingTimeInterval(300)
        let nextMidnight = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 1),
            matchingPolicy: .nextTime
        ) ?? fiveMinutesLater

        let nextUpdate = min(fiveMinutesLater, nextMidnight)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func createEntry() -> GitStreakEntry {
        let cacheManager = CacheManager()
        let cache = cacheManager.load()

        let prefs = UserPreferences.shared
        prefs.reloadFromDisk()
        let theme = ThemeRegistry.theme(for: prefs.selectedThemeID)
        let username = prefs.username ?? cache?.user.username

        if let cache = cache, let username = username, !username.isEmpty {
            return GitStreakEntry(
                date: Date(),
                contributionData: cache,
                theme: theme,
                state: .loaded,
                username: username
            )
        } else if let username = username, !username.isEmpty {
            return GitStreakEntry(
                date: Date(),
                contributionData: nil,
                theme: theme,
                state: .noData,
                username: username
            )
        } else {
            return GitStreakEntry(
                date: Date(),
                contributionData: nil,
                theme: theme,
                state: .noUser,
                username: nil
            )
        }
    }
}
