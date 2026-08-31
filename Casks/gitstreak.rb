cask "gitstreak" do
  version "1.1.9"
  sha256 "f1ae4a9023338088f9f7532f929b79841e65dfc39928723a785f20b25f555888"

  url "https://github.com/wenujacodes/GitStreak/releases/download/v#{version}/GitStreak-v#{version}.dmg"
  name "GitStreak"
  desc "Native macOS widget showing GitHub contribution activity on the desktop"
  homepage "https://github.com/wenujacodes/GitStreak"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "GitStreak.app"

  caveats <<~EOS
    GitStreak is not notarized. On first launch, macOS may block it:
    right-click GitStreak.app in /Applications and choose Open,
    or allow it under System Settings → Privacy & Security.
  EOS

  zap trash: [
    "~/Library/Application Support/GitStreak",
    "~/Library/Preferences/com.gitstreak.GitStreak.plist",
  ]
end
