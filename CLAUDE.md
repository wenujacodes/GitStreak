# GitStreak — Project Guide

Native macOS app + WidgetKit extension that shows a user's GitHub contribution grid, streaks, PRs and issues on the desktop.

## Working rules
- **Discuss every change with the maintainer before making it.** Investigate and propose first; edit code only after approval.
- Tackle the issues below **one at a time**, carefully. Verify each fix before moving on.
- The app was built on macOS 27; it must also work on **macOS 14/15** (deployment target is 14.0). Test against older macOS behavior.

## Stack
- Swift 6.0 with strict concurrency, SwiftUI, WidgetKit, Security (Keychain), Sparkle 2.6
- GitHub GraphQL API v4; OAuth device flow (client ID in `OAuthService.swift`) or a personal access token
- XcodeGen (`project.yml` is the source of truth, so don't hand-edit `.xcodeproj`), Make, `create-dmg`
- Ad-hoc signed (`CODE_SIGN_IDENTITY="-"`), distributed via GitHub Releases + Sparkle appcast

## Layout
| Path | Purpose |
|---|---|
| `GitStreak/` | App target: Onboarding, Dashboard, Settings, ThemePicker, Sparkle updater. **Not sandboxed.** |
| `GitStreakWidget/` | Widget extension (6 widgets sharing `GitStreakTimelineProvider`). **Sandboxed.** |
| `GitStreakKit/` | Shared framework: `GitHub/` (API client, GraphQL, OAuth, models), `Services/` (ContributionService, StreakCalculator, TokenStorage, KeychainService), `Data/` (CacheManager, SharedContainer, UserPreferences), `DesignSystem/` |
| `GitStreakTests/` | XCTest unit tests (~40) |
| `scripts/` | `package_release.sh` (DMG + Sparkle zip), `update_appcast.py` |

## Commands
```bash
make generate   # xcodegen generate
make build      # Debug build into ./build
make test       # run unit tests
make run        # install to /Applications, register widget, launch
make check-widget
```
- If `xcode-select` still points at the Command Line Tools, prefix commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
- **Careful:** `TokenStorageTests` and `CacheManagerTests` use the real Keychain and shared folder, so running them **deletes the developer's real token and cache**. Until they are isolated, run tests with
  `-skip-testing:GitStreakTests/TokenStorageTests -skip-testing:GitStreakTests/CacheManagerTests`.

## Data flow
App fetches GitHub data → `CacheManager` writes `contribution_cache.json` into `SharedContainer.url` → widgets read the cache (and also try to fetch themselves using `TokenStorage.loadToken()`).
Token storage layers: Keychain → `UserDefaults(suiteName: "group.com.gitstreak")` → legacy file.

## Known issues to tackle (in order)
1. **Widgets not working on macOS 15** (reported by users and reproduced on the maintainer's Mac). Cause (confirmed): no App Group entitlement and no Team ID. The unsandboxed app wrote to `~/Library/Group Containers/group.com.gitstreak/`, which macOS 15 blocks for the sandboxed widget, and the widget's `UserDefaults(suiteName:)` is a separate sandboxed copy with no username or token. *In progress, branch `fix/widget-macos15`.* Plan (Option B, no paid Apple account):
   1. Shared data lives in `~/Library/Application Support/com.gitstreak.shared/` (allowed by both entitlements), with a one-time copy from the old location. **Done.**
   2. The app keeps running hidden (no Dock or menu bar icon) after its window closes, refreshes every 5 min, and launches at login (on by default). Settings gets a "Quit GitStreak completely" button.
   3. The widget stops calling GitHub and only reads the shared files.
2. **Token stored in plaintext** in App Group `UserDefaults` (`TokenStorage.swift`), duplicating the Keychain copy. Don't just delete it: with ad-hoc signing the Keychain item may become unreadable after a Sparkle update (see commit `f0e3302`). Discuss options first.
3. **Excessive API usage**: all 6 widgets fetch every 5 min (`TimelineProvider.swift`), each with 8 search queries; cache stale after 60 s (`CacheManager.swift`). README claims 15 min.
4. **Username interpolated into GraphQL search strings** (`GitHubGraphQL.swift`); should use variables.
5. **PAT link requests the `repo` scope** (`SettingsView.swift`); device flow only uses `read:user,user:email`.
6. Housekeeping:
   - Committed binary `UserPreferences.o` should be removed and added to `.gitignore`.
   - Version numbers disagree across `Makefile`, `package_release.sh` and `project.yml`.
   - Hard-coded year fallback in `ContributionService.swift`.
   - `EntitlementManager` always Pro.
   - Main app unsandboxed; ad-hoc signing.
   - No CI.
   - Little test coverage outside streak logic.
   - `TokenStorageTests` and `CacheManagerTests` touch real user data (see Commands); they should use isolated storage.

## Commits
- Never add Claude as a co-author (no `Co-Authored-By` line).
