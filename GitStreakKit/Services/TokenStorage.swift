import Foundation

/// Stores the GitHub access token in the macOS login Keychain.
///
/// Older versions (up to 1.1.10) kept the token in plain text, because saving to the
/// Keychain was silently failing. On first load, any plain-text copy is moved into the
/// Keychain and deleted, but only after the Keychain save succeeds, so nobody is signed out.
/// If the Keychain is unavailable, the plain-text copy is kept as a last resort.
///
/// Only the app uses the token. The widget reads the shared cache and never needs it.
public enum TokenStorage {
    private static var groupDefaults: UserDefaults {
        // Tests use an in-memory Keychain, so they must not touch the real settings either.
        let suite = KeychainService.isRunningInTestEnvironment ? "com.gitstreak.tests" : "group.com.gitstreak"
        return UserDefaults(suiteName: suite) ?? .standard
    }
    private static let tokenKey = "github_pat"
    private static let lock = NSLock()
    nonisolated(unsafe) private static var inMemoryCache: String?
    nonisolated(unsafe) private static var accessDenied = false

    /// True when the token is in the Keychain but the user denied access to this build.
    /// We stop asking until the user saves a token again, to avoid repeated dialogs.
    public static var keychainAccessDenied: Bool {
        lock.lock()
        defer { lock.unlock() }
        return accessDenied
    }

    /// Plain-text token file used by versions before 1.1.10.
    private static var legacyTokenFileURL: URL {
        return SharedContainer.url.appendingPathComponent(".token_auth")
    }

    /// Saves the GitHub access token in the Keychain and removes any plain-text copy.
    /// - Parameter token: The GitHub Personal Access Token or OAuth token.
    public static func saveToken(_ token: String) {
        let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanToken.isEmpty else { return }

        lock.lock()
        inMemoryCache = cleanToken
        accessDenied = false
        lock.unlock()

        storeSecurely(cleanToken)
    }

    /// Loads the stored GitHub access token, migrating any plain-text copy into the Keychain.
    /// - Returns: The access token string, or `nil` if none exists.
    public static func loadToken() -> String? {
        lock.lock()
        if let cached = inMemoryCache, !cached.isEmpty {
            lock.unlock()
            return cached
        }
        if accessDenied {
            lock.unlock()
            return nil
        }
        lock.unlock()

        switch KeychainService.read(forKey: tokenKey) {
        case .found(let token):
            if let token = clean(token) {
                cache(token)
                removePlaintextCopies()
                return token
            }
        case .denied:
            lock.lock()
            accessDenied = true
            lock.unlock()
            return nil
        case .notFound:
            break
        }

        // Migrate from plain-text storage used by older versions.
        if let token = clean(groupDefaults.string(forKey: tokenKey)) ?? readLegacyTokenFile() {
            cache(token)
            storeSecurely(token)
            return token
        }

        return nil
    }

    /// Clears the stored access token from the Keychain and any plain-text location.
    public static func clearToken() {
        lock.lock()
        inMemoryCache = nil
        accessDenied = false
        lock.unlock()

        try? KeychainService.delete(forKey: tokenKey)
        removePlaintextCopies()
    }

    // MARK: - Private

    /// Saves to the Keychain. Plain-text copies are only removed once that succeeded;
    /// if the Keychain fails, the token is kept in plain text so the user stays signed in.
    private static func storeSecurely(_ token: String) {
        do {
            try KeychainService.save(token: token, forKey: tokenKey)
            removePlaintextCopies()
        } catch {
            groupDefaults.set(token, forKey: tokenKey)
        }
    }

    private static func removePlaintextCopies() {
        if groupDefaults.object(forKey: tokenKey) != nil {
            groupDefaults.removeObject(forKey: tokenKey)
        }
        if FileManager.default.fileExists(atPath: legacyTokenFileURL.path) {
            try? FileManager.default.removeItem(at: legacyTokenFileURL)
        }
    }

    private static func readLegacyTokenFile() -> String? {
        guard let data = try? Data(contentsOf: legacyTokenFileURL) else { return nil }
        return clean(String(data: data, encoding: .utf8))
    }

    private static func cache(_ token: String) {
        lock.lock()
        inMemoryCache = token
        lock.unlock()
    }

    private static func clean(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
