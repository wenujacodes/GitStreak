import Foundation

public final class CacheManager: Sendable {
    private static let fileName = "contribution_cache.json"
    private static let groupID = "group.com.gitstreak.shared"
    private static let staleDuration: TimeInterval = 30 * 60 // 30 minutes
    
    public init() {}
    
    /// Returns the App Group shared container directory if available and writable,
    /// otherwise falls back to Application Support.
    private var primaryDirectoryURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.groupID)
    }
    
    private var fallbackDirectoryURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return appSupport.appendingPathComponent("com.gitstreak.shared", isDirectory: true)
    }
    
    /// Target file URL to write to, ensuring directory exists and is writable.
    private func getWritableFileURL() -> URL? {
        // Try App Group directory first
        if let groupDir = primaryDirectoryURL {
            do {
                if !FileManager.default.fileExists(atPath: groupDir.path) {
                    try FileManager.default.createDirectory(at: groupDir, withIntermediateDirectories: true, attributes: nil)
                }
                // Test writability
                if FileManager.default.isWritableFile(atPath: groupDir.path) {
                    return groupDir.appendingPathComponent(Self.fileName)
                }
            } catch {
                // Not permitted or failed, proceed to fallback
            }
        }
        
        // Fallback to Application Support directory
        if let fallbackDir = fallbackDirectoryURL {
            do {
                if !FileManager.default.fileExists(atPath: fallbackDir.path) {
                    try FileManager.default.createDirectory(at: fallbackDir, withIntermediateDirectories: true, attributes: nil)
                }
                return fallbackDir.appendingPathComponent(Self.fileName)
            } catch {
                return nil
            }
        }
        
        return nil
    }
    
    /// Returns candidate file URLs to read from in priority order (Group Container -> App Support).
    private var readableCandidateURLs: [URL] {
        var candidates: [URL] = []
        if let groupDir = primaryDirectoryURL {
            candidates.append(groupDir.appendingPathComponent(Self.fileName))
        }
        if let fallbackDir = fallbackDirectoryURL {
            candidates.append(fallbackDir.appendingPathComponent(Self.fileName))
        }
        return candidates
    }
    
    public func save(_ data: ContributionData) throws {
        guard let fileURL = getWritableFileURL() else {
            throw NSError(
                domain: "CacheManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to create or access cache storage directory."]
            )
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let encodedData = try encoder.encode(data)
        try encodedData.write(to: fileURL, options: .atomic)
    }
    
    public func load() -> ContributionData? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for fileURL in readableCandidateURLs {
            if FileManager.default.fileExists(atPath: fileURL.path),
               let data = try? Data(contentsOf: fileURL),
               let decoded = try? decoder.decode(ContributionData.self, from: data) {
                return decoded
            }
        }
        
        return nil
    }
    
    public func isFresh() -> Bool {
        for fileURL in readableCandidateURLs {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                    if let modificationDate = attributes[.modificationDate] as? Date {
                        return Date().timeIntervalSince(modificationDate) < Self.staleDuration
                    }
                } catch {
                    continue
                }
            }
        }
        return false
    }
    
    public func clear() throws {
        for fileURL in readableCandidateURLs {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }
}
