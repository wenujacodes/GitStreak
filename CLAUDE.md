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
- All tests are safe to run on a developer Mac: during tests the Keychain is in-memory, token defaults use a separate `com.gitstreak.tests` suite, and `SharedContainer.url` points to a temporary folder.

## Data flow
The app fetches GitHub data (in the background every 5 min, `BackgroundController`) → `CacheManager` writes `contribution_cache.json` into `SharedContainer.url` (`~/Library/Application Support/com.gitstreak.shared/`) → the app reloads widget timelines → widgets only read the cache. **The widget never calls GitHub or touches the token.**

## Token storage
- The token lives in the **login Keychain** only (`KeychainService`, service `com.gitstreak.github`). The data protection Keychain is not an option: without a Team ID it fails with -34018.
- Without a Team ID, macOS ties Keychain access to each build, so **after every update the user sees one "GitStreak wants to access key…" dialog**. A self-signed certificate does not avoid this (tested). This is expected.
- If the user clicks Deny, `TokenStorage.keychainAccessDenied` stops further prompts for the session and the dashboard asks them to save the token again (which replaces the blocked item).
- Plain-text copies from ≤1.1.10 (`group.com.gitstreak` defaults, `.token_auth` file) are migrated into the Keychain and deleted only after the Keychain save succeeds.

## Known issues to tackle (in order)
Release target: fix everything below, then ship **1.1.11** (not released yet).

1. ~~Widgets not working on macOS 15~~ **Done (PR #26).** Cause: no App Group entitlement and no Team ID, so the app and the sandboxed widget used different folders. Fixed with the shared Application Support folder, hidden background mode + launch at login, and a widget that only reads the cache.
2. ~~Token stored in plaintext~~ **Done (branch `fix/token-keychain`).** Keychain saves had been failing silently (-34018). See "Token storage". Reported by a user on GitHub; reply once released.
3. ~~Excessive API usage~~ **Mostly done** with #1: one fetch by the app every 5 min. Remaining: README still says 15 min.
4. ~~Username interpolated into GraphQL search strings~~ **Done:** low risk (the username comes from GitHub itself), so instead of a rewrite, `GitHubGraphQL.isValidUsername` rejects anything but letters, numbers and hyphens before a request is built.
5. ~~PAT link requests the `repo` scope~~ **Decided: keep classic `repo,read:user`** (`OAuthService.createTokenURL`, used by Settings and Onboarding). A fine-grained read-only token was tested and misses organization work (68 vs 120 PRs, 835 vs 1365 contributions); GitHub has no read-only token covering private org repos. The UI explains why `repo` is needed and suggests "No expiration". The OAuth device flow in `OAuthService` is currently unused.
6. Housekeeping:
   - Committed binary `UserPreferences.o` should be removed and added to `.gitignore`.
   - Version numbers disagree across `Makefile`, `package_release.sh` and `project.yml`.
   - Hard-coded year fallback in `ContributionService.swift`.
   - `EntitlementManager` always Pro.
   - Main app unsandboxed; ad-hoc signing.
   - No CI.
   - Little test coverage outside streak logic.
   - README: document background mode, launch at login and the one-time Keychain dialog after updates.
7. Ideas (optional): widget hint when data is stale (e.g. app not running or token denied).

## Commits
- Never add Claude as a co-author (no `Co-Authored-By` line).

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.
