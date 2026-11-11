import WidgetKit
import SwiftUI

@main
struct GitStreakWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
        GitStreakWidget()
        TodayCommitsWidget()
        GitStreakRadarWidget()
        GitStreakComboWidget()
        PullRequestsWidget()
        IssuesWidget()
    }
}
