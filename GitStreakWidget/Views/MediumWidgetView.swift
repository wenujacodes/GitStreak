import SwiftUI
import WidgetKit
import GitStreakKit

struct MediumWidgetView: View {
    var entry: GitStreakEntry
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            switch entry.state {
            case .loaded:
                if let username = entry.username, let data = entry.contributionData {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            AvatarView(
                                avatarURL: data.user.avatarURL,
                                size: 28
                            )
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text(data.user.displayName ?? username)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Text("@\(username)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("\(data.totalContributions)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        
                        StreakBadgeView(
                            streakCount: data.currentStreak,
                            label: "day streak",
                            style: .compact
                        )
                    }
                    .frame(maxWidth: 110, alignment: .leading)
                    
                    Spacer(minLength: 0)
                    
                    ContributionGridView(
                        weeks: data.weeks,
                        theme: entry.theme,
                        maxWeeks: 11,
                        cellSize: 10.5,
                        cellSpacing: 2.5
                    )
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
        .padding(14)
        .background(Color(red: 30/255, green: 30/255, blue: 31/255))
        .containerBackground(for: .widget) {
            Color(red: 30/255, green: 30/255, blue: 31/255) // #1E1E1F
        }
    }
}
