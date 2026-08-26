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

    public func color(for level: ContributionLevel, colorScheme: ColorScheme = .dark, isWidget: Bool = false) -> Color {
        if level.intensity == 0 {
            if colorScheme == .light {
                return Color(hex: "#EFF2F5")
            } else {
                return Color(hex: "#2C2C2C")
            }
        }

        switch level.intensity {
        case 1: return Color(hex: lowHex)
        case 2: return Color(hex: mediumHex)
        case 3: return Color(hex: highHex)
        case 4: return Color(hex: veryHighHex)
        default: return colorScheme == .light ? Color(hex: "#EFF2F5") : Color(hex: "#2C2C2C")
        }
    }

    public func color(for level: ContributionLevel) -> Color {
        color(for: level, colorScheme: .dark, isWidget: false)
    }

    public var allColors: [Color] {
        allColors(for: .dark, isWidget: false)
    }

    public func allColors(for colorScheme: ColorScheme, isWidget: Bool = false) -> [Color] {
        let empty = colorScheme == .light ? Color(hex: "#EFF2F5") : Color(hex: "#2C2C2C")
        return [empty, Color(hex: lowHex), Color(hex: mediumHex), Color(hex: highHex), Color(hex: veryHighHex)]
    }
}

public enum ThemeRegistry {
    public static let github = ThemeColors(
        id: "github", name: "GitHub", description: "The classic GitHub green.", isPro: false,
        noneHex: "#151B23", lowHex: "#9be9a8", mediumHex: "#40c463", highHex: "#30a14e", veryHighHex: "#216e39"
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
    public static let nord = ThemeColors(
        id: "nord", name: "Nord", description: "Arctic, north-bluish color palette.", isPro: false,
        noneHex: "#151B23", lowHex: "#88c0d0", mediumHex: "#5e81ac", highHex: "#4c6f94", veryHighHex: "#2e3440"
    )

    public static let allThemes: [ThemeColors] = [github, ocean, sunset, forest, nord]
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
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        colorScheme == .dark
                        ? Color.white.opacity(isHovered ? 0.25 : 0.12)
                        : Color.black.opacity(isHovered ? 0.2 : 0.12),
                        lineWidth: 1
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
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(colorScheme == .dark ? Color.white.opacity(isHovered ? 0.16 : 0.08) : Color.black.opacity(isHovered ? 0.16 : 0.08), lineWidth: 1)
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
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? Color(hex: "#D32F2F") : Color.red.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : (isHovered ? 1.01 : 1.0))
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
