import XCTest
import SwiftUI
@testable import GitStreakKit

final class ThemeRegistryTests: XCTestCase {
    
    func testDefaultThemeIsGitHub() {
        let theme = ThemeRegistry.defaultTheme
        XCTAssertEqual(theme.id, "github")
        XCTAssertEqual(theme.name, "GitHub")
        XCTAssertFalse(theme.isPro)
    }
    
    func testLookupExistingTheme() {
        let ocean = ThemeRegistry.theme(for: "ocean")
        XCTAssertEqual(ocean.id, "ocean")
        XCTAssertEqual(ocean.name, "Ocean")
        XCTAssertFalse(ocean.isPro)
    }
    
    func testLookupUnknownThemeFallsBackToDefault() {
        let fallback = ThemeRegistry.theme(for: "non_existent_theme_id")
        XCTAssertEqual(fallback.id, ThemeRegistry.defaultTheme.id)
    }
    
    func testProThemesIdentifiedCorrectly() {
        let nord = ThemeRegistry.theme(for: "nord")
        XCTAssertTrue(nord.isPro)
        
        let forest = ThemeRegistry.theme(for: "forest")
        XCTAssertTrue(forest.isPro)
    }
    
    func testFreeThemesExcludesPro() {
        let free = ThemeRegistry.freeThemes
        XCTAssertFalse(free.contains { $0.isPro })
        XCTAssertTrue(free.contains { $0.id == "github" })
        XCTAssertTrue(free.contains { $0.id == "monochrome" })
    }
    
    func testThemeColorsAllLevels() {
        let theme = ThemeRegistry.github
        XCTAssertEqual(theme.allColors.count, 5)
        
        // Ensure color mapping doesn't crash for all contribution levels
        _ = theme.color(for: .none)
        _ = theme.color(for: .firstQuartile)
        _ = theme.color(for: .secondQuartile)
        _ = theme.color(for: .thirdQuartile)
        _ = theme.color(for: .fourthQuartile)
    }
}
