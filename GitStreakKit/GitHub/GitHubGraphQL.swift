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
          prAllCreated: search(query: "type:pr author:\(cleanUsername)", type: ISSUE) { issueCount }
          prOpenCreated: search(query: "type:pr author:\(cleanUsername) is:open", type: ISSUE) { issueCount }
          prAssigned: search(query: "type:pr assignee:\(cleanUsername) is:open", type: ISSUE) { issueCount }
          prMentioned: search(query: "type:pr involves:\(cleanUsername) is:open", type: ISSUE) { issueCount }
          prReviewRequested: search(query: "type:pr review-requested:\(cleanUsername) is:open", type: ISSUE) { issueCount }
          issuesAllCreated: search(query: "type:issue author:\(cleanUsername)", type: ISSUE) { issueCount }
          issuesOpen: search(query: "type:issue author:\(cleanUsername) is:open", type: ISSUE) { issueCount }
          issuesAssigned: search(query: "type:issue assignee:\(cleanUsername) is:open", type: ISSUE) { issueCount }
        }
        """
    }

    /// GitHub logins only contain letters, numbers and hyphens (max 39 characters).
    /// The username is placed inside search strings, so anything else (spaces, quotes,
    /// extra search words) is rejected rather than sent.
    public static func isValidUsername(_ username: String) -> Bool {
        username.range(of: "^[A-Za-z0-9-]{1,39}$", options: .regularExpression) != nil
    }

    public static let calendarQuery = """
    query($username: String!, $from: DateTime!, $to: DateTime!) {
      user(login: $username) {
        contributionsCollection(from: $from, to: $to) {
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

    /// Request for one year's contribution days only (see `GitHubAPIClient.fetchCalendarDays`).
    public static func makeCalendarRequestBody(username: String, year: Int) throws -> Data {
        guard isValidUsername(username) else {
            throw GitHubAPIError.userNotFound
        }
        let (from, to) = yearRange(year)
        let payload: [String: Any] = [
            "query": calendarQuery,
            "variables": ["username": username, "from": from, "to": to]
        ]
        return try JSONSerialization.data(withJSONObject: payload, options: [])
    }

    /// Jan 1 00:00:00 to Dec 31 23:59:59 (UTC) of a year, as ISO 8601 strings.
    static func yearRange(_ year: Int) -> (String, String) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(identifier: "UTC")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let from = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? Date()
        let to = calendar.date(from: DateComponents(year: year, month: 12, day: 31, hour: 23, minute: 59, second: 59)) ?? Date()
        return (formatter.string(from: from), formatter.string(from: to))
    }

    public static func makeRequestBody(username: String, year: Int? = nil) throws -> Data {
        guard isValidUsername(username) else {
            throw GitHubAPIError.userNotFound
        }

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
        return try JSONSerialization.data(withJSONObject: payload, options: [])
    }
}
