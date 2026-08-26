import Foundation

/// High-level credential manager coordinating token persistence across UserPreferences, macOS Keychain, and shared container storage.
public enum TokenStorage {
    private static var legacyTokenFileURL: URL {
        return SharedContainer.url.appendingPathComponent(".token_auth")
    }

    /// Saves the GitHub access token exclusively into the encrypted macOS System Keychain.
    /// - Parameter token: The GitHub Personal Access Token or OAuth token.
    public static func saveToken(_ token: String) {
        // Purge legacy unencrypted file if present
        removeLegacyFile()
        try? KeychainService.save(token: token, forKey: "github_pat")
    }

    /// Loads the stored GitHub access token strictly from the encrypted macOS System Keychain.
    /// Performs automatic one-time migration from any legacy unencrypted disk files.
    /// - Returns: The access token string, or `nil` if none exists.
    public static func loadToken() -> String? {
        if let token = KeychainService.load(forKey: "github_pat"), !token.isEmpty {
            return token
        }
        // Legacy file migration: if an old unencrypted token file exists, migrate to Keychain then delete file
        if FileManager.default.fileExists(atPath: legacyTokenFileURL.path),
           let data = try? Data(contentsOf: legacyTokenFileURL),
           let token = String(data: data, encoding: .utf8), !token.isEmpty {
            try? KeychainService.save(token: token, forKey: "github_pat")
            removeLegacyFile()
            return token
        }
        return nil
    }

    /// Clears the stored access token completely from macOS Keychain and deletes any legacy local disk files.
    public static func clearToken() {
        try? KeychainService.delete(forKey: "github_pat")
        removeLegacyFile()
    }

    private static func removeLegacyFile() {
        if FileManager.default.fileExists(atPath: legacyTokenFileURL.path) {
            try? FileManager.default.removeItem(at: legacyTokenFileURL)
        }
    }
}
