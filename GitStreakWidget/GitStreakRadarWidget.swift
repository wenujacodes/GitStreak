import SwiftUI
import WidgetKit
import GitStreakKit

struct GitStreakRadarWidget: Widget {
    let kind: String = "GitStreakRadarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GitStreakTimelineProvider()) { entry in
            RadarSmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Activity Radar")
        .description("Visual overview of your GitHub activity balance.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}
