import SwiftUI
import WidgetKit
import GitStreakKit

struct MediumWidgetView: View {
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
        VStack(spacing: 0) {
            switch entry.state {
            case .loaded:
                if let _ = entry.username, let data = entry.contributionData {
                    VStack {
                        Spacer(minLength: 0)
                        HStack {
                            Spacer(minLength: 0)
                            ContributionGridView(
                                weeks: data.weeks,
                                theme: entry.theme,
                                maxWeeks: 17,
                                cellSize: 14.5,
                                columnSpacing: 3.5,
                                rowSpacing: 3.0,
                                cornerRadius: 1.5,
                                showTooltips: true
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            Spacer(minLength: 0)
                        }
                        Spacer(minLength: 0)
                    }
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
        .padding(5)
        .background(widgetGradient)
        .containerBackground(for: .widget) {
            widgetGradient
        }
    }
}
