import SwiftUI
import WidgetKit
import GitStreakKit

public struct PullRequestsSmallWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    var entry: GitStreakEntry

    private var widgetGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(hex: "#242426"), Color(hex: "#141416")]
                : [Color.white, Color.white],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    public init(entry: GitStreakEntry) {
        self.entry = entry
    }

    private var activeFilter: PRWidgetFilter {
        if let raw = UserDefaults(suiteName: "group.com.gitstreak")?.string(forKey: "prWidgetFilter"),
           let filter = PRWidgetFilter(rawValue: raw) {
            return filter
        }
        return UserPreferences.shared.prWidgetFilter
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch entry.state {
            case .loaded:
                if let data = entry.contributionData {
                    let filter = activeFilter
                    let count = data.activityStats.count(for: filter)
                    let labelText = filter.shortLabel

                    VStack(alignment: .leading, spacing: 0) {
                        PullRequestIconView()
                            .frame(width: 23, height: 23)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)

                        Spacer()

                        Text("\(count)")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text(labelText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(14)
                } else {
                    EmptyView()
                }
            case .noUser:
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    Text("Add GitHub Account")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .noData:
                VStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    Text("Open app to sync")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let msg):
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(widgetGradient)
        .containerBackground(for: .widget) {
            widgetGradient
        }
    }
}
