import SwiftUI

public struct AvatarView: View {
    public let url: URL?
    public let size: CGFloat

    public init(url: URL?, size: CGFloat = 32) {
        self.url = url
        self.size = size
    }

    public init(avatarURL: URL?, size: CGFloat = 32) {
        self.url = avatarURL
        self.size = size
    }

    public var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: size, height: size)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            case .failure:
                fallbackImage
            @unknown default:
                fallbackImage
            }
        }
    }

    private var fallbackImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .frame(width: size, height: size)
            .foregroundColor(.secondary)
    }
}
