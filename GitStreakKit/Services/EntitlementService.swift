import Foundation

public protocol EntitlementProviding: Sendable {
    var isPro: Bool { get }
    var canUseCustomThemes: Bool { get }
    var canUseAdvancedStats: Bool { get }
    var canUseAdvancedLayouts: Bool { get }
    var maxAccounts: Int { get }
}

public struct FreeEntitlements: EntitlementProviding, Sendable {
    public let isPro = false
    public let canUseCustomThemes = false
    public let canUseAdvancedStats = false
    public let canUseAdvancedLayouts = false
    public let maxAccounts = 1
    
    public init() {}
}

public struct ProEntitlements: EntitlementProviding, Sendable {
    public let isPro = true
    public let canUseCustomThemes = true
    public let canUseAdvancedStats = true
    public let canUseAdvancedLayouts = true
    public let maxAccounts = 5
    
    public init() {}
}

public final class EntitlementManager: @unchecked Sendable {
    public static let shared = EntitlementManager()
    
    public private(set) var current: any EntitlementProviding = ProEntitlements()
    
    private init() {}
    
    public func upgrade() {
        current = ProEntitlements()
    }
    
    public func downgrade() {
        current = FreeEntitlements()
    }
}
