import Foundation
import WidgetKit

public final class SharedDataStore: @unchecked Sendable {
    public static let shared = SharedDataStore()
    
    private let contributionService: ContributionService
    private let cacheManager: CacheManager
    public let preferences: UserPreferences
    
    private init() {
        self.cacheManager = CacheManager()
        self.contributionService = ContributionService(cacheManager: self.cacheManager)
        self.preferences = UserPreferences.shared
    }
    
    public func refreshData(force: Bool = true) async throws -> ContributionData {
        guard let username = preferences.username, !username.isEmpty else {
            throw NSError(domain: "SharedDataStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Username is not set"])
        }
        
        let token = KeychainService.load(forKey: "github_pat") ?? ""
        
        let data: ContributionData
        if force {
            data = try await contributionService.fetchContributions(username: username, token: token)
        } else {
            data = try await contributionService.refreshIfNeeded(username: username, token: token)
        }
        preferences.lastRefreshDate = Date()
        
        notifyWidgetToRefresh()
        return data
    }
    
    public func getCachedData() -> ContributionData? {
        return contributionService.getCachedData()
    }
    
    public func notifyWidgetToRefresh() {
        WidgetCenter.shared.reloadTimelines(ofKind: "GitStreakWidget")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    public func clearAllData() throws {
        try cacheManager.clear()
        try KeychainService.delete(forKey: "github_pat")
        
        preferences.username = nil
        preferences.selectedThemeID = "github"
        preferences.hasCompletedOnboarding = false
        preferences.preferredAppearance = .system
        preferences.lastRefreshDate = nil
        
        notifyWidgetToRefresh()
    }
}
