import SwiftUI
import WidgetKit
import GitStreakKit

struct IssuesWidget: Widget {
    let kind: String = "IssuesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GitStreakTimelineProvider()) { entry in
            IssuesSmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Issues")
        .description("Shows an overview of your created, assigned, or mentioned issues on GitHub.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}
