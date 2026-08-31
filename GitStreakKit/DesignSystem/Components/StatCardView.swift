import SwiftUI

public struct StatCardView: View {
    public let title: String
    public let value: String
    public let icon: String?
    public let customIconView: AnyView?
    public let iconColor: Color
    public let subtitle: String?

    public init(
        title: String,
        value: String,
        icon: String? = nil,
        customIconView: AnyView? = nil,
        iconColor: Color = .secondary,
        subtitle: String? = nil
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.customIconView = customIconView
        self.iconColor = iconColor
        self.subtitle = subtitle
    }

    @Environment(\.colorScheme) private var colorScheme

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if let customIconView = customIconView {
                    customIconView
                        .frame(width: 14, height: 14)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title)
                    .font(GSTypography.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }

            Text(value)
                .font(GSTypography.title)
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
                .fill(colorScheme == .dark ? Color(hex: "#1A1A1A") : Color(hex: "#F5F5F7"))
        )
    }
}
