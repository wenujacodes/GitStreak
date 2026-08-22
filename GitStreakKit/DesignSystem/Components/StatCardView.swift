import SwiftUI

public struct StatCardView: View {
    public let title: String
    public let value: String
    public let icon: String?
    public let iconColor: Color
    public let subtitle: String?

    public init(
        title: String,
        value: String,
        icon: String? = nil,
        iconColor: Color = .secondary,
        subtitle: String? = nil
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.iconColor = iconColor
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title.uppercased())
                    .font(GSTypography.monoCaption)
                    .foregroundColor(.secondary)
                    .tracking(0.5)

                Spacer()
            }

            Text(value)
                .font(GSTypography.monoTitle)
                .foregroundColor(.primary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
