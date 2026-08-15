import Foundation

public enum AppearanceMode: String, Codable, Sendable, CaseIterable {
    case system, light, dark
}

public final class UserPreferences: @unchecked Sendable {
    public static let shared = UserPreferences()
    
    private static let groupID = "group.com.gitstreak.shared"
    private let defaults: UserDefaults
    
    private init() {
        if let sharedDefaults = UserDefaults(suiteName: Self.groupID) {
            self.defaults = sharedDefaults
        } else {
            self.defaults = UserDefaults.standard
        }
    }
    
    public var username: String? {
        get { defaults.string(forKey: "username") }
        set { defaults.set(newValue, forKey: "username") }
    }
    
    public var selectedThemeID: String {
        get { defaults.string(forKey: "selectedThemeID") ?? "github" }
        set { defaults.set(newValue, forKey: "selectedThemeID") }
    }
    
    public var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: "hasCompletedOnboarding") }
        set { defaults.set(newValue, forKey: "hasCompletedOnboarding") }
    }
    
    public var preferredAppearance: AppearanceMode {
        get {
            if let rawValue = defaults.string(forKey: "preferredAppearance"),
               let mode = AppearanceMode(rawValue: rawValue) {
                return mode
            }
            return .system
        }
        set { defaults.set(newValue.rawValue, forKey: "preferredAppearance") }
    }
    
    public var lastRefreshDate: Date? {
        get { defaults.object(forKey: "lastRefreshDate") as? Date }
        set { defaults.set(newValue, forKey: "lastRefreshDate") }
    }
}
