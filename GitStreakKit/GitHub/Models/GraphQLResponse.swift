import Foundation

public struct GraphQLResponse: Codable, Sendable, Equatable {
    public let data: GraphQLData?
    public let message: String?
    public let errors: [GraphQLError]?
}

public struct SearchResult: Codable, Sendable, Equatable {
    public let issueCount: Int
}

public struct GraphQLData: Codable, Sendable, Equatable {
    public let user: GraphQLUser?
    public let prAssigned: SearchResult?
    public let prMentioned: SearchResult?
    public let issuesAllCreated: SearchResult?
    public let issuesOpen: SearchResult?
    public let issuesAssigned: SearchResult?
}

public struct GraphQLError: Codable, Sendable, Equatable {
    public let message: String
}

public struct GraphQLUser: Codable, Sendable, Equatable {
    public let login: String
    public let name: String?
    public let avatarUrl: URL?
    public let bio: String?
    public let contributionsCollection: ContributionsCollection

    public func toDomainModel() -> GitHubUser {
        return GitHubUser(
            username: login,
            displayName: name,
            avatarURL: avatarUrl,
            bio: bio
        )
    }
}

public struct ContributionsCollection: Codable, Sendable, Equatable {
    public let contributionYears: [Int]?
    public let totalCommitContributions: Int?
    public let totalIssueContributions: Int?
    public let totalPullRequestContributions: Int?
    public let totalPullRequestReviewContributions: Int?
    public let totalRepositoryContributions: Int?
    public let contributionCalendar: ContributionCalendar
}

public struct ContributionCalendar: Codable, Sendable, Equatable {
    public let totalContributions: Int
    public let weeks: [ContributionWeek]
}

extension GraphQLResponse {
    public func toDomainModel() throws -> (user: GitHubUser, weeks: [ContributionWeek], totalContributions: Int, activityStats: UserActivityStats, contributionYears: [Int]) {
        if let errors = errors, let firstError = errors.first {
            throw GitHubAPIError.serverError(firstError.message)
        }

        if let message = message {
            throw GitHubAPIError.serverError(message)
        }

        guard let data = data, let user = data.user else {
            throw GitHubAPIError.userNotFound
        }

        let gitHubUser = user.toDomainModel()
        let weeks = user.contributionsCollection.contributionCalendar.weeks
        let totalContributions = user.contributionsCollection.contributionCalendar.totalContributions
        let activityStats = UserActivityStats(
            commits: user.contributionsCollection.totalCommitContributions ?? totalContributions,
            issues: user.contributionsCollection.totalIssueContributions ?? 0,
            pullRequests: user.contributionsCollection.totalPullRequestContributions ?? 0,
            reviews: user.contributionsCollection.totalPullRequestReviewContributions ?? 0,
            repositories: user.contributionsCollection.totalRepositoryContributions ?? 0,
            prCreated: user.contributionsCollection.totalPullRequestContributions ?? 0,
            prAssigned: data.prAssigned?.issueCount ?? 0,
            prMentioned: data.prMentioned?.issueCount ?? 0,
            prReviewRequested: user.contributionsCollection.totalPullRequestReviewContributions ?? 0,
            issuesAllCreated: data.issuesAllCreated?.issueCount ?? (user.contributionsCollection.totalIssueContributions ?? 0),
            issuesOpenCreated: data.issuesOpen?.issueCount ?? 0,
            issuesAssigned: data.issuesAssigned?.issueCount ?? 0
        )
        let years = user.contributionsCollection.contributionYears ?? []

        return (gitHubUser, weeks, totalContributions, activityStats, years)
    }
}
