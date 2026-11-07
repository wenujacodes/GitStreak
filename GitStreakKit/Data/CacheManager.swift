import Foundation

/// The folder shared by the app and the widget: `~/Library/Application Support/com.gitstreak.shared/`.
///
/// Both targets are entitled to this exact path (`temporary-exception.files.home-relative-path`),
/// so the unsandboxed app and the sandboxed widget always resolve the same folder.
/// We don't use an App Group container: that needs a Team ID, which ad-hoc signed builds
/// don't have, and macOS 15 blocks the widget from reading it.
internal enum SharedContainer {
    static var url: URL {
        // Tests must never read or overwrite the user's real cache and preferences.
        if KeychainService.isRunningInTestEnvironment {
            return testDirectory
        }
        _ = migrateFromGroupContainer
        return sharedDirectory
    }

    private static var testDirectory: URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitStreakTests-shared", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        return dir
    }

    private static var sharedDirectory: URL {
        let dir = realHomeDirectory
            .appendingPathComponent("Library/Application Support/com.gitstreak.shared", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        return dir
    }

    /// The user's real home folder, even inside the widget sandbox (where NSHomeDirectory() points into the container).
    private static var realHomeDirectory: URL {
        if let pw = getpwuid(getuid()), let dir = pw.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: dir), isDirectory: true)
        }
        let homeDir = NSHomeDirectory()
        if homeDir.contains("/Library/Containers/") {
            let realHome = homeDir.components(separatedBy: "/Library/Containers/").first ?? homeDir
            return URL(fileURLWithPath: realHome, isDirectory: true)
        }
        return URL(fileURLWithPath: homeDir, isDirectory: true)
    }

    /// One-time copy of preferences and cache from the old App Group location (used up to v1.1.10),
    /// so existing users keep their settings. Runs only in the app, never in the widget.
    /// The old files are left in place.
    private static let migrateFromGroupContainer: Void = {
        guard Bundle.main.bundleURL.pathExtension != "appex",
              let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gitstreak") else {
            return
        }
        let oldDir = groupURL.appendingPathComponent("com.gitstreak.shared", isDirectory: true)
        let newDir = sharedDirectory
        let fm = FileManager.default

        for name in ["user_preferences.json", "contribution_cache.json"] {
            let oldFile = oldDir.appendingPathComponent(name)
            let newFile = newDir.appendingPathComponent(name)
            if fm.fileExists(atPath: oldFile.path), !fm.fileExists(atPath: newFile.path) {
                try? fm.copyItem(at: oldFile, to: newFile)
            }
        }
    }()
}

public final class CacheManager: Sendable {
    private static let fileName = "contribution_cache.json"
    private static let staleDuration: TimeInterval = 60

    private static var sharedFileURL: URL {
        return SharedContainer.url.appendingPathComponent(fileName)
    }

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
        try? FileManager.default.removeItem(at: Self.historyFileURL)
    }

    // MARK: - Streak history (older years, see StreakHistory)

    private static var historyFileURL: URL {
        SharedContainer.url.appendingPathComponent("streak_history.json")
    }

    public func saveHistory(_ history: StreakHistory) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(history).write(to: Self.historyFileURL, options: .atomic)
    }

    public func loadHistory() -> StreakHistory? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: Self.historyFileURL) else { return nil }
        return try? decoder.decode(StreakHistory.self, from: data)
    }
}
