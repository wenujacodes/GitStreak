import SwiftUI

// ContributionLevel is defined in ContributionDay.swift

public struct ThemeColors: Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let isPro: Bool
    
    // Colors stored as hex strings for Codable
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
    
    public func color(for level: ContributionLevel) -> Color {
        switch level.intensity {
        case 0: return Color(hex: noneHex)
        case 1: return Color(hex: lowHex)
        case 2: return Color(hex: mediumHex)
        case 3: return Color(hex: highHex)
        case 4: return Color(hex: veryHighHex)
        default: return Color(hex: noneHex)
        }
    }
    
    public var allColors: [Color] {
        [Color(hex: noneHex), Color(hex: lowHex), Color(hex: mediumHex), Color(hex: highHex), Color(hex: veryHighHex)]
    }
}

public enum ThemeRegistry {
    public static let github = ThemeColors(
        id: "github", name: "GitHub", description: "The classic GitHub green.", isPro: false,
        noneHex: "#ebedf0", lowHex: "#9be9a8", mediumHex: "#40c463", highHex: "#30a14e", veryHighHex: "#216e39"
    )
    public static let monochrome = ThemeColors(
        id: "monochrome", name: "Monochrome", description: "Clean black and white.", isPro: false,
        noneHex: "#eeeeee", lowHex: "#c6c6c6", mediumHex: "#919191", highHex: "#5a5a5a", veryHighHex: "#333333"
    )
    public static let ocean = ThemeColors(
        id: "ocean", name: "Ocean", description: "Cool blues.", isPro: false,
        noneHex: "#e0f0ff", lowHex: "#a3d5ff", mediumHex: "#5aacf5", highHex: "#2b7fd4", veryHighHex: "#1a4f8a"
    )
    public static let sunset = ThemeColors(
        id: "sunset", name: "Sunset", description: "Warm oranges.", isPro: false,
        noneHex: "#fff0e6", lowHex: "#ffc9a3", mediumHex: "#ff9a5c", highHex: "#e06b2d", veryHighHex: "#a63d0a"
    )
    public static let forest = ThemeColors(
        id: "forest", name: "Forest", description: "Deep greens.", isPro: false,
        noneHex: "#ecf5e8", lowHex: "#b5d9a3", mediumHex: "#7abf5e", highHex: "#4a9434", veryHighHex: "#2d6420"
    )
    public static let nord = ThemeColors(
        id: "nord", name: "Nord", description: "Arctic, north-bluish color palette.", isPro: false,
        noneHex: "#eceff4", lowHex: "#88c0d0", mediumHex: "#5e81ac", highHex: "#4c6f94", veryHighHex: "#2e3440"
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
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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
