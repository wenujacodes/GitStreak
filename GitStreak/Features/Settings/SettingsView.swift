import SwiftUI
import GitStreakKit

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var username: String = UserPreferences.shared.username ?? ""
    @State private var showingClearConfirmation = false
    @State private var saveStatusMessage: String?

    @State private var isAuthenticatingOAuth = false
    @State private var deviceCodeResponse: DeviceCodeResponse? = nil

    private var appBgColor: Color {
        colorScheme == .dark ? Color(hex: "#0B0C0E") : Color(NSColor.windowBackgroundColor)
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                TabView {
                    generalTab
                        .tabItem {
                            Label("General", systemImage: "gearshape")
                        }

                    aboutTab
                        .tabItem {
                            Label("About", systemImage: "info.circle")
                        }
                }
                .frame(width: 480, height: 260)
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
        .background(appBgColor)
        .onReceive(NotificationCenter.default.publisher(for: .userPreferencesDidChange)) { _ in
            self.username = UserPreferences.shared.username ?? ""
        }
    }

    private var generalTab: some View {
        Form {
            Section {
                if let devCode = deviceCodeResponse, isAuthenticatingOAuth {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("ENTER THIS CODE ON GITHUB:")
                                .font(GSTypography.monoBadge)
                                .foregroundColor(.secondary)
                            Spacer()
                            CopyableUserCodeView(userCode: devCode.userCode, fontSize: 16, paddingVertical: 4, paddingHorizontal: 8, cornerRadius: 4)
                        }

                        HStack(spacing: 8) {
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
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Connected Account")
                                .font(.subheadline)
                                .fontWeight(.medium)

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

                        Spacer()

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
                    .padding(.vertical, 4)
                }

                if let msg = saveStatusMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(msg.contains("failed") ? .red : .green)
                }
            } header: {
                Text("GitHub Authentication")
            } footer: {
                Text("GitStreak authenticates securely with GitHub via 1-click Device Flow and stores your token in the local Keychain.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(.orange)

            VStack(spacing: 2) {
                Text("GitStreak")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Version 1.0.0 (Build 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("GitStreak keeps all your data strictly on your Mac. We never send your tokens or contributions to any third-party server.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)

            Text("© 2026 Wenuja Liyanamana")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: 12) {
                Button("Check for Updates...") {
                    SparkleUpdaterViewModel.shared.checkForUpdates()
                }
                .buttonStyle(ModernSecondaryButtonStyle())

                Spacer()

                Button("Reset & Clear All Data", role: .destructive) {
                    showingClearConfirmation = true
                }
                .buttonStyle(ModernSecondaryButtonStyle())
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
        .padding()
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

                try KeychainService.save(token: accessToken, forKey: "github_pat")
                UserPreferences.shared.username = userInfo.username
                _ = try await SharedDataStore.shared.refreshData(force: true)
                SharedDataStore.shared.notifyWidgetToRefresh()

                await MainActor.run {
                    self.username = userInfo.username
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
        saveStatusMessage = nil
    }

    private func clearData() {
        try? SharedDataStore.shared.clearAllData()
        username = ""
        saveStatusMessage = nil
    }
}
