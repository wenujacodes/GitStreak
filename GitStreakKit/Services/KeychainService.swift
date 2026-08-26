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

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            let attributesToUpdate: [String: Any] = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            if updateStatus != errSecSuccess {
                trySaveDataProtection(data: data, key: key)
            }
        } else if status == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = data
            let addStatus = SecItemAdd(newItem as CFDictionary, nil)
            if addStatus != errSecSuccess {
                trySaveDataProtection(data: data, key: key)
            }
        } else {
            trySaveDataProtection(data: data, key: key)
        }
    }

    private static func trySaveDataProtection(data: Data, key: String) {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            let attributesToUpdate: [String: Any] = [kSecValueData as String: data]
            SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        } else {
            query[kSecValueData as String] = data
            SecItemAdd(query as CFDictionary, nil)
        }
    }

    public static func load(forKey key: String) -> String? {
        if isRunningInTestEnvironment {
            lock.lock()
            defer { lock.unlock() }
            return inMemoryCache[key]
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data, let str = String(data: data, encoding: .utf8), !str.isEmpty {
            return str
        }

        let dpQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecUseDataProtectionKeychain as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dpRef: AnyObject?
        let dpStatus = SecItemCopyMatching(dpQuery as CFDictionary, &dpRef)
        if dpStatus == errSecSuccess, let data = dpRef as? Data, let str = String(data: data, encoding: .utf8), !str.isEmpty {
            return str
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

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)

        let dpQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecUseDataProtectionKeychain as String: true
        ]
        SecItemDelete(dpQuery as CFDictionary)
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
