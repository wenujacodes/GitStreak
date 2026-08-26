import SwiftUI
import WidgetKit
import GitStreakKit

public struct RadarComboMediumWidgetView: View {
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

    public var body: some View {
        HStack(spacing: 8) {
            switch entry.state {
            case .loaded:
                if let data = entry.contributionData {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            HStack(alignment: .firstTextBaseline, spacing: 3) {
                                Text(formatStatNumber(data.totalContributions))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Text("Total")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.secondary)
                            }

                            HStack(alignment: .firstTextBaseline, spacing: 3) {
                                Text(formatStatNumber(data.longestStreak))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Text("Best")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer(minLength: 0)

                        ContributionGridView(
                            weeks: data.weeks,
                            theme: entry.theme,
                            maxWeeks: 10,
                            cellSize: 12.0,
                            columnSpacing: 3.0,
                            rowSpacing: 2.5,
                            cornerRadius: 2.0,
                            showTooltips: false,
                            isWidget: true
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 6)

                    VStack {
                        ActivityRadarChartView(
                            stats: data.activityStats,
                            theme: entry.theme
                        )
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    EmptyView()
                }
            case .noUser:
                VStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    Text("Add your GitHub account in GitStreak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .noData:
                VStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    Text("Open GitStreak to sync contributions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let msg):
                VStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(10)
        .background(widgetGradient)
        .containerBackground(for: .widget) {
            widgetGradient
        }
    }

    private func formatStatNumber(_ count: Int) -> String {
        if count >= 10_000 {
            let value = Double(count) / 1000.0
            let formatted = String(format: "%.2f", value)
                .replacingOccurrences(of: "\\.00$", with: "", options: .regularExpression)
                .replacingOccurrences(of: "(\\.[1-9])0$", with: "$1", options: .regularExpression)
            return "\(formatted)k"
        } else {
            return "\(count)"
        }
    }
}
