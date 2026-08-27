import Foundation

public enum PRWidgetFilter: String, Codable, CaseIterable, Sendable {
    case allCreated = "all_created"
    case openCreated = "open_created"
    case created = "created"
    case assigned = "assigned"
    case mentioned = "mentioned"
    case reviewRequested = "review_requested"

    public var displayName: String {
        switch self {
        case .allCreated, .created: return "All Authored by You"
        case .openCreated: return "Currently Open Authored by You"
        case .assigned: return "Assigned to You"
        case .mentioned: return "Involves You"
        case .reviewRequested: return "Review Requested"
        }
    }

    public var shortLabel: String {
        switch self {
        case .allCreated, .created: return "All PRs"
        case .openCreated: return "Open PRs"
        case .assigned: return "Assigned PRs"
        case .mentioned: return "Involved PRs"
        case .reviewRequested: return "Review Requests"
        }
    }
}

public enum IssueWidgetFilter: String, Codable, CaseIterable, Sendable {
    case allCreated = "all_created"
    case openCreated = "open_created"
    case assigned = "assigned"

    public var displayName: String {
        switch self {
        case .allCreated: return "All Opened by You"
        case .openCreated: return "Currently Open by You"
        case .assigned: return "Assigned to You"
        }
    }

    public var shortLabel: String {
        switch self {
        case .allCreated: return "All Issues"
        case .openCreated: return "Open Issues"
        case .assigned: return "Assigned Issues"
        }
    }
}
