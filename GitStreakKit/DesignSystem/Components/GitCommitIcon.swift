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

        // Outer contour starting at (11.93, 8.5)
        path.move(to: p(11.93, 8.5))

        // Bottom arc of outer circle
        path.addArc(
            center: p(8.0, 7.75),
            radius: 4.002 * scale,
            startAngle: .radians(0.183),
            endAngle: .radians(.pi - 0.183),
            clockwise: false
        )

        // Line to left cap
        path.addLine(to: p(0.75, 8.5))

        // Left cap arc
        path.addArc(
            center: p(0.75, 7.75),
            radius: 0.75 * scale,
            startAngle: .radians(.pi / 2),
            endAngle: .radians(-.pi / 2),
            clockwise: false
        )

        // Line to top of outer circle
        path.addLine(to: p(4.07, 7.0))

        // Top arc of outer circle
        path.addArc(
            center: p(8.0, 7.75),
            radius: 4.002 * scale,
            startAngle: .radians(.pi + 0.183),
            endAngle: .radians(-0.183),
            clockwise: false
        )

        // Line to right cap
        path.addLine(to: p(15.25, 7.0))

        // Right cap arc
        path.addArc(
            center: p(15.25, 7.75),
            radius: 0.75 * scale,
            startAngle: .radians(-.pi / 2),
            endAngle: .radians(.pi / 2),
            clockwise: false
        )

        path.closeSubpath()

        // Inner circle hole (center 8.0, 7.75, radius 2.5)
        let innerR = 2.5 * scale
        path.addEllipse(in: CGRect(
            x: offsetX + (8.0 - 2.5) * scale,
            y: offsetY + (7.75 - 2.5) * scale,
            width: innerR * 2,
            height: innerR * 2
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
