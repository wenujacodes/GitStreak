import WidgetKit
import SwiftUI

@main
struct GitStreakWidgetBundle: WidgetBundle {
    var body: some Widget {
        GitStreakWidget()
        TodayCommitsWidget()
        GitStreakRadarWidget()
        GitStreakComboWidget()
        PullRequestsWidget()
        IssuesWidget()
    }
}
