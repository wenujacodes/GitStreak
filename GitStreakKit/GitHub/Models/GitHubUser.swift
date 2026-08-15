import Foundation

public struct GitHubUser: Codable, Sendable, Equatable {
    public let username: String
    public let displayName: String?
    public let avatarURL: URL?
    public let bio: String?
    
    public init(username: String, displayName: String?, avatarURL: URL?, bio: String?) {
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.bio = bio
    }
}
