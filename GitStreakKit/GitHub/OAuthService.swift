import Foundation
import AppKit

public struct DeviceCodeResponse: Codable, Sendable {
    public let deviceCode: String
    public let userCode: String
    public let verificationUri: String
    public let expiresIn: Int
    public let interval: Int

    enum CodingKeys: String, CodingKey {
        case deviceCode = "device_code"
        case userCode = "user_code"
        case verificationUri = "verification_uri"
        case expiresIn = "expires_in"
        case interval
    }
}

public struct OAuthTokenResponse: Codable, Sendable {
    public let accessToken: String?
    public let tokenType: String?
    public let scope: String?
    public let error: String?
    public let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case error
        case errorDescription = "error_description"
    }
}

public enum OAuthError: LocalizedError, Sendable {
    case authorizationPending
    case slowDown
    case expiredToken
    case accessDenied
    case networkError(String)
    case invalidResponse
    case userFetchFailed(String)

    public var errorDescription: String? {
        switch self {
        case .authorizationPending:
            return "Waiting for GitHub authorization..."
        case .slowDown:
            return "Polling rate limit hit, slowing down..."
        case .expiredToken:
            return "Authorization code expired. Please try again."
        case .accessDenied:
            return "Access denied on GitHub."
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .invalidResponse:
            return "Invalid response received from GitHub."
        case .userFetchFailed(let msg):
            return "Failed to fetch GitHub profile: \(msg)"
        }
    }
}

public final class OAuthService: @unchecked Sendable {
    public static let shared = OAuthService()

    public static let clientID = "Ov23lidbeTr3oc4Fy82o"
    public static let defaultScopes = "read:user,repo"

    private init() {}

    public func requestDeviceCode(scopes: String = defaultScopes) async throws -> DeviceCodeResponse {
        let url = URL(string: "https://github.com/login/device/code")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("GitStreak", forHTTPHeaderField: "User-Agent")

        let body: [String: String] = [
            "client_id": OAuthService.clientID,
            "scope": scopes
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OAuthError.invalidResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(DeviceCodeResponse.self, from: data)
    }

    public func pollForToken(deviceCode: String, interval: Int = 5) async throws -> String {
        let url = URL(string: "https://github.com/login/oauth/access_token")!
        var currentInterval = max(5, interval)

        let payload: [String: String] = [
            "client_id": OAuthService.clientID,
            "device_code": deviceCode,
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
        ]
        let requestBody = try JSONSerialization.data(withJSONObject: payload)

        while true {
            try await Task.sleep(nanoseconds: UInt64(currentInterval) * 1_000_000_000)

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("GitStreak", forHTTPHeaderField: "User-Agent")
            request.httpBody = requestBody

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw OAuthError.invalidResponse
            }

            let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)

            if let token = tokenResponse.accessToken, !token.isEmpty {
                return token
            }

            if let error = tokenResponse.error {
                switch error {
                case "authorization_pending":
                    continue
                case "slow_down":
                    currentInterval += 5
                    continue
                case "expired_token":
                    throw OAuthError.expiredToken
                case "access_denied":
                    throw OAuthError.accessDenied
                default:
                    throw OAuthError.networkError(tokenResponse.errorDescription ?? error)
                }
            }
        }
    }

    public func fetchAuthenticatedUser(token: String) async throws -> (username: String, name: String?, avatarURL: URL?) {
        let url = URL(string: "https://api.github.com/user")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("GitStreak", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OAuthError.userFetchFailed("HTTP Status \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let login = json["login"] as? String else {
            throw OAuthError.invalidResponse
        }

        let name = json["name"] as? String
        let avatarString = json["avatar_url"] as? String
        let avatarURL = avatarString.flatMap { URL(string: $0) }

        return (username: login, name: name, avatarURL: avatarURL)
    }

    public static func openDeviceLogin(userCode: String, verificationUri: String = "https://github.com/login/device") {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(userCode, forType: .string)

        if let url = URL(string: verificationUri) {
            NSWorkspace.shared.open(url)
        }
    }
}
