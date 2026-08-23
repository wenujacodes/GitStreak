import Foundation

public final class CacheManager: Sendable {
    private static let fileName = "contribution_cache.json"
    private static let staleDuration: TimeInterval = 60

    private static let sharedFileURL: URL = {
        let home: String
        if let pw = getpwuid(getuid()) {
            home = String(cString: pw.pointee.pw_dir)
        } else {
            home = NSHomeDirectory()
        }
        let dir = URL(fileURLWithPath: home).appendingPathComponent("Library/Application Support/com.gitstreak.shared", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(fileName)
    }()

    public init() {}

    public func save(_ data: ContributionData) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodedData = try encoder.encode(data)
        try encodedData.write(to: Self.sharedFileURL, options: .atomic)
    }

    public func load() -> ContributionData? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let url = Self.sharedFileURL
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let decoded = try? decoder.decode(ContributionData.self, from: data) else {
            return nil
        }
        return decoded
    }

    public func isFresh() -> Bool {
        let url = Self.sharedFileURL
        guard FileManager.default.fileExists(atPath: url.path),
              let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let modificationDate = attributes[.modificationDate] as? Date else {
            return false
        }
        return Date().timeIntervalSince(modificationDate) < Self.staleDuration
    }

    public func clear() throws {
        let url = Self.sharedFileURL
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
