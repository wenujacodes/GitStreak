# GitStreak 🔥

> **Make your coding habit visible without turning your desktop into a GitHub dashboard.**

GitStreak is a native macOS application and WidgetKit widget designed to motivate developers to keep coding by making their GitHub contribution activity visible directly on their desktop.

---

## ✨ Features

- **Desktop Widgets (WidgetKit)**:
  - **Small (`systemSmall`)**: Compact 6-week mini grid with flame streak counter.
  - **Medium (`systemMedium`)**: Identity view with GitHub avatar, username, total contributions, 10-week graph, and streak badge.
  - **Large (`systemLarge`)**: Full 13-week (~90 days) contribution matrix with weekday indicators (`M`, `W`, `F`) and complete 3-metric statistics row.
- **Privacy & Security First**:
  - Requires only **public permissions** (zero scopes needed on your GitHub Personal Access Token).
  - Your PAT is stored securely in the **Apple Keychain**.
  - All contribution data is cached locally on your Mac.
- **6 Color Palettes**:
  - Classic GitHub Green
  - Monochrome (Minimal Grayscale)
  - Ocean (Cool Blues)
  - Sunset (Warm Amber/Oranges)
  - Forest (Deep Greens)
  - Nord (Arctic North Palette)
- **Deterministic Streak Engine**: Accurately computes current streaks, longest streaks, and gap tolerance in UTC.

---

## 🛠 Tech Stack

- **Platform**: macOS 14.0+ (Sonoma, Sequoia)
- **Language**: Swift 6.0 (Strict Concurrency)
- **Frameworks**: SwiftUI, WidgetKit, Security (Keychain)
- **API**: GitHub GraphQL API v4
- **Build Tooling**: XcodeGen, XCTest, Make

---

## 🚀 Getting Started

### Prerequisites

- macOS 14.0 or later
- Xcode 15.0 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Building & Running

1. **Clone the repository**:
   ```bash
   git clone https://github.com/wenujacodes/GitStreak.git
   cd GitStreak
   ```

2. **Generate the Xcode project & build**:
   ```bash
   make generate
   make build
   ```

3. **Run all 26 Unit Tests**:
   ```bash
   make test
   ```

4. **Launch the App**:
   ```bash
   open GitStreak.xcodeproj
   ```
   Press `Cmd + R` in Xcode to run the app and register the desktop widget.

---

## 🧩 Adding the Widget to Desktop

1. Right-click on your desktop wallpaper.
2. Select **Edit Widgets...**
3. Search for **GitStreak** and select your preferred size.
4. Drag it directly onto your desktop.

---

## 📄 License

MIT License. See `LICENSE` for details.
