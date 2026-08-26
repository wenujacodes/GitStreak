import XCTest
@testable import GitStreakKit

final class TokenStorageTests: XCTestCase {

    override func setUp() {
        super.setUp()
        TokenStorage.clearToken()
    }

    override func tearDown() {
        TokenStorage.clearToken()
        super.tearDown()
    }

    func testTokenSaveLoadAndClear() {
        XCTAssertNil(TokenStorage.loadToken())

        let testToken = "ghp_testToken1234567890abcdef"
        TokenStorage.saveToken(testToken)

        XCTAssertEqual(TokenStorage.loadToken(), testToken)

        // Verify UserPreferences.accessToken delegates to TokenStorage
        XCTAssertEqual(UserPreferences.shared.accessToken, testToken)

        TokenStorage.clearToken()
        XCTAssertNil(TokenStorage.loadToken())
        XCTAssertNil(UserPreferences.shared.accessToken)
    }

    func testTokenIsNeverSavedInUnencryptedPreferencesJSON() throws {
        let testToken = "ghp_secureTokenInKeychainOnly"
        TokenStorage.saveToken(testToken)

        let model = PreferencesModel()
        let encoder = JSONEncoder()
        let data = try encoder.encode(model)
        let jsonString = String(data: data, encoding: .utf8) ?? ""

        XCTAssertFalse(jsonString.contains(testToken))
        XCTAssertFalse(jsonString.contains("accessToken"))
    }
}
