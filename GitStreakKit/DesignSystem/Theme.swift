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

    public init(id: String, name: String, description: String, isPro: Bool, noneHex: String, lowHex: String, mediumHex: String, highHex: String, veryHighHex: String) {
        self.id = id
        self.name = name
        self.description = description
        self.isPro = isPro
        self.noneHex = noneHex
        self.lowHex = lowHex
        self.mediumHex = mediumHex
        self.highHex = highHex
        self.veryHighHex = veryHighHex
    }

    public func color(for level: ContributionLevel, colorScheme: ColorScheme = .dark) -> Color {
        if level.intensity == 0 {
            return colorScheme == .light ? Color(hex: "#dce0e5") : Color(hex: "#333942")
        }

        switch level.intensity {
        case 1: return Color(hex: lowHex)
        case 2: return Color(hex: mediumHex)
        case 3: return Color(hex: highHex)
        case 4: return Color(hex: veryHighHex)
        default: return colorScheme == .light ? Color(hex: "#dce0e5") : Color(hex: "#333942")
        }
    }

    public func color(for level: ContributionLevel) -> Color {
        color(for: level, colorScheme: .dark)
    }

    public var allColors: [Color] {
        allColors(for: .dark)
    }

    public func allColors(for colorScheme: ColorScheme) -> [Color] {
        let empty = colorScheme == .light ? Color(hex: "#dce0e5") : Color(hex: "#333942")
        return [empty, Color(hex: lowHex), Color(hex: mediumHex), Color(hex: highHex), Color(hex: veryHighHex)]
    }
}

public enum ThemeRegistry {
    public static let github = ThemeColors(
        id: "github", name: "GitHub", description: "The classic GitHub green.", isPro: false,
        noneHex: "#22272e", lowHex: "#9be9a8", mediumHex: "#40c463", highHex: "#30a14e", veryHighHex: "#216e39"
    )
    public static let monochrome = ThemeColors(
        id: "monochrome", name: "Monochrome", description: "Clean black and white.", isPro: false,
        noneHex: "#22272e", lowHex: "#b0b0b0", mediumHex: "#787878", highHex: "#444444", veryHighHex: "#111111"
    )
    public static let ocean = ThemeColors(
        id: "ocean", name: "Ocean", description: "Cool blues.", isPro: false,
        noneHex: "#22272e", lowHex: "#79b8ff", mediumHex: "#2188ff", highHex: "#0366d6", veryHighHex: "#044289"
    )
    public static let sunset = ThemeColors(
        id: "sunset", name: "Sunset", description: "Warm oranges.", isPro: false,
        noneHex: "#22272e", lowHex: "#ffb088", mediumHex: "#ff7b42", highHex: "#d9480f", veryHighHex: "#9c2706"
    )
    public static let forest = ThemeColors(
        id: "forest", name: "Forest", description: "Deep greens.", isPro: false,
        noneHex: "#22272e", lowHex: "#99d18b", mediumHex: "#5bb543", highHex: "#358422", veryHighHex: "#1d5212"
    )
    public static let nord = ThemeColors(
        id: "nord", name: "Nord", description: "Arctic, north-bluish color palette.", isPro: false,
        noneHex: "#22272e", lowHex: "#88c0d0", mediumHex: "#5e81ac", highHex: "#4c6f94", veryHighHex: "#2e3440"
    )

    public static let allThemes: [ThemeColors] = [github, monochrome, ocean, sunset, forest, nord]
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
    @Environment(\.colorScheme) private var colorScheme
    public var isProminent: Bool
    
    public init(isProminent: Bool = true) {
        self.isProminent = isProminent
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(isProminent ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isProminent
                        ? (colorScheme == .dark ? Color(hex: "#222428") : Color(hex: "#1E1E1E"))
                        : (colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(configuration.isPressed ? 0.2 : 0.12) : Color.black.opacity(0.12),
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

public struct ModernSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? Color.white.opacity(configuration.isPressed ? 0.08 : 0.04) : Color.black.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
