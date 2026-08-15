import Foundation

public struct GitHubGraphQL {
    public static let query = """
    query($username: String!) {
      user(login: $username) {
        login
        name
        avatarUrl(size: 200)
        bio
        contributionsCollection {
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
        let payload: [String: Any] = [
            "query": query,
            "variables": ["username": username]
        ]
        return try! JSONSerialization.data(withJSONObject: payload, options: [])
    }
}
