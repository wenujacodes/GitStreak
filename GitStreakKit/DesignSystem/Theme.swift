import SwiftUI

public struct ThemeColors: Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let isPro: Bool

    public let noneHex: String
    public let lowHex: String
    public let mediumHex: String
    public let highHex: String
    public let veryHighHex: String

    public let darkNoneHex: String?
    public let darkLowHex: String?
    public let darkMediumHex: String?
    public let darkHighHex: String?
    public let darkVeryHighHex: String?

    public init(
        id: String,
        name: String,
        description: String,
        isPro: Bool,
        noneHex: String,
        lowHex: String,
        mediumHex: String,
        highHex: String,
        veryHighHex: String,
        darkNoneHex: String? = nil,
        darkLowHex: String? = nil,
        darkMediumHex: String? = nil,
        darkHighHex: String? = nil,
        darkVeryHighHex: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.isPro = isPro
        self.noneHex = noneHex
        self.lowHex = lowHex
        self.mediumHex = mediumHex
        self.highHex = highHex
        self.veryHighHex = veryHighHex
        self.darkNoneHex = darkNoneHex
        self.darkLowHex = darkLowHex
        self.darkMediumHex = darkMediumHex
        self.darkHighHex = darkHighHex
        self.darkVeryHighHex = darkVeryHighHex
    }

    public func color(for level: ContributionLevel, colorScheme: ColorScheme = .dark, isWidget: Bool = false) -> Color {
        if level.intensity == 0 {
            if colorScheme == .light {
                return Color(hex: "#EFF2F5")
            } else {
                return Color(hex: "#3A3A3C")
            }
        }

        if colorScheme == .light {
            switch level.intensity {
            case 1: return Color(hex: lowHex)
            case 2: return Color(hex: mediumHex)
            case 3: return Color(hex: highHex)
            case 4: return Color(hex: veryHighHex)
            default: return Color(hex: "#EFF2F5")
            }
        } else {
            switch level.intensity {
            case 1: return Color(hex: darkLowHex ?? veryHighHex)
            case 2: return Color(hex: darkMediumHex ?? highHex)
            case 3: return Color(hex: darkHighHex ?? mediumHex)
            case 4: return Color(hex: darkVeryHighHex ?? lowHex)
            default: return Color(hex: "#3A3A3C")
            }
        }
    }

    public func color(for level: ContributionLevel) -> Color {
        color(for: level, colorScheme: .dark, isWidget: false)
    }

    public var allColors: [Color] {
        allColors(for: .dark, isWidget: false)
    }

    public func allColors(for colorScheme: ColorScheme, isWidget: Bool = false) -> [Color] {
        let empty = colorScheme == .light
            ? Color(hex: "#EFF2F5")
            : Color(hex: "#3A3A3C")
        if colorScheme == .light {
            return [empty, Color(hex: lowHex), Color(hex: mediumHex), Color(hex: highHex), Color(hex: veryHighHex)]
        } else {
            return [
                empty,
                Color(hex: darkLowHex ?? veryHighHex),
                Color(hex: darkMediumHex ?? highHex),
                Color(hex: darkHighHex ?? mediumHex),
                Color(hex: darkVeryHighHex ?? lowHex)
            ]
        }
    }
}

