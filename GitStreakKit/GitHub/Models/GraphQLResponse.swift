import Foundation

public struct GraphQLResponse: Codable, Sendable, Equatable {
    public let data: GraphQLData?
    public let message: String?
    public let errors: [GraphQLError]?
}

public struct GraphQLData: Codable, Sendable, Equatable {
    public let user: GraphQLUser?
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
    public let contributionCalendar: ContributionCalendar
}

public struct ContributionCalendar: Codable, Sendable, Equatable {
    public let totalContributions: Int
    public let weeks: [ContributionWeek]
}

extension GraphQLResponse {
    public func toDomainModel() throws -> (user: GitHubUser, weeks: [ContributionWeek], totalContributions: Int) {
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

        return (gitHubUser, weeks, totalContributions)
    }
}
