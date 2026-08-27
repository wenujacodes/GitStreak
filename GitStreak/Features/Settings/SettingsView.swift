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
    @State private var patInput: String = TokenStorage.loadToken() ?? ""
    @State private var showingClearConfirmation = false
    @State private var saveStatusMessage: String?
    @State private var isSavingPAT = false
    @State private var avatarURL: URL? = SharedDataStore.shared.getCachedData()?.user.avatarURL
    @State private var prWidgetFilter: PRWidgetFilter = UserPreferences.shared.prWidgetFilter
    @State private var issueWidgetFilter: IssueWidgetFilter = UserPreferences.shared.issueWidgetFilter
    @ObservedObject private var updaterViewModel = SparkleUpdaterViewModel.shared

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
                .frame(width: 540, height: 420)
                .padding()
            } else {
                Color.clear
                    .frame(width: 0, height: 0)
                    .onAppear {
                        NSApp.keyWindow?.close()
                    }
            }
        }
        .background(
            WindowAccessor { window in
                window.isOpaque = true
                window.backgroundColor = colorScheme == .dark ? NSColor.windowBackgroundColor : .white
                window.titlebarAppearsTransparent = true
            }
        )
        .background((colorScheme == .dark ? Color(NSColor.windowBackgroundColor) : Color.white).ignoresSafeArea())
        .onAppear {
            self.username = UserPreferences.shared.username ?? ""
            self.avatarURL = SharedDataStore.shared.getCachedData()?.user.avatarURL
            self.patInput = TokenStorage.loadToken() ?? ""
            self.prWidgetFilter = UserPreferences.shared.prWidgetFilter
            self.issueWidgetFilter = UserPreferences.shared.issueWidgetFilter
        }
        .onReceive(NotificationCenter.default.publisher(for: .userPreferencesDidChange)) { _ in
            self.username = UserPreferences.shared.username ?? ""
            self.avatarURL = SharedDataStore.shared.getCachedData()?.user.avatarURL
            self.patInput = TokenStorage.loadToken() ?? ""
            self.prWidgetFilter = UserPreferences.shared.prWidgetFilter
            self.issueWidgetFilter = UserPreferences.shared.issueWidgetFilter
        }
    }

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Connected Account Section
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

                if !username.isEmpty {
                    Button(action: signOut) {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                    }
                    .buttonStyle(ModernSecondaryButtonStyle())
                }
            }

            Divider()

            // Personal Access Token Section
            VStack(alignment: .leading, spacing: 8) {
                Text("GitHub Personal Access Token")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Enter your Personal Access Token (ghp_... or github_pat_...) to access contribution data.")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    SecureField("ghp_xxxxxxxxxxxxxxxxxxxx", text: $patInput)
                        .textFieldStyle(.roundedBorder)

                    Button("Save Token") {
                        savePersonalToken()
                    }
                    .buttonStyle(ModernPrimaryButtonStyle())
                    .disabled(isSavingPAT || patInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Button(action: openCreateTokenURL) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right.square")
                            Text("Generate Token on GitHub (Pre-selected Scopes)")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                    }
                    .buttonStyle(.link)

                    Text("Opens GitHub with required scopes (repo, read:user) automatically pre-checked.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if let msg = saveStatusMessage {
                    let isError = msg.lowercased().contains("failed") || msg.lowercased().contains("error") || msg.lowercased().contains("invalid") || msg.lowercased().contains("exceeded")
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(isError ? .red : .green)
                }
            }

            Divider()

            // Widget Filter Options Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Widget Filter Options")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pull Requests Widget:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("", selection: Binding(
                            get: { prWidgetFilter },
                            set: { newFilter in
                                prWidgetFilter = newFilter
                                UserPreferences.shared.prWidgetFilter = newFilter
                            }
                        )) {
                            ForEach(PRWidgetFilter.selectableCases, id: \.self) { filter in
                                Text(filter.displayName).tag(filter)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Issues Widget:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("", selection: Binding(
                            get: { issueWidgetFilter },
                            set: { newFilter in
                                issueWidgetFilter = newFilter
                                UserPreferences.shared.issueWidgetFilter = newFilter
                            }
                        )) {
                            ForEach(IssueWidgetFilter.allCases, id: \.self) { filter in
                                Text(filter.displayName).tag(filter)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }

            Spacer()
        }
        .padding(16)
    }

    private var aboutTab: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: 64, height: 64)

                    Image(systemName: "flame.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .foregroundColor(.orange)
                }

                VStack(spacing: 4) {
                    Text("GitStreak")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

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

                Text("© 2026 Wenuja Liyanamana (BSL 1.1 License)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(spacing: 10) {
                if let updateStatus = updaterViewModel.lastStatusMessage {
                    Text(updateStatus)
                        .font(.caption)
                        .foregroundColor(updateStatus.contains("up to date") ? .green : (updateStatus.contains("failed") ? .red : .secondary))
                }

                HStack(spacing: 12) {
                    Button(action: {
                        updaterViewModel.checkForUpdates()
                    }) {
                        HStack(spacing: 6) {
                            if updaterViewModel.isCheckingForUpdates {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text("Check for Updates...")
                        }
                    }
                    .buttonStyle(ModernSecondaryButtonStyle())
                    .disabled(updaterViewModel.isCheckingForUpdates)

                    Spacer()

                    Button("Reset & Clear All Data") {
                        showingClearConfirmation = true
                    }
                    .buttonStyle(DestructiveButtonStyle())
                }
            }
        }
        .padding(20)
        .confirmationDialog("Are you sure you want to clear all data?", isPresented: $showingClearConfirmation) {
            Button("Clear Everything", role: .destructive) {
                clearData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove your cached contribution history, stored GitHub credentials, and reset the app.")
        }
    }

    private func openCreateTokenURL() {
        if let url = URL(string: "https://github.com/settings/tokens/new?description=GitStreak%20App&scopes=repo,read:user") {
            NSWorkspace.shared.open(url)
        }
    }

    private func savePersonalToken() {
        let cleanToken = patInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanToken.isEmpty else { return }

        isSavingPAT = true
        saveStatusMessage = nil

        Task {
            do {
                TokenStorage.saveToken(cleanToken)

                let userInfo = try await OAuthService.shared.fetchAuthenticatedUser(token: cleanToken)
                UserPreferences.shared.username = userInfo.username

                let data = try await SharedDataStore.shared.refreshData(force: true)
                SharedDataStore.shared.notifyWidgetToRefresh()

                await MainActor.run {
                    self.username = userInfo.username
                    self.avatarURL = data.user.avatarURL
                    self.isSavingPAT = false
                    self.saveStatusMessage = "Personal Access Token saved successfully! (@\(userInfo.username))"
                }
            } catch {
                await MainActor.run {
                    self.isSavingPAT = false
                    self.saveStatusMessage = "Failed to save token: \(error.localizedDescription)"
                }
            }
        }
    }

    private func signOut() {
        try? SharedDataStore.shared.clearAllData()
        username = ""
        avatarURL = nil
        patInput = ""
        saveStatusMessage = nil
    }

    private func clearData() {
        try? SharedDataStore.shared.clearAllData()
        username = ""
        avatarURL = nil
        patInput = ""
        saveStatusMessage = nil
    }
}

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = state
        return visualEffectView
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

private struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                callback(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
