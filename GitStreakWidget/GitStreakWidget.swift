import SwiftUI
import WidgetKit
import GitStreakKit

struct GitStreakWidget: Widget {
    let kind: String = "GitStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GitStreakTimelineProvider()) { entry in
            GitStreakWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("GitStreak")
        .description("Your GitHub contribution streak at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}

struct GitStreakWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: GitStreakEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        @unknown default:
            SmallWidgetView(entry: entry)
        }
    }
}
