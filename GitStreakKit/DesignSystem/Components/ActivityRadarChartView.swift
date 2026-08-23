import SwiftUI

public struct ActivityRadarChartView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let stats: UserActivityStats
    public let theme: ThemeColors

    private let axes: [(name: String, angle: Double)] = [
        ("Commit", -Double.pi / 2),
        ("Issue", -Double.pi / 2 + 2 * Double.pi / 5),
        ("PullReq", -Double.pi / 2 + 4 * Double.pi / 5),
        ("Review", -Double.pi / 2 + 6 * Double.pi / 5),
        ("Repo", -Double.pi / 2 + 8 * Double.pi / 5)
    ]

    private var levels: [(scale: Double, label: String)] {
        stats.dynamicLevels
    }

    public init(stats: UserActivityStats, theme: ThemeColors = ThemeRegistry.github) {
        self.stats = stats
        self.theme = theme
    }

    private var gridColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.35)
            : Color.black.opacity(0.28)
    }

    private var scaleLabelColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.65)
            : Color.black.opacity(0.55)
    }

    private var chartAccentColor: Color {
        Color(hex: theme.mediumHex)
    }

    public var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2 + 2)
            let maxRadius = (size / 2) * 0.65

            ZStack {
                // Dashed concentric pentagons & radial spokes
                Canvas { context, _ in
                    let strokeStyle = StrokeStyle(
                        lineWidth: 0.9,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: [2.5, 2.5]
                    )

                    // 1. Concentric pentagons
                    for level in levels {
                        let r = maxRadius * level.scale
                        var path = Path()
                        for (i, axis) in axes.enumerated() {
                            let pt = CGPoint(
                                x: center.x + r * cos(axis.angle),
                                y: center.y + r * sin(axis.angle)
                            )
                            if i == 0 {
                                path.move(to: pt)
                            } else {
                                path.addLine(to: pt)
                            }
                        }
                        path.closeSubpath()
                        context.stroke(path, with: .color(gridColor), style: strokeStyle)
                    }

                    // 2. Radial spokes from center to each outer vertex
                    for axis in axes {
                        var spoke = Path()
                        spoke.move(to: center)
                        spoke.addLine(to: CGPoint(
                            x: center.x + maxRadius * cos(axis.angle),
                            y: center.y + maxRadius * sin(axis.angle)
                        ))
                        context.stroke(spoke, with: .color(gridColor), style: strokeStyle)
                    }

                    // 3. User Stats Data Polygon
                    let fractions = [
                        stats.commitFraction,
                        stats.issueFraction,
                        stats.pullRequestFraction,
                        stats.reviewFraction,
                        stats.repositoryFraction
                    ]

                    var dataPath = Path()
                    var hasData = false
                    for (i, fraction) in fractions.enumerated() {
                        let r = max(maxRadius * fraction, 1.0)
                        if fraction > 0 { hasData = true }
                        let angle = axes[i].angle
                        let pt = CGPoint(
                            x: center.x + r * cos(angle),
                            y: center.y + r * sin(angle)
                        )
                        if i == 0 {
                            dataPath.move(to: pt)
                        } else {
                            dataPath.addLine(to: pt)
                        }
                    }
                    dataPath.closeSubpath()

                    if hasData {
                        let fillOpacity = colorScheme == .dark ? 0.52 : 0.42
                        context.fill(dataPath, with: .color(chartAccentColor.opacity(fillOpacity)))
                        let outlineStyle = StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
                        context.stroke(dataPath, with: .color(chartAccentColor), style: outlineStyle)
                    }
                }

                // Numbers along the vertical (Commit) axis
                ForEach(levels.indices, id: \.self) { idx in
                    let level = levels[idx]
                    let yOffset = -maxRadius * level.scale + 6.5
                    Text(level.label)
                        .font(.system(size: 6.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(scaleLabelColor)
                        .position(x: center.x, y: center.y + yOffset)
                }

                // Axis Labels with Stat Values
                // Commit (Top)
                VStack(spacing: 0) {
                    Text("Commit")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("\(stats.commits)")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(chartAccentColor)
                }
                .position(x: center.x, y: center.y - maxRadius - 13)

                // Issue (Top Right)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Issue")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("\(stats.issues)")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(chartAccentColor)
                }
                .position(
                    x: center.x + maxRadius * cos(axes[1].angle) + 18,
                    y: center.y + maxRadius * sin(axes[1].angle)
                )

                // PullReq (Bottom Right)
                VStack(alignment: .leading, spacing: 0) {
                    Text("PullReq")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("\(stats.pullRequests)")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(chartAccentColor)
                }
                .position(
                    x: center.x + maxRadius * cos(axes[2].angle) + 14,
                    y: center.y + maxRadius * sin(axes[2].angle) + 11
                )

                // Review (Bottom Left)
                VStack(alignment: .trailing, spacing: 0) {
                    Text("Review")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("\(stats.reviews)")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(chartAccentColor)
                }
                .position(
                    x: center.x + maxRadius * cos(axes[3].angle) - 14,
                    y: center.y + maxRadius * sin(axes[3].angle) + 11
                )

                // Repo (Top Left)
                VStack(alignment: .trailing, spacing: 0) {
                    Text("Repo")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("\(stats.repositories)")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(chartAccentColor)
                }
                .position(
                    x: center.x + maxRadius * cos(axes[4].angle) - 18,
                    y: center.y + maxRadius * sin(axes[4].angle)
                )
            }
        }
    }
}
