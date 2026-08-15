import SwiftUI

public struct StatCardView: View {
    public let title: String
    public let value: String
    public let icon: String?
    public let iconColor: Color
    
    public init(title: String, value: String, icon: String? = nil, iconColor: Color = .secondary) {
        self.title = title
        self.value = value
        self.icon = icon
        self.iconColor = iconColor
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: GSSpacing.xs) {
            HStack(spacing: GSSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(GSTypography.caption)
                }
                Text(title)
                    .font(GSTypography.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(GSTypography.title)
                .foregroundColor(.primary)
        }
        .padding(GSSpacing.md)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(GSSpacing.sm)
    }
}
