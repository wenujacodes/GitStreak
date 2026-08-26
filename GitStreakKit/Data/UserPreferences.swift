import Foundation
import WidgetKit

public enum AppearanceMode: String, Codable, Sendable, CaseIterable {
    case system, light, dark
}

public struct PreferencesModel: Codable, Sendable {
    public var username: String?
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

    private static var groupDefaults: UserDefaults {
        UserDefaults(suiteName: "group.com.gitstreak") ?? .standard
    }

    private static var sharedFileURL: URL {
        return SharedContainer.url.appendingPathComponent(fileName)
    }

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
        } else if let themeID = Self.groupDefaults.string(forKey: "selectedThemeID"), !themeID.isEmpty {
            self.model.selectedThemeID = themeID
        }

        UserDefaults.standard.set(self.model.hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        Self.groupDefaults.set(self.model.selectedThemeID, forKey: "selectedThemeID")
    }

    private func saveModel() {
        lock.lock()
        let url = Self.sharedFileURL
        if let data = try? JSONEncoder().encode(model) {
            try? data.write(to: url, options: .atomic)
        }
        UserDefaults.standard.set(model.hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        Self.groupDefaults.set(model.selectedThemeID, forKey: "selectedThemeID")
        Self.groupDefaults.synchronize()
        lock.unlock()

        NotificationCenter.default.post(name: .userPreferencesDidChange, object: nil)
        WidgetCenter.shared.reloadAllTimelines()
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
            TokenStorage.loadToken()
        }
        set {
            if let newValue = newValue, !newValue.isEmpty {
                TokenStorage.saveToken(newValue)
            } else {
                TokenStorage.clearToken()
            }
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
