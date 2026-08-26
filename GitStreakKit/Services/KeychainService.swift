import Foundation
import Security

/// Low-level helper for managing secure key-value items in the macOS Keychain.
public enum KeychainService {
    private static let service = "com.gitstreak.github"

    /// Saves or updates a secret string (e.g. GitHub Personal Access Token) in the macOS System Keychain.
    /// - Parameters:
    ///   - token: The secret token string to store.
    ///   - key: The key account name for the Keychain entry.
    /// - Throws: `KeychainError.saveFailed` if the OS Keychain API encounters an error.
    public static func save(token: String, forKey key: String) throws {
        guard let data = token.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)

        if status == errSecSuccess {
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data
            ]
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

    /// Loads a secret string from the macOS System Keychain for the given key.
    /// - Parameter key: The key account name of the stored item.
    /// - Returns: The decrypted secret token string, or `nil` if not found.
    public static func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }

    /// Deletes a secret string from the macOS System Keychain for the given key.
    /// - Parameter key: The key account name of the item to delete.
    /// - Throws: `KeychainError.deleteFailed` if deletion fails.
    public static func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
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
