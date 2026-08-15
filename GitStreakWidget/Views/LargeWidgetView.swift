import SwiftUI
import WidgetKit
import GitStreakKit

struct LargeWidgetView: View {
    var entry: GitStreakEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch entry.state {
            case .loaded:
                if let username = entry.username, let data = entry.contributionData {
                    // Header: Avatar, Display Name, and Username (bio/about removed)
                    HStack(spacing: 10) {
                        AvatarView(
                            avatarURL: data.user.avatarURL,
                            size: 34
                        )
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(data.user.displayName ?? username)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Text("@\(username)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Grid with Day labels
                    HStack(alignment: .top, spacing: 4) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(" ").font(.system(size: 8)) // Sun
                            Text("M").font(.system(size: 8, weight: .medium)).foregroundColor(.secondary)
                            Text(" ").font(.system(size: 8)) // Tue
                            Text("W").font(.system(size: 8, weight: .medium)).foregroundColor(.secondary)
                            Text(" ").font(.system(size: 8)) // Thu
                            Text("F").font(.system(size: 8, weight: .medium)).foregroundColor(.secondary)
                            Text(" ").font(.system(size: 8)) // Sat
                        }
                        
                        ContributionGridView(
                            weeks: data.weeks,
                            theme: entry.theme,
                            maxWeeks: 14,
                            cellSize: 10.5,
                            cellSpacing: 2.5
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()
                    
                    // Stats Row
                    HStack(spacing: 12) {
                        WidgetStatView(
                            title: "Current",
                            value: "\(data.currentStreak)d",
                            icon: "flame.fill",
                            iconColor: .orange
                        )
                        
                        Spacer()
                        
                        WidgetStatView(
                            title: "Longest",
                            value: "\(data.longestStreak)d",
                            icon: "trophy.fill",
                            iconColor: .yellow
                        )
                        
                        Spacer()
                        
                        WidgetStatView(
                            title: "Total",
                            value: "\(data.totalContributions)",
                            icon: "plus.circle.fill",
                            iconColor: .green
                        )
                    }
                    .padding(.top, 4)
                }
            case .noUser:
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("Add your GitHub account in GitStreak")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .noData:
                VStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("Open GitStreak to get started")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let msg):
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    Text(msg)
                        .font(.callout)
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

struct WidgetStatView: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 9))
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
    }
}
