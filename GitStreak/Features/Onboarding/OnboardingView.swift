import SwiftUI
import GitStreakKit

enum NavigationDirection {
    case forward, backward
}

struct OnboardingView: View {
    @Environment(\.colorScheme) private var colorScheme
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var navigationDirection: NavigationDirection = .forward
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var fetchedData: ContributionData? = nil
    @State private var selectedThemeID = UserPreferences.shared.selectedThemeID

    @State private var isAuthenticatingOAuth = false
    @State private var deviceCodeResponse: DeviceCodeResponse? = nil
    @State private var isPollingOAuth = false

    private var appBgColor: Color {
        colorScheme == .dark ? Color(hex: "#131313") : Color(nsColor: .windowBackgroundColor)
    }

    private func advanceStep() {
        navigationDirection = .forward
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentStep = min(currentStep + 1, 3)
        }
    }

    private func regressStep() {
        navigationDirection = .backward
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentStep = max(currentStep - 1, 0)
        }
    }

    private var currentTransition: AnyTransition {
        let insertionEdge: Edge = navigationDirection == .forward ? .trailing : .leading
        let removalEdge: Edge = navigationDirection == .forward ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: insertionEdge).combined(with: .opacity),
            removal: .move(edge: removalEdge).combined(with: .opacity)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                switch currentStep {
                case 0:
                    welcomeStep
                        .transition(currentTransition)
                case 1:
                    connectStep
                        .transition(currentTransition)
                case 2:
                    previewStep
                        .transition(currentTransition)
                case 3:
                    doneStep
                        .transition(currentTransition)
                default:
                    EmptyView()
                }
            }
            .clipped()

            Spacer()

            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { index in
                        Capsule()
                            .fill(index == currentStep ? Color.orange : Color.primary.opacity(0.18))
                            .frame(width: index == currentStep ? 24 : 6, height: 6)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentStep)
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    if currentStep > 0 && currentStep < 3 && !isAuthenticatingOAuth {
                        Button(action: regressStep) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                        .buttonStyle(ModernSecondaryButtonStyle())
                    }

                    if currentStep == 0 {
                        Button("Get Started", action: advanceStep)
                            .buttonStyle(ModernPrimaryButtonStyle())
                    } else if currentStep == 2 {
                        Button("Continue", action: advanceStep)
                            .buttonStyle(ModernPrimaryButtonStyle())
                    } else if currentStep == 3 {
                        Button("Open GitStreak", action: onComplete)
                            .buttonStyle(ModernPrimaryButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
            .background(colorScheme == .dark ? Color(hex: "#0E0F12") : Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 900, maxWidth: 900, minHeight: 700, maxHeight: 700)
        .background(appBgColor)
    }

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "flame.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(.orange)

            VStack(spacing: 8) {
                Text("GitStreak")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)

                Text("Make your coding habit visible")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Text("Track your GitHub contributions right on your desktop with a calm, beautiful widget.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .font(.body)
                .frame(maxWidth: 420)
        }
    }

    private var connectStep: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("Connect to GitHub")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                Text("Sign in via GitHub Device Flow to display your activity widget.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            if isAuthenticatingOAuth, let devCode = deviceCodeResponse {
                VStack(spacing: 22) {
                    VStack(spacing: 12) {
                        Text("ENTER THIS CODE ON GITHUB:")
                            .font(GSTypography.monoBadge)
                            .foregroundColor(.secondary)
                            .tracking(1.5)

                        CopyableUserCodeView(userCode: devCode.userCode, fontSize: 32, paddingVertical: 10, paddingHorizontal: 20, cornerRadius: 8)

                        Text("✓ Code copied to clipboard")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    HStack(spacing: 16) {
                        Button("Open GitHub in Browser") {
                            OAuthService.openDeviceLogin(userCode: devCode.userCode, verificationUri: devCode.verificationUri)
                        }
                        .buttonStyle(ModernPrimaryButtonStyle())

                        Button("Cancel") {
                            cancelOAuth()
                        }
                        .buttonStyle(ModernSecondaryButtonStyle())
                    }

                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Waiting for authorization on GitHub...")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: 520)
                .transition(.scale.combined(with: .opacity))
            } else {
                VStack(spacing: 20) {
                    Button(action: startOAuthFlow) {
                        HStack(spacing: 10) {
                            Image(systemName: "person.badge.key.fill")
                                .font(.system(size: 15))
                            Text("Sign in with GitHub")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ModernPrimaryButtonStyle())
                    .disabled(isLoading)

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.callout)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: 360)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var previewStep: some View {
        VStack(spacing: 22) {
            VStack(spacing: 6) {
                Text("Your Activity & Theme")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                Text("Preview your contribution matrix and pick a color theme.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            if let data = fetchedData {
                VStack(spacing: 14) {
                    HStack(spacing: 18) {
                        StatCardView(
                            title: "Current Streak",
                            value: "\(data.currentStreak)d",
                            icon: "flame.fill",
                            iconColor: .orange
                        )
                        StatCardView(
                            title: "Contributions",
                            value: "\(data.totalContributions)",
                            icon: "square.grid.3x3.fill",
                            iconColor: .green
                        )
                    }

                    ContributionGridView(
                        weeks: data.weeks,
                        theme: ThemeRegistry.theme(for: selectedThemeID),
                        maxWeeks: 26,
                        cellSize: 12,
                        cellSpacing: 3
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .frame(maxWidth: 540)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Theme Palette:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(ThemeRegistry.allThemes, id: \.id) { theme in
                            ThemeSwatchGridItem(theme: theme, isSelected: selectedThemeID == theme.id)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedThemeID = theme.id
                                    }
                                    UserPreferences.shared.selectedThemeID = theme.id
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .frame(maxWidth: 540)
        }
    }

    private var doneStep: some View {
        VStack(spacing: 28) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            VStack(spacing: 8) {
                Text("Widget Ready")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                Text("Add GitStreak to your desktop wallpaper in 4 easy steps:")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                        .frame(width: 28)
                    Text("Right-click your desktop wallpaper")
                        .font(.body)
                        .foregroundColor(.primary)
                }
                HStack(spacing: 14) {
                    Image(systemName: "plus.square.on.square")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                        .frame(width: 28)
                    Text("Select 'Edit Widgets...'")
                        .font(.body)
                        .foregroundColor(.primary)
                }
                HStack(spacing: 14) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                        .frame(width: 28)
                    Text("Search for 'GitStreak' and pick a widget size")
                        .font(.body)
                        .foregroundColor(.primary)
                }
                HStack(spacing: 14) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                        .frame(width: 28)
                    Text("Drag it anywhere onto your desktop wallpaper")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            .frame(maxWidth: 500)
        }
    }

    private func startOAuthFlow() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isLoading = true
            errorMessage = nil
        }

        Task {
            do {
                let codeResponse = try await OAuthService.shared.requestDeviceCode()

                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        self.deviceCodeResponse = codeResponse
                        self.isAuthenticatingOAuth = true
                        self.isLoading = false
                        self.isPollingOAuth = true
                    }
                }

                OAuthService.openDeviceLogin(userCode: codeResponse.userCode, verificationUri: codeResponse.verificationUri)

                let accessToken = try await OAuthService.shared.pollForToken(deviceCode: codeResponse.deviceCode, interval: codeResponse.interval)
                let userInfo = try await OAuthService.shared.fetchAuthenticatedUser(token: accessToken)

                let service = ContributionService()
                let data = try await service.fetchContributions(username: userInfo.username, token: accessToken)

                TokenStorage.saveToken(accessToken)
                UserPreferences.shared.username = userInfo.username
                SharedDataStore.shared.notifyWidgetToRefresh()

                await MainActor.run {
                    self.fetchedData = data
                    self.isAuthenticatingOAuth = false
                    self.isPollingOAuth = false
                    self.advanceStep()
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        self.isLoading = false
                        self.isAuthenticatingOAuth = false
                        self.isPollingOAuth = false
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private func cancelOAuth() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isAuthenticatingOAuth = false
            isPollingOAuth = false
            deviceCodeResponse = nil
        }
    }
}
