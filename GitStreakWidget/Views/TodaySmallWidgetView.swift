import SwiftUI
import WidgetKit
import GitStreakKit

public struct TodaySmallWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var family
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

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch entry.state {
            case .loaded:
                if let data = entry.contributionData {
                    let count = data.todayContributions

                    if family == .systemMedium {
                        HStack(spacing: 16) {
                            // LEFT SIDE: 10-column week contribution graph (no icons)
                            VStack {
                                Spacer(minLength: 0)
                                ContributionGridView(
                                    weeks: data.weeks,
                                    theme: entry.theme,
                                    maxWeeks: 10,
                                    cellSize: 13.0,
                                    columnSpacing: 3.5,
                                    rowSpacing: 3.0,
                                    cornerRadius: 2.0,
                                    showTooltips: false,
                                    isWidget: true
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)

                            Divider()
                                .opacity(0.3)

                            // RIGHT SIDE: Today's Commits & Total Contributions (NO ICONS, NO TRUNCATION)
                            VStack(alignment: .leading, spacing: 14) {
                                Spacer(minLength: 0)

                                // Today's Commits
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Today's Commits")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)

                                    Text("\(data.todayContributions)")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }

                                // Total Contributions
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Total Contributions")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.65)

                                    Text("\(data.totalContributions)")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }

                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(14)
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            GitCommitIcon(size: 22, color: .primary)

                            Spacer()

                            Text("\(count)")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            Text("Today's Commits")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .padding(14)
                    }
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
