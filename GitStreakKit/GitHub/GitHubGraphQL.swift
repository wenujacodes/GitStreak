import Foundation

public struct GitHubGraphQL {
    public static func buildQuery(username: String) -> String {
        let cleanUsername = username.replacingOccurrences(of: "\"", with: "")
        return """
        query($username: String!, $from: DateTime!, $to: DateTime!) {
          user(login: $username) {
            login
            name
            avatarUrl(size: 200)
            bio
            contributionsCollection(from: $from, to: $to) {
              contributionYears
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
          prAssigned: search(query: "type:pr assignee:\(cleanUsername) is:open", type: ISSUE) { issueCount }
          prMentioned: search(query: "type:pr mentions:\(cleanUsername) is:open", type: ISSUE) { issueCount }
          issuesAllCreated: search(query: "type:issue author:\(cleanUsername)", type: ISSUE) { issueCount }
          issuesOpen: search(query: "type:issue author:\(cleanUsername) is:open", type: ISSUE) { issueCount }
          issuesAssigned: search(query: "type:issue assignee:\(cleanUsername) is:open", type: ISSUE) { issueCount }
        }
        """
    }

    public static func makeRequestBody(username: String, year: Int? = nil) -> Data {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(identifier: "UTC")

        let fromDate: Date
        let toDate: Date

        if let y = year {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: "UTC")!

            var components = DateComponents()
            components.year = y
            components.month = 1
            components.day = 1
            components.hour = 0
            components.minute = 0
            components.second = 0
            fromDate = calendar.date(from: components) ?? Date()

            components.month = 12
            components.day = 31
            components.hour = 23
            components.minute = 59
            components.second = 59
            toDate = calendar.date(from: components) ?? Date()
        } else {
            let now = Date()
            toDate = now
            fromDate = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now.addingTimeInterval(-31536000)
        }

        let payload: [String: Any] = [
            "query": buildQuery(username: username),
            "variables": [
                "username": username,
                "from": formatter.string(from: fromDate),
                "to": formatter.string(from: toDate)
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: payload, options: [])
    }
}
