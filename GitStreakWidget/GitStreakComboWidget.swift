import SwiftUI
import WidgetKit
import GitStreakKit

struct GitStreakComboWidget: Widget {
    let kind: String = "GitStreakComboWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GitStreakTimelineProvider()) { entry in
            RadarComboMediumWidgetView(entry: entry)
        }
        .configurationDisplayName("Streak & Radar")
        .description("Shows your 7-week contribution grid alongside your activity radar chart.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}
