import Foundation

/// High-level credential manager coordinating token persistence across UserPreferences, macOS Keychain, and shared container storage.
public enum TokenStorage {
    private static let tokenFileURL: URL = {
        let home: String
        if let pw = getpwuid(getuid()) {
            home = String(cString: pw.pointee.pw_dir)
        } else {
            home = NSHomeDirectory()
        }
        let dir = URL(fileURLWithPath: home).appendingPathComponent("Library/Application Support/com.gitstreak.shared", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(".token_auth")
    }()

    /// Saves the GitHub access token to UserPreferences, System Keychain, and the shared container file.
    /// - Parameter token: The GitHub Personal Access Token or OAuth token.
    public static func saveToken(_ token: String) {
        UserPreferences.shared.accessToken = token
        try? KeychainService.save(token: token, forKey: "github_pat")
        if let data = token.data(using: .utf8) {
            try? data.write(to: tokenFileURL, options: .atomic)
        }
    }

    /// Loads the stored GitHub access token checking in order: UserPreferences memory, System Keychain, and shared container file.
    /// - Returns: The access token string, or `nil` if none exists.
    public static func loadToken() -> String? {
        if let token = UserPreferences.shared.accessToken, !token.isEmpty {
            return token
        }
        if let token = KeychainService.load(forKey: "github_pat"), !token.isEmpty {
            UserPreferences.shared.accessToken = token
            return token
        }
        if let data = try? Data(contentsOf: tokenFileURL),
           let token = String(data: data, encoding: .utf8), !token.isEmpty {
            UserPreferences.shared.accessToken = token
            return token
        }
        return nil
    }

    /// Clears the stored access token from memory, Keychain, and local shared storage.
    public static func clearToken() {
        UserPreferences.shared.accessToken = nil
        try? KeychainService.delete(forKey: "github_pat")
        if FileManager.default.fileExists(atPath: tokenFileURL.path) {
            try? FileManager.default.removeItem(at: tokenFileURL)
        }
    }
}
