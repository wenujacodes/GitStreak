import Foundation

public enum GitHubAPIError: LocalizedError, Sendable {
    case unauthorized
    case userNotFound
    case networkError(Error)
    case rateLimited
    case decodingError(Error)
    case serverError(String)
    case unknown

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Unauthorized. Please check your GitHub token."
        case .userNotFound:
            return "User not found. Please check the username."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimited:
            return "GitHub API rate limit exceeded. Please try again later."
        case .decodingError(let error):
            return "Failed to parse data: \(error.localizedDescription)"
        case .serverError(let message):
            return "GitHub server error: \(message)"
        case .unknown:
            return "An unknown error occurred."
        }
    }

    public static func == (lhs: GitHubAPIError, rhs: GitHubAPIError) -> Bool {
        switch (lhs, rhs) {
        case (.unauthorized, .unauthorized): return true
        case (.userNotFound, .userNotFound): return true
        case (.rateLimited, .rateLimited): return true
        case (.unknown, .unknown): return true
        case (.serverError(let a), .serverError(let b)): return a == b
        default: return false
        }
    }
}

public actor GitHubAPIClient {
    private let endpoint = URL(string: "https://api.github.com/graphql")!

    public init() {}

    public func fetchContributions(username: String, token: String) async throws -> (GitHubUser, [ContributionWeek], Int) {
        var request = URLRequest(url: endpoint, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
        request.httpMethod = "POST"
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedToken.isEmpty {
            if trimmedToken.hasPrefix("Bearer ") {
                request.setValue(trimmedToken, forHTTPHeaderField: "Authorization")
            } else {
                request.setValue("Bearer \(trimmedToken)", forHTTPHeaderField: "Authorization")
            }
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("GitStreak", forHTTPHeaderField: "User-Agent")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        request.httpBody = GitHubGraphQL.makeRequestBody(username: username)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw GitHubAPIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.unknown
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw GitHubAPIError.unauthorized
        case 403:
            throw GitHubAPIError.rateLimited
        case 404:
            throw GitHubAPIError.userNotFound
        default:
            throw GitHubAPIError.serverError("HTTP Status \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        let graphQLResponse: GraphQLResponse
        do {
            graphQLResponse = try decoder.decode(GraphQLResponse.self, from: data)
        } catch {
            throw GitHubAPIError.decodingError(error)
        }

        return try graphQLResponse.toDomainModel()
    }
}
