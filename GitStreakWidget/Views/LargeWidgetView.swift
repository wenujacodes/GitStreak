import SwiftUI
import WidgetKit
import GitStreakKit

struct LargeWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    var entry: GitStreakEntry

    private var widgetGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(hex: "#222224"), Color(hex: "#141416")]
                : [Color.white, Color.white],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch entry.state {
            case .loaded:
                if let username = entry.username, let data = entry.contributionData {

                    HStack(spacing: 8) {
                        AvatarView(
                            avatarURL: data.user.avatarURL,
                            size: 32
                        )

                        VStack(alignment: .leading, spacing: 0) {
                            Text(data.user.displayName ?? username)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Text("@\(username)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        StreakBadgeView(
                            streakCount: data.currentStreak,
                            label: "days",
                            style: .compact
                        )
                    }

                    Spacer(minLength: 2)

                    HStack(alignment: .top, spacing: 4) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(" ").font(.system(size: 7))
                            Text("M").font(.system(size: 7, weight: .medium)).foregroundColor(.secondary)
                            Text(" ").font(.system(size: 7))
                            Text("W").font(.system(size: 7, weight: .medium)).foregroundColor(.secondary)
                            Text(" ").font(.system(size: 7))
                            Text("F").font(.system(size: 7, weight: .medium)).foregroundColor(.secondary)
                            Text(" ").font(.system(size: 7))
                        }

                        Spacer(minLength: 0)

                        ContributionGridView(
                            weeks: data.weeks,
                            theme: entry.theme,
                            maxWeeks: 13,
                            cellSize: 11,
                            cellSpacing: 2.5,
                            showTooltips: true,
                            isWidget: true
                        )

                        Spacer(minLength: 0)
                    }

                    Spacer(minLength: 2)

                    HStack(spacing: 0) {
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
                            icon: "square.grid.3x3.fill",
                            iconColor: .green
                        )
                    }
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
                    Text("Open GitStreak to sync contributions")
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
        .background(widgetGradient)
        .containerBackground(for: .widget) {
            widgetGradient
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