public enum ThemeRegistry {
    public static let github = ThemeColors(
        id: "github", name: "GitHub", description: "The classic GitHub green.", isPro: false,
        noneHex: "#151B23", lowHex: "#9be9a8", mediumHex: "#40c463", highHex: "#30a14e", veryHighHex: "#216e39",
        darkLowHex: "#023A16", darkMediumHex: "#006D32", darkHighHex: "#26A641", darkVeryHighHex: "#39D353"
    )
    public static let ocean = ThemeColors(
        id: "ocean", name: "Ocean", description: "Cool blues.", isPro: false,
        noneHex: "#151B23", lowHex: "#79b8ff", mediumHex: "#2188ff", highHex: "#0366d6", veryHighHex: "#044289"
    )
    public static let sunset = ThemeColors(
        id: "sunset", name: "Sunset", description: "Warm oranges.", isPro: false,
        noneHex: "#151B23", lowHex: "#ffb088", mediumHex: "#ff7b42", highHex: "#d9480f", veryHighHex: "#9c2706"
    )
    public static let forest = ThemeColors(
        id: "forest", name: "Forest", description: "Deep greens.", isPro: false,
        noneHex: "#151B23", lowHex: "#99d18b", mediumHex: "#5bb543", highHex: "#358422", veryHighHex: "#1d5212"
    )
    public static let lavender = ThemeColors(
        id: "lavender", name: "Lavender", description: "Soft lilac to deep violet.", isPro: false,
        noneHex: "#151B23", lowHex: "#e9d5ff", mediumHex: "#c084fc", highHex: "#9333ea", veryHighHex: "#581c87",
        darkLowHex: "#4c1d95", darkMediumHex: "#6d28d9", darkHighHex: "#a855f7", darkVeryHighHex: "#d8b4fe"
    )
    public static let rose = ThemeColors(
        id: "rose", name: "Rose", description: "Blush pink to deep magenta.", isPro: false,
        noneHex: "#151B23", lowHex: "#fbcfe8", mediumHex: "#f472b6", highHex: "#db2777", veryHighHex: "#9d174d",
        darkLowHex: "#831843", darkMediumHex: "#be185d", darkHighHex: "#ec4899", darkVeryHighHex: "#f9a8d4"
    )
    public static let amber = ThemeColors(
        id: "amber", name: "Amber", description: "Pale yellow to burnt gold.", isPro: false,
        noneHex: "#151B23", lowHex: "#fde68a", mediumHex: "#fbbf24", highHex: "#d97706", veryHighHex: "#92400e",
        darkLowHex: "#78350f", darkMediumHex: "#b45309", darkHighHex: "#f59e0b", darkVeryHighHex: "#fde68a"
    )
    public static let teal = ThemeColors(
        id: "teal", name: "Teal", description: "Mint to deep teal.", isPro: false,
        noneHex: "#151B23", lowHex: "#99f6e4", mediumHex: "#2dd4bf", highHex: "#0d9488", veryHighHex: "#115e59",
        darkLowHex: "#134e4a", darkMediumHex: "#0f766e", darkHighHex: "#14b8a6", darkVeryHighHex: "#5eead4"
    )

    public static let allThemes: [ThemeColors] = [github, ocean, sunset, forest, lavender, rose, amber, teal]
    public static let freeThemes: [ThemeColors] = allThemes

    public static func theme(for id: String) -> ThemeColors {
        allThemes.first { $0.id == id } ?? defaultTheme
    }

    public static let defaultTheme: ThemeColors = github
}

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

public struct ModernPrimaryButtonStyle: ButtonStyle {
    public var isProminent: Bool
    
    public init(isProminent: Bool = true) {
        self.isProminent = isProminent
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        ModernPrimaryButtonView(configuration: configuration, isProminent: isProminent)
    }
}

private struct ModernPrimaryButtonView: View {
    @Environment(\.colorScheme) private var colorScheme
    let configuration: ButtonStyle.Configuration
    let isProminent: Bool
    @State private var isHovered = false
    
    var body: some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(isProminent ? .white : .primary)
            .colorScheme(isProminent ? .dark : colorScheme)
            .tint(isProminent ? .white : .primary)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isProminent
                        ? (colorScheme == .dark
                           ? (isHovered ? Color(hex: "#2C2E34") : Color(hex: "#222428"))
                           : (isHovered ? Color(hex: "#2D2D2D") : Color(hex: "#1E1E1E")))
                        : (colorScheme == .dark
                           ? Color.white.opacity(isHovered ? 0.1 : 0.06)
                           : Color.black.opacity(isHovered ? 0.08 : 0.05))
                     )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : (isHovered ? 1.01 : 1.0))
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

public struct ModernSecondaryButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        ModernSecondaryButtonView(configuration: configuration)
    }
}

private struct ModernSecondaryButtonView: View {
    @Environment(\.colorScheme) private var colorScheme
    let configuration: ButtonStyle.Configuration
    @State private var isHovered = false
    
    var body: some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? Color.white.opacity(isHovered ? 0.09 : 0.04) : Color.black.opacity(isHovered ? 0.08 : 0.04))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : (isHovered ? 1.01 : 1.0))
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

public struct DestructiveButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        DestructiveButtonView(configuration: configuration)
    }
}

private struct DestructiveButtonView: View {
    @Environment(\.colorScheme) private var colorScheme
    let configuration: ButtonStyle.Configuration
    @State private var isHovered = false
    
    var body: some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(isHovered ? .white : Color(hex: "#FF4D4D"))
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color(hex: "#D32F2F") : (colorScheme == .dark ? Color.red.opacity(0.1) : Color.red.opacity(0.06)))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : (isHovered ? 1.01 : 1.0))
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
