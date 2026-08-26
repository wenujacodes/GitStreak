# Contributing to GitStreak 🔥

Thank you for your interest in contributing to GitStreak! We welcome contributions from developers of all skill levels. Whether you are fixing a bug, improving documentation, or proposing a new feature, your help is greatly appreciated.

---

## Code of Conduct

Please note that this project is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project, you agree to abide by its terms.

---

## How to Contribute

### 1. Reporting Bugs

Before creating a bug report, please check existing issues to avoid duplicates. When filing a bug report, include as much context as possible:
- **macOS version** (e.g., macOS 14.5 / 15.0)
- **Xcode version** (if building from source)
- **Detailed steps to reproduce** the issue
- **Expected vs. actual behavior**
- Screenshots or logs if applicable

### 2. Suggesting Features

We welcome ideas for new features, theme palettes, and WidgetKit enhancements!
- Open a new issue with a title clearly describing the feature.
- Explain the use case and why it would benefit GitStreak users.
- Provide mockup designs or code snippets if relevant.

### 3. Submitting Pull Requests

1. **Fork** the repository and create a feature branch off `main`:
   ```bash
   git checkout -b feature/my-cool-feature
   ```
2. **Make your changes** following our coding standards.
3. **Verify build and tests** pass locally:
   ```bash
   make generate
   make test
   make build
   ```
4. **Commit your changes** with a clear and concise commit message.
5. **Push** to your fork and submit a Pull Request targeting `main`.

---

## Local Development Setup

### Prerequisites

- **macOS 14.0+** (Sonoma or newer)
- **Xcode 15.0+** with command line tools installed
- **XcodeGen**: Used to generate the `.xcodeproj` file from `project.yml`.
  ```bash
  brew install xcodegen
  ```

### Build & Run Commands

We use `make` to automate common development workflows:

| Command | Description |
| :--- | :--- |
| `make generate` | Generates `GitStreak.xcodeproj` using XcodeGen. |
| `make build` | Builds the macOS app, framework, and WidgetKit extension. |
| `make test` | Executes the unit test suite (`GitStreakTests`). |
| `make register-widget` | Copies the app to `~/Applications` and registers the widget extension with `lsregister` and `pluginkit`. |
| `make run` | Registers the widget and launches the GitStreak app. |
| `make clean` | Removes build artifacts and the generated `.xcodeproj`. |

---

## Project Structure

- **`GitStreak/`**: Main macOS app target containing SwiftUI views, navigation, and settings UI.
- **`GitStreakKit/`**: Shared core framework containing model data, GitHub GraphQL API client, Keychain authentication manager, and theme providers.
- **`GitStreakWidget/`**: WidgetKit extension rendering small, medium, and large desktop widgets.
- **`GitStreakTests/`**: Unit test suite for core models, API client, and widget timeline logic.
- **`project.yml`**: XcodeGen specification defining targets, dependencies, build settings, and schemas.

---

## Coding Guidelines

- **Swift 6 Concurrency**: Maintain strict concurrency checks (`Sendable` conformance, `actor`/`@MainActor` annotations where appropriate).
- **SwiftUI**: Keep views clean and modular. Extract subviews or helper components when views become complex.
- **Zero Intermediate Servers**: All security tokens and private data must remain strictly on the client (Apple Keychain).
- **Code Style**: Follow standard Swift API Design Guidelines. Keep code formatted and clean.

---

## License & Contribution Ownership

By contributing to GitStreak (via Pull Requests, patches, or issues), you agree that:
1. Your contributions will be governed by the project's [Business Source License 1.1 (BSL 1.1)](LICENSE).
2. You grant Wenuja Liyanamana an irrevocable, worldwide, royalty-free license to use, modify, distribute, re-license, and include your contributions in GitStreak while preserving Wenuja Liyanamana's sole ownership.
