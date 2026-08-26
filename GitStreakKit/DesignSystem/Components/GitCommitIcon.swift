import SwiftUI

/// Vector Octicon Git Commit Shape matching GitHub's official octicon-git-commit SVG path.
public struct GitCommitShape: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 16.0
        let offsetX = (rect.width - 16.0 * scale) / 2.0
        let offsetY = (rect.height - 16.0 * scale) / 2.0

        func p(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: offsetX + x * scale, y: offsetY + y * scale)
        }

        var path = Path()

        // Outer contour of git commit icon (16x16 coordinate space)
        path.move(to: p(11.93, 8.5))

        // Arc around bottom of circle to left line join
        path.addArc(
            center: p(8.0, 8.5),
            radius: 4.002 * scale,
            startAngle: .radians(0.198),
            endAngle: .radians(.pi - 0.198),
            clockwise: false
        )

        // Line to left cap
        path.addLine(to: p(0.75, 8.5))

        // Left rounded end cap
        path.addArc(
            center: p(0.75, 7.75),
            radius: 0.75 * scale,
            startAngle: .radians(.pi / 2),
            endAngle: .radians(-.pi / 2),
            clockwise: false
        )

        // Line to top circle join
        path.addLine(to: p(4.07, 7.0))

        // Arc around top of circle to right line join
        path.addArc(
            center: p(8.0, 7.0),
            radius: 4.002 * scale,
            startAngle: .radians(.pi - 0.198),
            endAngle: .radians(0.198),
            clockwise: false
        )

        // Line to right cap
        path.addLine(to: p(15.25, 7.0))

        // Right rounded end cap
        path.addArc(
            center: p(15.25, 7.75),
            radius: 0.75 * scale,
            startAngle: .radians(-.pi / 2),
            endAngle: .radians(.pi / 2),
            clockwise: false
        )

        path.closeSubpath()

        // Inner cutout circle (radius 2.5 centered at 8.0, 7.75)
        path.addEllipse(in: CGRect(
            x: offsetX + 5.5 * scale,
            y: offsetY + 5.25 * scale,
            width: 5.0 * scale,
            height: 5.0 * scale
        ))

        return path
    }
}

/// SwiftUI View rendering the vector Octicon Git Commit Icon.
public struct GitCommitIcon: View {
    var size: CGFloat
    var color: Color

    public init(size: CGFloat = 22, color: Color = .primary) {
        self.size = size
        self.color = color
    }

    public var body: some View {
        GitCommitShape()
            .fill(color, style: FillStyle(eoFill: true))
            .frame(width: size, height: size)
    }
}
