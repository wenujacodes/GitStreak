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

    @State private var patInput: String = TokenStorage.loadToken() ?? ""

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
                    if currentStep > 0 && currentStep < 3 {
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
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Connect GitHub Token")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                Text("Paste your GitHub Personal Access Token to display your contribution activity.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Personal Access Token (ghp_... or github_pat_...)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    SecureField("ghp_xxxxxxxxxxxxxxxxxxxx", text: $patInput)
                        .textFieldStyle(.roundedBorder)

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
                }

                Button(action: connectWithPAT) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .colorScheme(.dark)
                                .tint(.white)
                        } else {
                            Image(systemName: "key.fill")
                        }
                        Text("Connect Account")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ModernPrimaryButtonStyle())
                .disabled(isLoading || patInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: 420)
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
                                    SharedDataStore.shared.notifyWidgetToRefresh()
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

    private func openCreateTokenURL() {
        if let url = URL(string: "https://github.com/settings/tokens/new?description=GitStreak%20App&scopes=repo,read:user") {
            NSWorkspace.shared.open(url)
        }
    }

    private func connectWithPAT() {
        let cleanToken = patInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanToken.isEmpty else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            isLoading = true
            errorMessage = nil
        }

        Task {
            do {
                let userInfo = try await OAuthService.shared.fetchAuthenticatedUser(token: cleanToken)
                let service = ContributionService()
                let data = try await service.fetchContributions(username: userInfo.username, token: cleanToken)

                TokenStorage.saveToken(cleanToken)
                UserPreferences.shared.username = userInfo.username
                SharedDataStore.shared.notifyWidgetToRefresh()

                await MainActor.run {
                    self.fetchedData = data
                    self.isLoading = false
                    self.advanceStep()
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        self.isLoading = false
                        self.errorMessage = "Invalid Token: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}
