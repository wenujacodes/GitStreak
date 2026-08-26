import Foundation

public struct UserActivityStats: Codable, Sendable, Equatable {
    public let commits: Int
    public let issues: Int
    public let pullRequests: Int
    public let reviews: Int
    public let repositories: Int

    public let prCreated: Int
    public let prAssigned: Int
    public let prMentioned: Int
    public let prReviewRequested: Int

    public let issuesAllCreated: Int
    public let issuesOpenCreated: Int
    public let issuesAssigned: Int

    public init(
        commits: Int = 0,
        issues: Int = 0,
        pullRequests: Int = 0,
        reviews: Int = 0,
        repositories: Int = 0,
        prCreated: Int? = nil,
        prAssigned: Int = 0,
        prMentioned: Int = 0,
        prReviewRequested: Int? = nil,
        issuesAllCreated: Int? = nil,
        issuesOpenCreated: Int = 0,
        issuesAssigned: Int = 0
    ) {
        self.commits = max(0, commits)
        self.issues = max(0, issues)
        self.pullRequests = max(0, pullRequests)
        self.reviews = max(0, reviews)
        self.repositories = max(0, repositories)

        self.prCreated = max(0, prCreated ?? pullRequests)
        self.prAssigned = max(0, prAssigned)
        self.prMentioned = max(0, prMentioned)
        self.prReviewRequested = max(0, prReviewRequested ?? reviews)

        self.issuesAllCreated = max(0, issuesAllCreated ?? issues)
        self.issuesOpenCreated = max(0, issuesOpenCreated)
        self.issuesAssigned = max(0, issuesAssigned)
    }

    public func count(for filter: PRWidgetFilter) -> Int {
        switch filter {
        case .created: return prCreated
        case .assigned: return prAssigned
        case .mentioned: return prMentioned
        case .reviewRequested: return prReviewRequested
        }
    }

    public func count(for filter: IssueWidgetFilter) -> Int {
        switch filter {
        case .allCreated: return issuesAllCreated
        case .openCreated: return issuesOpenCreated
        case .assigned: return issuesAssigned
        }
    }

    /// Calculates a normalized radius fraction (0.0 ... 1.0) on a 5-level logarithmic scale:
    /// Level 1: 1 (0.2)
    /// Level 2: 10 (0.4)
    /// Level 3: 100 (0.6)
    /// Level 4: 1,000 (0.8)
    /// Level 5: 10,000 (1.0)
    public static func scaleFraction(for value: Int) -> Double {
        guard value > 0 else { return 0.0 }
        let logVal = log10(Double(value))
        let clamped = min(max(logVal, 0.0), 4.0)
        return (clamped + 1.0) / 5.0
    }

    public var commitFraction: Double { Self.scaleFraction(for: commits) }
    public var issueFraction: Double { Self.scaleFraction(for: issues) }
    public var pullRequestFraction: Double { Self.scaleFraction(for: pullRequests) }
    public var reviewFraction: Double { Self.scaleFraction(for: reviews) }
    public var repositoryFraction: Double { Self.scaleFraction(for: repositories) }

    public static let sample = UserActivityStats(
        commits: 850,
        issues: 8,
        pullRequests: 95,
        reviews: 24,
        repositories: 14
    )
}
