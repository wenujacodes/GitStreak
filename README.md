<div align="center">

# GitStreak 🔥

### **Make your coding habit visible on your macOS desktop.**

A native macOS application & WidgetKit engine bringing your GitHub contribution matrix, active streaks, pull requests, and open issues directly to your desktop wallpaper.

[![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B%20Sonoma-black?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/wenujacodes/GitStreak)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![Sparkle Auto-Update](https://img.shields.io/badge/Sparkle-Auto--Updates-blue?style=for-the-badge&logo=github&logoColor=white)](https://github.com/wenujacodes/GitStreak/releases)
[![GitHub Stars](https://img.shields.io/github/stars/wenujacodes/GitStreak?style=for-the-badge&color=gold&logo=github)](https://github.com/wenujacodes/GitStreak/stargazers)
[![License: BSL 1.1](https://img.shields.io/badge/License-BSL%201.1-green?style=for-the-badge)](LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/wenujacodes/GitStreak?style=for-the-badge&color=orange)](https://github.com/wenujacodes/GitStreak/releases/latest)

<br/>

[**🚀 Download GitStreak for macOS (.dmg)**](https://github.com/wenujacodes/GitStreak/releases/latest/download/GitStreak-v1.1.1.dmg) &nbsp;•&nbsp; [**✨ Release Notes**](https://github.com/wenujacodes/GitStreak/releases) &nbsp;•&nbsp; [**🔥 Features**](#-key-features) &nbsp;•&nbsp; [**🗺️ Roadmap**](#-development-roadmap)

> ⭐ **If you find GitStreak helpful, please star the repository to support development and help others discover it!** ⭐

</div>

---

## 📸 Visual Showcase

### Application
| Dark Mode Aesthetic | Light Mode Aesthetic |
| :---: | :---: |
| ![GitStreak App Dark Mode](images/app-dark-mode.png) | ![GitStreak App Light Mode](images/app-light-mode.png) |

<br/>

### Widgets
| Dark Mode Widgets | Light Mode Widgets |
| :---: | :---: |
| ![GitStreak Widgets Dark Mode](images/dark-mode.png) | ![GitStreak Widgets Light Mode](images/light-mode.png) |

---

## 🔥 Key Features

### 🖥️ Native Desktop Wallpaper Widgets
* **Small Matrix Widget**: Terminal header (`~/username`), bold streak counter (`11 day streak`), and 11-week activity heatmap.
* **Medium Widgets**: Pure 17-column contribution grid or detailed developer identity card.
* **Pull Requests Widget**: Real-time tracker for PRs created, assigned, mentioned, or review requested.
* **Issues Widget**: Live metrics for open and assigned GitHub issues with custom filters.
* **Large Widget**: Full 53-week contribution matrix with weekday indicators (`M`, `W`, `F`) and complete stats row.

### 🎛️ Customization & Filtering
* **Widget Metrics Filter**: Pick between PR categories (*Created*, *Assigned*, *Mentioned*, *Review Requests*) and Issue categories (*All Open*, *Assigned to Me*).
* **6 Theme Color Palettes**: *GitHub Classic*, *Ocean*, *Monochrome*, *Sunset*, *Forest*, and *Nord*.

### ⚡ Performance & Security
* **Single GraphQL Call**: Fetches contributions, PRs, and Issues in a single GraphQL query at zero extra rate-limit cost.
* **Smart Local Cache**: Multi-year switching with instant cache-first rendering and 15-minute background refresh.
* **100% Serverless & Private**: Credentials stored in macOS Keychain with triple-layer self-healing persistence across app updates.
* **Sparkle 2 Auto-Updater**: Direct in-app update checks with 1-click installer authorization.

---

## 🗺️ Development Roadmap

> [!NOTE]
> GitStreak is under active, rapid development! Below is the feature roadmap for upcoming releases:

| Feature | Scope | Status |
| :--- | :--- | :---: |
| **Dynamic & Custom Theme Creator** | Build, save, and export your own custom color palettes | `Planned` |
| **Dedicated Current Streak Widget** | Ultra-compact wallpaper widget highlighting active streak & daily goal | `Planned` |
| **Multiple GitHub Profiles Support** | Seamlessly switch between personal, work, and client accounts | `Planned` |
| **Detailed Developer Analytics** | Developer metrics: language breakdown, weekly averages, and PR velocity | `Planned` |
| **Custom Widget Backgrounds** | Glassmorphism translucency, opacity sliders, and custom styles | `Planned` |
| **Smart Commit Reminders** | Native macOS notifications alerting before midnight if streak is at risk | `Planned` |
| **Dynamic Adaptive Widgets** | Visual alerts & state changes when today has zero commits | `Planned` |
| **Expanded Theme Library** | Curated color palettes inspired by popular IDE themes | `Planned` |

---

## 📥 Installation

### Option 1: Direct Download (Recommended)

1. Download the latest release disk image: [**GitStreak-v1.1.1.dmg**](https://github.com/wenujacodes/GitStreak/releases/latest/download/GitStreak-v1.1.1.dmg)
2. Open `GitStreak-v1.1.1.dmg` and drag **GitStreak** into your `/Applications` folder.
3. Launch **GitStreak**, enter your GitHub Personal Access Token, and configure your desktop widgets!

### Option 2: Build from Source

```bash
# 1. Clone the repository
git clone https://github.com/wenujacodes/GitStreak.git
cd GitStreak

# 2. Install XcodeGen (if not already installed)
brew install xcodegen

# 3. Generate Xcode project & build
make generate
make build

# 4. Install & Launch GitStreak
make run
```

---

## 🛠️ Desktop Wallpaper Widget Setup

1. Right-click anywhere on your macOS **Desktop Wallpaper**.
2. Click **Edit Widgets...**
3. Search for **GitStreak** in the widget gallery.
4. Drag your preferred widget size (**Small**, **Medium**, **Large**, **PRs**, or **Issues**) onto your desktop!

---

## 💻 Tech Stack

* **Platform Target**: macOS 14.0+ (Sonoma / Sequoia)
* **Language**: Swift 6.0 (Strict Concurrency)
* **Frameworks**: SwiftUI, WidgetKit, Security (Keychain), Sparkle 2.6
* **API**: GitHub GraphQL API v4
* **Tooling**: XcodeGen, XCTest, Make, `create-dmg`

---

## 📄 License

Source-Available under the [Business Source License 1.1 (BSL 1.1)](LICENSE) © 2026 Wenuja Liyanamana. Free for non-commercial personal use and open-source contributions.
