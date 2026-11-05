import XCTest
import SwiftUI
@testable import GitStreakKit

final class ThemeRegistryTests: XCTestCase {

    func testDefaultThemeIsGitHub() {
        let theme = ThemeRegistry.defaultTheme
        XCTAssertEqual(theme.id, "github")
        XCTAssertEqual(theme.name, "GitHub")
    }

    func testLookupExistingTheme() {
        let ocean = ThemeRegistry.theme(for: "ocean")
        XCTAssertEqual(ocean.id, "ocean")
        XCTAssertEqual(ocean.name, "Ocean")
    }

    func testLookupUnknownThemeFallsBackToDefault() {
        let fallback = ThemeRegistry.theme(for: "non_existent_theme_id")
        XCTAssertEqual(fallback.id, ThemeRegistry.defaultTheme.id)
    }

    func testAllThemesAvailableFreely() {
        let all = ThemeRegistry.allThemes
        XCTAssertEqual(all.count, 8)
        XCTAssertEqual(ThemeRegistry.freeThemes.count, 8)
        XCTAssertFalse(all.contains { $0.id == "monochrome" })
        XCTAssertFalse(all.contains { $0.id == "nord" })
        XCTAssertTrue(all.contains { $0.id == "forest" })
        for id in ["lavender", "rose", "amber", "teal"] {
            XCTAssertTrue(all.contains { $0.id == id }, "missing theme \(id)")
        }
        XCTAssertEqual(Set(all.map(\.id)).count, all.count, "theme ids must be unique")
    }

    func testRemovedNordThemeFallsBackToDefault() {
        // Users who had picked Nord get the default theme instead of a crash or blank grid.
        XCTAssertEqual(ThemeRegistry.theme(for: "nord").id, ThemeRegistry.defaultTheme.id)
    }

    func testThemeColorsAllLevels() {
        let theme = ThemeRegistry.github
        XCTAssertEqual(theme.allColors.count, 5)

        _ = theme.color(for: .none)
        _ = theme.color(for: .firstQuartile)
        _ = theme.color(for: .secondQuartile)
        _ = theme.color(for: .thirdQuartile)
        _ = theme.color(for: .fourthQuartile)
    }

    func testLightModeEmptyBlockColor() {
        let theme = ThemeRegistry.github
        let expectedLightColor = Color(hex: "#EFF2F5")
        XCTAssertEqual(theme.color(for: .none, colorScheme: .light, isWidget: false), expectedLightColor)
        XCTAssertEqual(theme.color(for: .none, colorScheme: .light, isWidget: true), expectedLightColor)
    }

    func testDarkModeWidgetEmptyBlockColor() {
        let theme = ThemeRegistry.github
        let expectedDarkWidgetColor = Color(hex: "#3A3A3C")
        XCTAssertEqual(theme.color(for: .none, colorScheme: .dark, isWidget: true), expectedDarkWidgetColor)
    }

    func testColorSchemeContributionColorsInversion() {
        let theme = ThemeRegistry.github

        // Light mode: higher activity = darker color
        XCTAssertEqual(theme.color(for: .firstQuartile, colorScheme: .light), Color(hex: theme.lowHex))
        XCTAssertEqual(theme.color(for: .secondQuartile, colorScheme: .light), Color(hex: theme.mediumHex))
        XCTAssertEqual(theme.color(for: .thirdQuartile, colorScheme: .light), Color(hex: theme.highHex))
        XCTAssertEqual(theme.color(for: .fourthQuartile, colorScheme: .light), Color(hex: theme.veryHighHex))

        // Dark mode: higher activity = lighter color (uses explicit dark palette when provided)
        let expectedDarkFirst = Color(hex: theme.darkLowHex ?? theme.veryHighHex)
        let expectedDarkSecond = Color(hex: theme.darkMediumHex ?? theme.highHex)
        let expectedDarkThird = Color(hex: theme.darkHighHex ?? theme.mediumHex)
        let expectedDarkFourth = Color(hex: theme.darkVeryHighHex ?? theme.lowHex)
        XCTAssertEqual(theme.color(for: .firstQuartile, colorScheme: .dark), expectedDarkFirst)
        XCTAssertEqual(theme.color(for: .secondQuartile, colorScheme: .dark), expectedDarkSecond)
        XCTAssertEqual(theme.color(for: .thirdQuartile, colorScheme: .dark), expectedDarkThird)
        XCTAssertEqual(theme.color(for: .fourthQuartile, colorScheme: .dark), expectedDarkFourth)

        // Swatch lists reflect the scheme order
        let lightColors = theme.allColors(for: .light)
        XCTAssertEqual(lightColors, [
            Color(hex: "#EFF2F5"),
            Color(hex: theme.lowHex),
            Color(hex: theme.mediumHex),
            Color(hex: theme.highHex),
            Color(hex: theme.veryHighHex)
        ])

        let darkColors = theme.allColors(for: .dark)
        XCTAssertEqual(darkColors, [
            Color(hex: "#3A3A3C"),
            expectedDarkFirst,
            expectedDarkSecond,
            expectedDarkThird,
            expectedDarkFourth
        ])
    }
}
