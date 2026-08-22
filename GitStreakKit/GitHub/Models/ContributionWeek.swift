import Foundation

public struct ContributionWeek: Codable, Sendable, Equatable {
    public let contributionDays: [ContributionDay]

    public init(contributionDays: [ContributionDay]) {
        self.contributionDays = contributionDays
    }
}
