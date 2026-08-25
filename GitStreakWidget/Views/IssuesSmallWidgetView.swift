import SwiftUI
import WidgetKit
import GitStreakKit

public struct IssuesSmallWidgetView: View {
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
        VStack(alignment: .leading, spacing: 0) {
            switch entry.state {
            case .loaded:
                if let data = entry.contributionData {
                    let count = data.activityStats.issues

                    VStack(alignment: .leading, spacing: 0) {
                        IssueIconView()
                            .frame(width: 23, height: 23)
                            .foregroundColor(.primary)

                        Spacer()

                        Text("\(count)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text("Issues")
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

public struct IssueIconView: View {
    public init() {}

    public var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 16.0
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            // Outer Ring (r = 7.25 * scale, lineWidth = 1.5 * scale -> outer boundary r=8.0, inner boundary r=6.5)
            var outerRing = Path()
            let ringRadius = 7.25 * scale
            outerRing.addEllipse(in: CGRect(
                x: center.x - ringRadius,
                y: center.y - ringRadius,
                width: ringRadius * 2,
                height: ringRadius * 2
            ))
            context.stroke(outerRing, with: .color(.primary), style: StrokeStyle(lineWidth: 1.5 * scale))

            // Inner Dot (r = 1.5 * scale)
            var innerDot = Path()
            let dotRadius = 1.5 * scale
            innerDot.addEllipse(in: CGRect(
                x: center.x - dotRadius,
                y: center.y - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fill(innerDot, with: .color(.primary))
        }
    }
}
