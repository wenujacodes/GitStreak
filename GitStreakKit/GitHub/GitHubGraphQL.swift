import Foundation

public struct GitHubGraphQL {
    public static let query = """
    query($username: String!, $from: DateTime!, $to: DateTime!) {
      user(login: $username) {
        login
        name
        avatarUrl(size: 200)
        bio
        contributionsCollection(from: $from, to: $to) {
          totalCommitContributions
          totalIssueContributions
          totalPullRequestContributions
          totalPullRequestReviewContributions
          totalRepositoryContributions
          contributionCalendar {
            totalContributions
            weeks {
              contributionDays {
                date
                contributionCount
                contributionLevel
                weekday
              }
            }
          }
        }
      }
    }
    """

    public static func makeRequestBody(username: String) -> Data {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        let now = Date()
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now.addingTimeInterval(-31536000)

        let payload: [String: Any] = [
            "query": query,
            "variables": [
                "username": username,
                "from": formatter.string(from: oneYearAgo),
                "to": formatter.string(from: now)
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: payload, options: [])
    }
}
