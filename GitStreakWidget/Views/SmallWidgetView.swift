import SwiftUI
import WidgetKit
import GitStreakKit

struct SmallWidgetView: View {
    var entry: GitStreakEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch entry.state {
            case .loaded:
                if let username = entry.username, let data = entry.contributionData {
                    HStack {
                        Text("@\(username)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Spacer()
                    }
                    
                    Spacer()
                    
                    ContributionGridView(
                        weeks: data.weeks,
                        theme: entry.theme,
                        maxWeeks: 6,
                        cellSize: GSSpacing.smallGridCellSize,
                        cellSpacing: 2
                    )
                    
                    Spacer()
                    
                    StreakBadgeView(
                        streakCount: data.currentStreak,
                        label: "days",
                        style: .compact
                    )
                }
            case .noUser:
                VStack(spacing: 4) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                    Text("Add GitHub\nAccount")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .noData:
                VStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                    Text("Open GitStreak\nto sync")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let msg):
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                    Text(msg)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color(NSColor.windowBackgroundColor)
        }
    }
}
