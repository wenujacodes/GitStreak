import SwiftUI
import GitStreakKit

enum SettingsTab: Hashable {
    case general
    case about
}

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var selectedTab: SettingsTab = .general
    @State private var username: String = UserPreferences.shared.username ?? ""
    @State private var showingClearConfirmation = false
    @State private var saveStatusMessage: String?

    @State private var isAuthenticatingOAuth = false
    @State private var deviceCodeResponse: DeviceCodeResponse? = nil
    @State private var avatarURL: URL? = SharedDataStore.shared.getCachedData()?.user.avatarURL

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                TabView(selection: $selectedTab) {
                    generalTab
                        .tag(SettingsTab.general)
                        .tabItem {
                            Label("General", systemImage: "gearshape")
                        }

                    aboutTab
                        .tag(SettingsTab.about)
                        .tabItem {
                            Label("About", systemImage: "info.circle")
                        }
                }
                .frame(width: 520, height: 280)
                .padding()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)

                    Text("Setup Required")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("Please complete the onboarding setup before accessing Settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 380, height: 180)
                .padding()
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: .userPreferencesDidChange)) { _ in
            self.username = UserPreferences.shared.username ?? ""
            self.avatarURL = SharedDataStore.shared.getCachedData()?.user.avatarURL
        }
    }

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("GitHub Authentication")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("GitStreak authenticates securely with GitHub via 1-click Device Flow and stores your token in the local Keychain.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let devCode = deviceCodeResponse, isAuthenticatingOAuth {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("ENTER THIS CODE ON GITHUB:")
                            .font(GSTypography.monoBadge)
                            .foregroundColor(.secondary)
                            .tracking(1)
                        Spacer()
                        CopyableUserCodeView(userCode: devCode.userCode, fontSize: 16, paddingVertical: 4, paddingHorizontal: 8, cornerRadius: 4)
                    }

                    HStack(spacing: 10) {
                        Button("Open GitHub") {
                            OAuthService.openDeviceLogin(userCode: devCode.userCode, verificationUri: devCode.verificationUri)
                        }
                        .buttonStyle(ModernPrimaryButtonStyle())

                        Button("Cancel") {
                            cancelOAuth()
                        }
                        .buttonStyle(ModernSecondaryButtonStyle())

                        Spacer()

                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            } else {
                HStack(spacing: 16) {
                    HStack(spacing: 12) {
                        if !username.isEmpty {
                            AvatarView(avatarURL: avatarURL, size: 38)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                )
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Connected Account")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            if !username.isEmpty {
                                Text("@\(username)")
                                    .font(GSTypography.monoCaption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("No account connected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        if !username.isEmpty {
                            Button(action: signOut) {
                                HStack(spacing: 4) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                }
                            }
                            .buttonStyle(ModernSecondaryButtonStyle())
                        }

                        Button(action: startOAuthFlow) {
                            HStack(spacing: 6) {
                                Image(systemName: "person.badge.key.fill")
                                Text(username.isEmpty ? "Sign in with GitHub" : "Switch Account")
                            }
                        }
                        .buttonStyle(ModernPrimaryButtonStyle())
                    }
                }
                .padding(.vertical, 4)
            }

            if let msg = saveStatusMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundColor(msg.contains("failed") ? .red : .green)
            }

            Spacer()
        }
        .padding(16)
    }

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundColor(.orange)

            VStack(spacing: 2) {
                Text("GitStreak")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("GitStreak keeps all your data strictly on your Mac. We never send your tokens or contributions to any third-party server.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)

            Button(action: {
                if let url = URL(string: "https://github.com/wenujacodes/GitStreak") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 11, weight: .bold))
                    Text("github.com/wenujacodes/GitStreak")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .buttonStyle(ModernSecondaryButtonStyle())

            Text("© 2026 Wenuja Liyanamana (MIT License)")
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: 12) {
                Button("Check for Updates...") {
                    SparkleUpdaterViewModel.shared.checkForUpdates()
                }
                .buttonStyle(ModernSecondaryButtonStyle())

                Spacer()

                Button("Reset & Clear All Data") {
                    showingClearConfirmation = true
                }
                .buttonStyle(DestructiveButtonStyle())
            }
            .confirmationDialog("Are you sure you want to clear all data?", isPresented: $showingClearConfirmation) {
                Button("Clear Everything", role: .destructive) {
                    clearData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove your cached contribution history, stored GitHub credentials, and reset the app.")
            }
        }
        .padding(16)
    }

    private func startOAuthFlow() {
        saveStatusMessage = nil
        Task {
            do {
                let codeResponse = try await OAuthService.shared.requestDeviceCode()

                await MainActor.run {
                    self.deviceCodeResponse = codeResponse
                    self.isAuthenticatingOAuth = true
                }

                OAuthService.openDeviceLogin(userCode: codeResponse.userCode, verificationUri: codeResponse.verificationUri)

                let accessToken = try await OAuthService.shared.pollForToken(deviceCode: codeResponse.deviceCode, interval: codeResponse.interval)
                let userInfo = try await OAuthService.shared.fetchAuthenticatedUser(token: accessToken)

                TokenStorage.saveToken(accessToken)
                UserPreferences.shared.username = userInfo.username
                let data = try await SharedDataStore.shared.refreshData(force: true)
                SharedDataStore.shared.notifyWidgetToRefresh()

                await MainActor.run {
                    self.username = userInfo.username
                    self.avatarURL = data.user.avatarURL
                    self.isAuthenticatingOAuth = false
                    self.saveStatusMessage = "Successfully connected as @\(userInfo.username)!"
                }
            } catch {
                await MainActor.run {
                    self.isAuthenticatingOAuth = false
                    self.saveStatusMessage = "OAuth failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func cancelOAuth() {
        isAuthenticatingOAuth = false
        deviceCodeResponse = nil
    }

    private func signOut() {
        try? SharedDataStore.shared.clearAllData()
        username = ""
        avatarURL = nil
        saveStatusMessage = nil
    }

    private func clearData() {
        try? SharedDataStore.shared.clearAllData()
        username = ""
        avatarURL = nil
        saveStatusMessage = nil
    }
}
