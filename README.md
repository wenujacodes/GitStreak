# GitStreak 🔥

> **Make your coding habit visible on your desktop with a sleek, minimalist dev aesthetic.**

GitStreak is a native macOS application and WidgetKit widget designed to motivate developers by displaying real-time GitHub contribution streaks and activity timelines directly on your desktop.

---

## Features

- **Desktop Widgets (WidgetKit)**:
  - **Small (`systemSmall`)**: Monospaced terminal header (`~/username`), bold streak counter (`11 day streak`), and 11-week activity heatmap.
  - **Medium (`systemMedium`)**: Identity banner with avatar, live streak metric, and contribution grid.
  - **Large (`systemLarge`)**: Full activity matrix with weekday indicators (`M`, `W`, `F`) and complete 3-metric developer card row.
- **Raycast-Inspired Dark Dev Aesthetic**:
  - Unified `#121313` dark mode and seamless light mode support.
  - Full 53-week interactive contribution matrix with live hover tooltips.
- **GitHub Token Requirements**:
  - Uses **Personal Access Token (Classic)** (`ghp_...`).
  - **Public Contributions Only**: Zero scopes required.
  - **Private & Public Contributions**: Select the **`repo`** (Full control of private repositories) and **`read:user`** scopes.
- **Privacy & Security First**:
  - Your PAT is stored securely in the local **Apple Keychain**.
  - All contribution data is cached locally on your Mac. No intermediate backend servers.
- **Color Themes**:
  - Classic GitHub Green
  - Monochrome (Minimal Grayscale)
  - Ocean (Cool Blues)
  - Sunset (Warm Amber/Oranges)
  - Forest (Deep Greens)
  - Nord (Arctic North Palette)

---

## Tech Stack

- **Platform**: macOS 14.0+ (Sonoma, Sequoia)
- **Language**: Swift 6.0 (Strict Concurrency)
- **Frameworks**: SwiftUI, WidgetKit, Security (Keychain)
- **API**: GitHub GraphQL API v4
- **Build Tooling**: XcodeGen, XCTest, Make

---

## Getting Started

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

3. **Run the App & Register the Desktop Widget**:
   ```bash
   make register-widget
   make run
   ```

---

## License

MIT License © 2026 Wenuja Liyanamana
