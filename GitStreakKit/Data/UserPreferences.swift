import Foundation
import WidgetKit

public enum AppearanceMode: String, Codable, Sendable, CaseIterable {
    case system, light, dark
}

public struct PreferencesModel: Codable, Sendable {
    public var username: String?
    public var accessToken: String?
    public var selectedThemeID: String = "github"
    public var hasCompletedOnboarding: Bool = false
    public var preferredAppearance: AppearanceMode = .system
    public var lastRefreshDate: Date?

    public init() {}
}

public final class UserPreferences: @unchecked Sendable {
    public static let shared = UserPreferences()

    private static let fileName = "user_preferences.json"
    private var model = PreferencesModel()
    private let lock = NSLock()

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

    private init() {
        loadModel()
    }

    public func reloadFromDisk() {
        loadModel()
    }

    private func loadModel() {
        lock.lock()
        defer { lock.unlock() }

        let url = Self.sharedFileURL
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(PreferencesModel.self, from: data) {
            self.model = decoded
            UserDefaults.standard.set(decoded.hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }

    private func saveModel() {
        lock.lock()
        let url = Self.sharedFileURL
        if let data = try? JSONEncoder().encode(model) {
            try? data.write(to: url, options: .atomic)
        }
        UserDefaults.standard.set(model.hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        lock.unlock()

        NotificationCenter.default.post(name: .userPreferencesDidChange, object: nil)
        WidgetCenter.shared.reloadTimelines(ofKind: "GitStreakWidget")
    }

    public var username: String? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return model.username
        }
        set {
            lock.lock()
            model.username = newValue
            lock.unlock()
            saveModel()
        }
    }

    public var accessToken: String? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return model.accessToken
        }
        set {
            lock.lock()
            model.accessToken = newValue
            lock.unlock()
            saveModel()
        }
    }

    public var selectedThemeID: String {
        get {
            lock.lock()
            defer { lock.unlock() }
            return model.selectedThemeID
        }
        set {
            lock.lock()
            model.selectedThemeID = newValue
            lock.unlock()
            saveModel()
        }
    }

    public var hasCompletedOnboarding: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return model.hasCompletedOnboarding
        }
        set {
            lock.lock()
            model.hasCompletedOnboarding = newValue
            lock.unlock()
            saveModel()
        }
    }

    public var preferredAppearance: AppearanceMode {
        get {
            lock.lock()
            defer { lock.unlock() }
            return model.preferredAppearance
        }
        set {
            lock.lock()
            model.preferredAppearance = newValue
            lock.unlock()
            saveModel()
        }
    }

    public var lastRefreshDate: Date? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return model.lastRefreshDate
        }
        set {
            lock.lock()
            model.lastRefreshDate = newValue
            lock.unlock()
            saveModel()
        }
    }
}

extension Notification.Name {
    public static let userPreferencesDidChange = Notification.Name("UserPreferencesDidChangeNotification")
}
