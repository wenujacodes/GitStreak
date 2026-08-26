import SwiftUI
import WidgetKit
import GitStreakKit

struct TodayCommitsWidget: Widget {
    let kind: String = "TodayCommitsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GitStreakTimelineProvider()) { entry in
            TodaySmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's Commits")
        .description("Display your GitHub commits for today.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}
