import SwiftUI
import WidgetKit
import GitStreakKit

struct SmallWidgetView: View {
    var entry: GitStreakEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch entry.state {
            case .loaded:
                if let username = entry.username, let data = entry.contributionData {
                    // Header: ~/username in compact monospaced text
                    Text("~/\(username)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer(minLength: 2)
                    
                    // Compact Streak Metric
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(data.currentStreak)")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                        
                        Text("day streak")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer(minLength: 4)
                    
                    // Heatmap Grid: 11 weeks, smaller cells, balanced side & bottom margins
                    HStack {
                        Spacer(minLength: 0)
                        ContributionGridView(
                            weeks: data.weeks,
                            theme: entry.theme,
                            maxWeeks: 11,
                            cellSize: 9.5,
                            cellSpacing: 2.2
                        )
                        Spacer(minLength: 0)
                    }
                }
            case .noUser:
                VStack(spacing: 6) {
                    Text("~/gitstreak")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                    Text("Add GitHub Account")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .noData:
                VStack(spacing: 6) {
                    Text("~/gitstreak")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                    Text("Open app to sync")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let msg):
                VStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                    Text(msg)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 13)
        .padding(.bottom, 14)
        .containerBackground(for: .widget) {
            Color(NSColor.windowBackgroundColor)
        }
    }
}
