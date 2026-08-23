import XCTest
@testable import GitStreakKit

final class UserActivityStatsTests: XCTestCase {

    func testScaleFraction() {
        XCTAssertEqual(UserActivityStats.scaleFraction(for: 0), 0.0, accuracy: 0.001)
        XCTAssertEqual(UserActivityStats.scaleFraction(for: 1), 0.2, accuracy: 0.001)
        XCTAssertEqual(UserActivityStats.scaleFraction(for: 10), 0.4, accuracy: 0.001)
        XCTAssertEqual(UserActivityStats.scaleFraction(for: 100), 0.6, accuracy: 0.001)
        XCTAssertEqual(UserActivityStats.scaleFraction(for: 1000), 0.8, accuracy: 0.001)
        XCTAssertEqual(UserActivityStats.scaleFraction(for: 10000), 1.0, accuracy: 0.001)
        XCTAssertEqual(UserActivityStats.scaleFraction(for: 50000), 1.0, accuracy: 0.001)
    }

    func testContributionDataBackwardCompatibleDecoding() throws {
        // Old JSON format without activityStats field
        let oldJson = """
        {
          "user": {
            "username": "octocat",
            "displayName": "The Octocat",
            "avatarURL": "https://avatars.githubusercontent.com/u/583231",
            "bio": "GitHub mascot"
          },
          "weeks": [],
          "totalContributions": 150,
          "currentStreak": 5,
          "longestStreak": 10
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ContributionData.self, from: oldJson)

        XCTAssertEqual(decoded.totalContributions, 150)
        XCTAssertEqual(decoded.activityStats.commits, 150)
        XCTAssertEqual(decoded.currentStreak, 5)
        XCTAssertEqual(decoded.longestStreak, 10)
    }

    func testUserActivityStatsInitClampsNegative() {
        let stats = UserActivityStats(commits: -5, issues: -1, pullRequests: 10, reviews: 0, repositories: 2)
        XCTAssertEqual(stats.commits, 0)
        XCTAssertEqual(stats.issues, 0)
        XCTAssertEqual(stats.pullRequests, 10)
        XCTAssertEqual(stats.reviews, 0)
        XCTAssertEqual(stats.repositories, 2)
    }
}
