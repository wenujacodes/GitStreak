import Foundation
import Security

/// Low-level helper for managing secure key-value items in the macOS Keychain.
public enum KeychainService {
    private static let service = "com.gitstreak.github"
    nonisolated(unsafe) private static var inMemoryCache: [String: String] = [:]
    private static let lock = NSLock()

    private static var isRunningInTestEnvironment: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil || NSClassFromString("XCTestCase") != nil
    }

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true
        ]
    }

    /// Saves or updates a secret string (e.g. GitHub Personal Access Token) in the macOS System Keychain.
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

        // Clean up any legacy login.keychain items to prevent OS prompt modals
        let legacyQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(legacyQuery as CFDictionary)

        var query = baseQuery
        query[kSecAttrAccount as String] = key
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            let attributesToUpdate: [String: Any] = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            if updateStatus != errSecSuccess {
                throw KeychainError.saveFailed(updateStatus)
            }
        } else if status == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = data
            let addStatus = SecItemAdd(newItem as CFDictionary, nil)
            if addStatus != errSecSuccess {
                throw KeychainError.saveFailed(addStatus)
            }
        } else {
            throw KeychainError.saveFailed(status)
        }
    }

    public static func load(forKey key: String) -> String? {
        if isRunningInTestEnvironment {
            lock.lock()
            defer { lock.unlock() }
            return inMemoryCache[key]
        }

        // 1. Load from Data Protection Keychain (No OS prompt modal)
        var query = baseQuery
        query[kSecAttrAccount as String] = key
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data, let str = String(data: data, encoding: .utf8), !str.isEmpty {
            return str
        }

        // 2. Migration fallback: If an old entry exists in legacy login.keychain, read & migrate to Data Protection Keychain, then purge legacy item
        let legacyQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var legacyRef: AnyObject?
        if SecItemCopyMatching(legacyQuery as CFDictionary, &legacyRef) == errSecSuccess,
           let data = legacyRef as? Data,
           let legacyToken = String(data: data, encoding: .utf8), !legacyToken.isEmpty {
            SecItemDelete(legacyQuery as CFDictionary)
            try? save(token: legacyToken, forKey: key)
            return legacyToken
        }

        return nil
    }

    public static func delete(forKey key: String) throws {
        if isRunningInTestEnvironment {
            lock.lock()
            inMemoryCache.removeValue(forKey: key)
            lock.unlock()
            return
        }

        var query = baseQuery
        query[kSecAttrAccount as String] = key
        SecItemDelete(query as CFDictionary)

        let legacyQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(legacyQuery as CFDictionary)
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
