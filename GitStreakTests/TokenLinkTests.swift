import XCTest
@testable import GitStreakKit

final class TokenLinkTests: XCTestCase {

    /// Classic token with repo + read:user: the only token type that reads private
    /// activity across organizations (fine-grained tokens miss org work).
    func testCreateTokenLinkRequestsClassicScopes() throws {
        let components = try XCTUnwrap(URLComponents(url: OAuthService.createTokenURL, resolvingAgainstBaseURL: false))
        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        XCTAssertEqual(components.host, "github.com")
        XCTAssertEqual(components.path, "/settings/tokens/new")
        XCTAssertEqual(Set((items["scopes"] ?? "").split(separator: ",").map(String.init)), ["repo", "read:user"])
    }
}
