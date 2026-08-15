import WidgetKit
import SwiftUI
import GitStreakKit

struct GitStreakTimelineProvider: TimelineProvider {
    typealias Entry = GitStreakEntry
    
    func placeholder(in context: Context) -> GitStreakEntry {
        return GitStreakEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (GitStreakEntry) -> Void) {
        if context.isPreview {
            completion(GitStreakEntry.placeholder)
            return
        }
        
        let entry = createEntry()
        if case .noUser = entry.state {
            completion(GitStreakEntry.placeholder)
        } else {
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<GitStreakEntry>) -> Void) {
        let entry = createEntry()
        // Schedule next refresh in 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func createEntry() -> GitStreakEntry {
        let cacheManager = CacheManager()
        let cache = cacheManager.load()
        
        let prefs = UserPreferences.shared
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
