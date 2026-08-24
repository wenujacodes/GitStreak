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
                : [Color(hex: "#F5F5F7"), Color(hex: "#E5E5EA")],
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
                    let count = data.activityStats.reviews > 0 ? data.activityStats.reviews : data.activityStats.pullRequests
                    let labelText = data.activityStats.reviews > 0 ? "Reviews Requested" : "Pull Requests"

                    VStack(alignment: .leading, spacing: 0) {
                        PullRequestIconView()
                            .frame(width: 26, height: 26)
                            .foregroundColor(.primary)

                        Spacer()

                        Text("\(count)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
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
        if let nsImage = NSImage(named: "GitPullRequest") ?? NSImage(contentsOfFile: "/Users/wenujaliyanamana/Desktop/gitstreak/git-pull-request.png") {
            Image(nsImage: nsImage)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
        } else {
            Canvas { context, size in
                let w = size.width
                let h = size.height
                let strokeWidth = w * 0.11

                var leftLine = Path()
                leftLine.move(to: CGPoint(x: w * 0.25, y: h * 0.25))
                leftLine.addLine(to: CGPoint(x: w * 0.25, y: h * 0.75))
                context.stroke(leftLine, with: .color(.primary), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))

                var rightBranch = Path()
                rightBranch.move(to: CGPoint(x: w * 0.75, y: h * 0.75))
                rightBranch.addLine(to: CGPoint(x: w * 0.75, y: h * 0.4))
                rightBranch.addQuadCurve(to: CGPoint(x: w * 0.42, y: h * 0.25), control: CGPoint(x: w * 0.75, y: h * 0.25))
                context.stroke(rightBranch, with: .color(.primary), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))

                var arrow = Path()
                arrow.move(to: CGPoint(x: w * 0.52, y: h * 0.17))
                arrow.addLine(to: CGPoint(x: w * 0.40, y: h * 0.25))
                arrow.addLine(to: CGPoint(x: w * 0.52, y: h * 0.33))
                context.stroke(arrow, with: .color(.primary), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))

                let r = w * 0.12
                for center in [CGPoint(x: w * 0.25, y: h * 0.22), CGPoint(x: w * 0.25, y: h * 0.78), CGPoint(x: w * 0.75, y: h * 0.78)] {
                    var circle = Path()
                    circle.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
                    context.fill(circle, with: .color(.primary))
                }
            }
        }
    }
}
