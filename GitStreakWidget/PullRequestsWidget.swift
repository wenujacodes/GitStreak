import SwiftUI
import WidgetKit
import GitStreakKit

struct PullRequestsWidget: Widget {
    let kind: String = "PullRequestsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GitStreakTimelineProvider()) { entry in
            PullRequestsSmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Pull Requests")
        .description("Shows an overview of your created, assigned, mentioned, or review-requested pull requests on GitHub.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}
