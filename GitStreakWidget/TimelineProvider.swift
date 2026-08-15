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
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<GitStreakEntry>) -> Void) {
        let entry = createEntry()
        // Schedule next refresh in 1 hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func createEntry() -> GitStreakEntry {
        let prefs = UserPreferences.shared
        let theme = ThemeRegistry.theme(for: prefs.selectedThemeID)
        
        guard let username = prefs.username, !username.isEmpty else {
            return GitStreakEntry(
                date: Date(),
                contributionData: nil,
                theme: theme,
                state: .noUser,
                username: nil
            )
        }
        
        let cacheManager = CacheManager()
        if let cache = cacheManager.load() {
            return GitStreakEntry(
                date: Date(),
                contributionData: cache,
                theme: theme,
                state: .loaded,
                username: username
            )
        } else {
            return GitStreakEntry(
                date: Date(),
                contributionData: nil,
                theme: theme,
                state: .noData,
                username: username
            )
        }
    }
}
