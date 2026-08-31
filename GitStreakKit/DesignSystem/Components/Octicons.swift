import SwiftUI

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

            // 4. Octicon Node Circles
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

public struct IssueIconView: View {
    public init() {}

    public var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 16.0
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            // Outer Ring
            var outerRing = Path()
            let ringRadius = 7.25 * scale
            outerRing.addEllipse(in: CGRect(
                x: center.x - ringRadius,
                y: center.y - ringRadius,
                width: ringRadius * 2,
                height: ringRadius * 2
            ))
            context.stroke(outerRing, with: .color(.primary), style: StrokeStyle(lineWidth: 1.5 * scale))

            // Inner Dot
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

