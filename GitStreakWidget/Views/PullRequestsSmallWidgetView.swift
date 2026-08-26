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

public struct PullRequestIconView: View {
    public init() {}

    public var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 16.0
            let centerOffset = CGPoint(
                x: (size.width - 16.0 * scale) / 2,
                y: (size.height - 16.0 * scale) / 2
            )

            context.translateBy(x: centerOffset.x, y: centerOffset.y)
            context.scaleBy(x: scale, y: scale)

            let strokeStyle = StrokeStyle(lineWidth: 1.35, lineCap: .round, lineJoin: .round)

            // 1. Left Vertical Stem
            var leftStem = Path()
            leftStem.move(to: CGPoint(x: 3.25, y: 3.25))
            leftStem.addLine(to: CGPoint(x: 3.25, y: 12.75))
            context.stroke(leftStem, with: .color(.primary), style: strokeStyle)

            // 2. Right Stem & Top Curve to Arrow
            var rightBranch = Path()
            rightBranch.move(to: CGPoint(x: 12.75, y: 12.75))
            rightBranch.addLine(to: CGPoint(x: 12.75, y: 5.5))
            rightBranch.addQuadCurve(to: CGPoint(x: 10.25, y: 3.0), control: CGPoint(x: 12.75, y: 3.0))
            rightBranch.addLine(to: CGPoint(x: 9.0, y: 3.0))
            context.stroke(rightBranch, with: .color(.primary), style: strokeStyle)

            // 3. Left-pointing Arrow Head
            var arrow = Path()
            arrow.move(to: CGPoint(x: 9.4, y: 1.0))
            arrow.addLine(to: CGPoint(x: 7.2, y: 3.0))
            arrow.addLine(to: CGPoint(x: 9.4, y: 5.0))
            context.stroke(arrow, with: .color(.primary), style: strokeStyle)

            // 4. Octicon Node Circles at (3.25, 3.25), (3.25, 12.75), (12.75, 12.75)
            let circleCenters = [
                CGPoint(x: 3.25, y: 3.25),
                CGPoint(x: 3.25, y: 12.75),
                CGPoint(x: 12.75, y: 12.75)
            ]

            for center in circleCenters {
                var ring = Path()
                let r = 1.4
                ring.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
                context.stroke(ring, with: .color(.primary), style: StrokeStyle(lineWidth: 1.35))

                var dot = Path()
                let dotR = 0.65
                dot.addEllipse(in: CGRect(x: center.x - dotR, y: center.y - dotR, width: dotR * 2, height: dotR * 2))
                context.fill(dot, with: .color(.primary))
            }
        }
    }
}
