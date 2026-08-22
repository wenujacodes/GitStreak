import XCTest
@testable import GitStreakKit

final class GraphQLResponseTests: XCTestCase {

    func testDecodeSuccessfulGraphQLPayload() throws {
        let json = """
        {
          "data": {
            "user": {
              "login": "octocat",
              "name": "The Octocat",
              "avatarUrl": "https://avatars.githubusercontent.com/u/583231",
              "bio": "GitHub's mascot",
              "contributionsCollection": {
                "contributionCalendar": {
                  "totalContributions": 42,
                  "weeks": [
                    {
                      "contributionDays": [
                        {
                          "date": "2025-08-15",
                          "contributionCount": 5,
                          "contributionLevel": "SECOND_QUARTILE",
                          "weekday": 5
                        }
                      ]
                    }
                  ]
                }
              }
            }
          }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(GraphQLResponse.self, from: json)
        let (user, weeks, total) = try response.toDomainModel()

        XCTAssertEqual(user.username, "octocat")
        XCTAssertEqual(user.displayName, "The Octocat")
        XCTAssertEqual(user.avatarURL?.absoluteString, "https://avatars.githubusercontent.com/u/583231")
        XCTAssertEqual(user.bio, "GitHub's mascot")
        XCTAssertEqual(total, 42)
        XCTAssertEqual(weeks.count, 1)
        XCTAssertEqual(weeks[0].contributionDays.count, 1)
        XCTAssertEqual(weeks[0].contributionDays[0].contributionCount, 5)
        XCTAssertEqual(weeks[0].contributionDays[0].level, .secondQuartile)
    }

    func testDecodeGraphQLErrorPayload() throws {
        let json = """
        {
          "data": null,
          "errors": [
            {
              "message": "Could not resolve to a User with the login of 'unknown_user_xyz'."
            }
          ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(GraphQLResponse.self, from: json)

        XCTAssertThrowsError(try response.toDomainModel()) { error in
            guard case GitHubAPIError.serverError(let message) = error else {
                XCTFail("Expected GitHubAPIError.serverError, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("Could not resolve to a User"))
        }
    }
}
