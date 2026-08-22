import SwiftUI

public struct StreakBadgeView: View {
    public let streakCount: Int
    public let label: String
    public let style: StreakBadgeStyle

    public enum StreakBadgeStyle: Sendable {
        case compact
        case standard
        case expanded
    }

    public init(streakCount: Int, label: String, style: StreakBadgeStyle = .standard) {
        self.streakCount = streakCount
        self.label = label
        self.style = style
    }

    public var body: some View {
        HStack(alignment: .center, spacing: GSSpacing.xs) {
            Image(systemName: "flame.fill")
                .foregroundColor(streakCount > 0 ? .orange : .gray)
                .font(style == .expanded ? GSTypography.title : (style == .compact ? GSTypography.widgetTitle : GSTypography.headline))

            if style == .compact {
                Text("\(streakCount)")
                    .font(GSTypography.widgetTitle)
                    .foregroundColor(.primary)
            } else {
                Text("\(streakCount) \(label)")
                    .font(style == .expanded ? GSTypography.title : GSTypography.headline)
                    .foregroundColor(.primary)
            }
        }
    }
}
