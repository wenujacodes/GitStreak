import Foundation
import Security

/// Low-level helper for managing secure key-value items in the macOS Keychain.
public enum KeychainService {
    private static let service = "com.gitstreak.github"
    nonisolated(unsafe) private static var inMemoryCache: [String: String] = [:]
    private static let lock = NSLock()

    internal static var isRunningInTestEnvironment: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil || NSClassFromString("XCTestCase") != nil
    }

    /// Uses the login Keychain. The newer data protection Keychain
    /// (`kSecUseDataProtectionKeychain`) needs a Team ID entitlement, which ad-hoc and
    /// self-signed builds don't have: it fails with -34018 (errSecMissingEntitlement).
    private static func query(forKey key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }

    /// Saves or updates a secret string (e.g. GitHub Personal Access Token) in the macOS login Keychain.
    /// - Parameters:
    ///   - token: The secret token string to store.
    ///   - key: The key account name for the Keychain entry.
    /// - Throws: `KeychainError.saveFailed` if the OS Keychain API encounters an error.
    public static func save(token: String, forKey key: String) throws {
        if isRunningInTestEnvironment {
            lock.lock()
            inMemoryCache[key] = token
            lock.unlock()
            return
        }

        guard let data = token.data(using: .utf8) else { return }
        let query = query(forKey: key)

        let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }
        if updateStatus != errSecItemNotFound {
            // The existing item is blocked for this build (e.g. access was denied).
            // Replace it with a fresh item owned by this build.
            let deleteStatus = SecItemDelete(query as CFDictionary)
            guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
                throw KeychainError.saveFailed(updateStatus)
            }
        }

        var newItem = query
        newItem[kSecValueData as String] = data
        newItem[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        newItem[kSecAttrLabel as String] = "GitStreak GitHub Token"
        let addStatus = SecItemAdd(newItem as CFDictionary, nil)
        if addStatus != errSecSuccess {
            throw KeychainError.saveFailed(addStatus)
        }
    }

    /// Result of reading a Keychain item.
    public enum ReadResult: Equatable, Sendable {
        case found(String)
        case notFound
        /// The item exists but macOS didn't allow access (the user clicked Deny or cancelled).
        /// Without a Team ID, each new build of the app has to be approved once.
        case denied
    }

    public static func load(forKey key: String) -> String? {
        if case .found(let token) = read(forKey: key) {
            return token
        }
        return nil
    }

    public static func read(forKey key: String) -> ReadResult {
        if isRunningInTestEnvironment {
            lock.lock()
            defer { lock.unlock() }
            return inMemoryCache[key].map { .found($0) } ?? .notFound
        }

        var query = query(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                  let token = String(data: data, encoding: .utf8),
                  !token.isEmpty else {
                return .notFound
            }
            return .found(token)
        case errSecAuthFailed, errSecUserCanceled, errSecInteractionNotAllowed:
            return .denied
        default:
            return .notFound
        }
    }

    public static func delete(forKey key: String) throws {
        if isRunningInTestEnvironment {
            lock.lock()
            inMemoryCache.removeValue(forKey: key)
            lock.unlock()
            return
        }

        let status = SecItemDelete(query(forKey: key) as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deleteFailed(status)
        }
    }
}

/// Errors thrown by `KeychainService` operations.
public enum KeychainError: Error, LocalizedError, Equatable {
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to Keychain with status code: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from Keychain with status code: \(status)"
        }
    }
}
