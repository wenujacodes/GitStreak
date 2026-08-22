import SwiftUI

public enum GSTypography {
    public static let largeTitle: Font = .system(size: 28, weight: .bold, design: .rounded)
    public static let title: Font = .system(size: 20, weight: .semibold, design: .rounded)
    public static let headline: Font = .system(size: 15, weight: .semibold)
    public static let body: Font = .system(size: 13, weight: .regular)
    public static let caption: Font = .system(size: 11, weight: .medium)
    public static let captionSmall: Font = .system(size: 10, weight: .regular)

    public static let monoLarge: Font = .system(size: 32, weight: .bold, design: .monospaced)
    public static let monoTitle: Font = .system(size: 22, weight: .bold, design: .monospaced)
    public static let monoBody: Font = .system(size: 13, weight: .medium, design: .monospaced)
    public static let monoCaption: Font = .system(size: 11, weight: .medium, design: .monospaced)
    public static let monoBadge: Font = .system(size: 10, weight: .bold, design: .monospaced)

    public static let widgetTitle: Font = .system(size: 14, weight: .semibold, design: .rounded)
    public static let widgetHeadline: Font = .system(size: 22, weight: .bold, design: .rounded)
    public static let widgetCaption: Font = .system(size: 10, weight: .medium)
    public static let widgetStreakCount: Font = .system(size: 32, weight: .bold, design: .rounded)
}
