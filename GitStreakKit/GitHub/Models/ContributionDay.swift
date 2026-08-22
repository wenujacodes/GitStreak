import Foundation

public enum ContributionLevel: String, Codable, Sendable, Equatable {
    case none = "NONE"
    case firstQuartile = "FIRST_QUARTILE"
    case secondQuartile = "SECOND_QUARTILE"
    case thirdQuartile = "THIRD_QUARTILE"
    case fourthQuartile = "FOURTH_QUARTILE"

    public var intensity: Int {
        switch self {
        case .none: return 0
        case .firstQuartile: return 1
        case .secondQuartile: return 2
        case .thirdQuartile: return 3
        case .fourthQuartile: return 4
        }
    }
}

public struct ContributionDay: Codable, Sendable, Equatable, Identifiable {
    public let date: String
    public let contributionCount: Int
    public let level: ContributionLevel
    public let weekday: Int

    public var id: String { date }

    enum CodingKeys: String, CodingKey {
        case date
        case contributionCount
        case level = "contributionLevel"
        case weekday
    }

    public init(date: String, contributionCount: Int, level: ContributionLevel, weekday: Int) {
        self.date = date
        self.contributionCount = contributionCount
        self.level = level
        self.weekday = weekday
    }
}
