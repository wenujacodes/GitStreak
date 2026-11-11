import SwiftUI
import WidgetKit
import GitStreakKit

struct StreakWidget: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GitStreakTimelineProvider()) { entry in
            StreakSmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Your current streak, the last 7 days, and a heads-up when today still needs a contribution.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}
