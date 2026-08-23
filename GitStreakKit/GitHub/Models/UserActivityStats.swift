import Foundation

public struct UserActivityStats: Codable, Sendable, Equatable {
    public let commits: Int
    public let issues: Int
    public let pullRequests: Int
    public let reviews: Int
    public let repositories: Int

    public init(
        commits: Int = 0,
        issues: Int = 0,
        pullRequests: Int = 0,
        reviews: Int = 0,
        repositories: Int = 0
    ) {
        self.commits = max(0, commits)
        self.issues = max(0, issues)
        self.pullRequests = max(0, pullRequests)
        self.reviews = max(0, reviews)
        self.repositories = max(0, repositories)
    }

    /// Maximum stat value across all activity categories
    public var maxStatValue: Int {
        max(commits, issues, pullRequests, reviews, repositories)
    }

    /// Dynamic ceiling based on maximum stat value to provide dynamic scaling
    public var dynamicCeiling: Int {
        Self.niceCeiling(for: maxStatValue)
    }

    /// Computes a nice rounded ceiling for dynamic scaling
    public static func niceCeiling(for maxValue: Int) -> Int {
        guard maxValue > 0 else { return 10 }
        let raw = Double(maxValue)
        let exponent = floor(log10(raw))
        let fraction = raw / pow(10, exponent)
        let niceFraction: Double
        if fraction <= 1.0 {
            niceFraction = 1.0
        } else if fraction <= 2.0 {
            niceFraction = 2.0
        } else if fraction <= 2.5 {
            niceFraction = 2.5
        } else if fraction <= 5.0 {
            niceFraction = 5.0
        } else {
            niceFraction = 10.0
        }
        return max(5, Int(niceFraction * pow(10, exponent)))
    }

    /// Dynamically calculates a normalized radius fraction (0.0 ... 1.0) scaled to the user's data
    public func dynamicFraction(for value: Int) -> Double {
        guard value > 0 else { return 0.0 }
        let ceiling = Double(max(dynamicCeiling, 1))
        let logVal = log10(Double(value) + 1.0)
        let logCeiling = log10(ceiling + 1.0)
        guard logCeiling > 0 else { return 0.0 }
        return min(max(logVal / logCeiling, 0.0), 1.0)
    }

    /// Generates dynamic level markers for the radar chart grid
    public var dynamicLevels: [(scale: Double, label: String)] {
        let ceiling = dynamicCeiling
        let steps = [0.2, 0.4, 0.6, 0.8, 1.0]
        let logCeiling = log10(Double(ceiling) + 1.0)

        return steps.map { step in
            let rawVal = pow(10.0, step * logCeiling) - 1.0
            let roundedVal = Int(rawVal.rounded())
            let label: String
            if roundedVal >= 1000 {
                if roundedVal % 1000 == 0 {
                    label = "\(roundedVal / 1000)K"
                } else {
                    label = String(format: "%.1fK", Double(roundedVal) / 1000.0)
                }
            } else {
                label = "\(max(1, roundedVal))"
            }
            return (scale: step, label: label)
        }
    }

    /// Calculates a normalized radius fraction (0.0 ... 1.0) on a 5-level logarithmic scale:
    /// Level 1: 1 (0.2)
    /// Level 2: 10 (0.4)
    /// Level 3: 100 (0.6)
    /// Level 4: 1,000 (0.8)
    /// Level 5: 10,000 (1.0)
    public static func scaleFraction(for value: Int) -> Double {
        guard value > 0 else { return 0.0 }
        let logVal = log10(Double(value))
        let clamped = min(max(logVal, 0.0), 4.0)
        return (clamped + 1.0) / 5.0
    }

    public var commitFraction: Double { dynamicFraction(for: commits) }
    public var issueFraction: Double { dynamicFraction(for: issues) }
    public var pullRequestFraction: Double { dynamicFraction(for: pullRequests) }
    public var reviewFraction: Double { dynamicFraction(for: reviews) }
    public var repositoryFraction: Double { dynamicFraction(for: repositories) }

    public static let sample = UserActivityStats(
        commits: 850,
        issues: 8,
        pullRequests: 95,
        reviews: 24,
        repositories: 14
    )
}
