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
                "totalCommitContributions": 120,
                "totalIssueContributions": 5,
                "totalPullRequestContributions": 18,
                "totalPullRequestReviewContributions": 7,
                "totalRepositoryContributions": 3,
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
        let (user, weeks, total, stats, years) = try response.toDomainModel()

        XCTAssertEqual(user.username, "octocat")
        XCTAssertEqual(user.displayName, "The Octocat")
        XCTAssertEqual(user.avatarURL?.absoluteString, "https://avatars.githubusercontent.com/u/583231")
        XCTAssertEqual(user.bio, "GitHub's mascot")
        XCTAssertEqual(total, 42)
        XCTAssertEqual(weeks.count, 1)
        XCTAssertEqual(weeks[0].contributionDays.count, 1)
        XCTAssertEqual(weeks[0].contributionDays[0].contributionCount, 5)
        XCTAssertEqual(weeks[0].contributionDays[0].level, ContributionLevel.secondQuartile)
        XCTAssertEqual(stats.commits, 120)
        XCTAssertEqual(stats.issues, 5)
        XCTAssertEqual(stats.pullRequests, 18)
        XCTAssertEqual(stats.reviews, 7)
        XCTAssertEqual(stats.repositories, 3)
    }

    func testDecodeSuccessfulGraphQLPayloadWithSearchResults() throws {
        let json = """
        {
          "data": {
            "user": {
              "login": "octocat",
              "name": "The Octocat",
              "avatarUrl": "https://avatars.githubusercontent.com/u/583231",
              "bio": "GitHub's mascot",
              "contributionsCollection": {
                "totalCommitContributions": 120,
                "totalIssueContributions": 78,
                "totalPullRequestContributions": 18,
                "totalPullRequestReviewContributions": 7,
                "totalRepositoryContributions": 3,
                "contributionCalendar": {
                  "totalContributions": 42,
                  "weeks": []
                }
              }
            },
            "prAssigned": { "issueCount": 2 },
            "prMentioned": { "issueCount": 4 },
            "issuesAllCreated": { "issueCount": 100 },
            "issuesOpen": { "issueCount": 9 },
            "issuesAssigned": { "issueCount": 3 }
          }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(GraphQLResponse.self, from: json)
        let (_, _, _, stats, _) = try response.toDomainModel()

        XCTAssertEqual(stats.prAssigned, 2)
        XCTAssertEqual(stats.prMentioned, 4)
        XCTAssertEqual(stats.issuesAllCreated, 100)
        XCTAssertEqual(stats.issuesOpenCreated, 9)
        XCTAssertEqual(stats.issuesAssigned, 3)
    }

    func testGitHubGraphQLBuildQuery() {
        let query = GitHubGraphQL.buildQuery(username: "octocat")
        XCTAssertTrue(query.contains("author:octocat"))
        XCTAssertTrue(query.contains("assignee:octocat"))
        XCTAssertFalse(query.contains("$username state:open"))
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
