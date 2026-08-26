import Foundation

/// High-level credential manager coordinating token persistence across UserPreferences, macOS Keychain, and shared container storage.
public enum TokenStorage {
    private static var groupDefaults: UserDefaults {
        UserDefaults(suiteName: "group.com.gitstreak") ?? .standard
    }
    private static let tokenKey = "github_pat"

    private static var legacyTokenFileURL: URL {
        return SharedContainer.url.appendingPathComponent(".token_auth")
    }

    /// Saves the GitHub access token securely into the macOS System Keychain and synced App Group container.
    /// - Parameter token: The GitHub Personal Access Token or OAuth token.
    public static func saveToken(_ token: String) {
        let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanToken.isEmpty else { return }

        removeLegacyFile()
        try? KeychainService.save(token: cleanToken, forKey: tokenKey)
        groupDefaults.set(cleanToken, forKey: tokenKey)
        groupDefaults.synchronize()
    }

    /// Loads the stored GitHub access token from Keychain with App Group container fallback.
    /// - Returns: The access token string, or `nil` if none exists.
    public static func loadToken() -> String? {
        if let token = KeychainService.load(forKey: tokenKey), !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return token.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let token = groupDefaults.string(forKey: tokenKey), !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
            try? KeychainService.save(token: cleanToken, forKey: tokenKey)
            return cleanToken
        }

        if FileManager.default.fileExists(atPath: legacyTokenFileURL.path),
           let data = try? Data(contentsOf: legacyTokenFileURL),
           let rawToken = String(data: data, encoding: .utf8), !rawToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let cleanToken = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
            saveToken(cleanToken)
            removeLegacyFile()
            return cleanToken
        }

        return nil
    }

    /// Clears the stored access token completely from macOS Keychain and App Group storage.
    public static func clearToken() {
        try? KeychainService.delete(forKey: tokenKey)
        groupDefaults.removeObject(forKey: tokenKey)
        groupDefaults.synchronize()
        removeLegacyFile()
    }

    private static func removeLegacyFile() {
        if FileManager.default.fileExists(atPath: legacyTokenFileURL.path) {
            try? FileManager.default.removeItem(at: legacyTokenFileURL)
        }
    }
}
