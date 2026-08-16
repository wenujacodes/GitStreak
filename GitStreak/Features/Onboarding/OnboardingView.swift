import SwiftUI
import GitStreakKit

struct OnboardingView: View {
    let onComplete: () -> Void
    
    @State private var currentStep = 0
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var fetchedData: ContributionData? = nil
    @State private var selectedThemeID = UserPreferences.shared.selectedThemeID
    
    // OAuth Device Flow state
    @State private var isAuthenticatingOAuth = false
    @State private var deviceCodeResponse: DeviceCodeResponse? = nil
    @State private var isPollingOAuth = false
    
    var body: some View {
        VStack {
            Spacer()
            
            Group {
                switch currentStep {
                case 0:
                    welcomeStep
                case 1:
                    connectStep
                case 2:
                    previewStep
                case 3:
                    doneStep
                default:
                    EmptyView()
                }
            }
            .animation(.easeInOut, value: currentStep)
            
            Spacer()
            
            HStack {
                if currentStep > 0 && currentStep < 3 && !isAuthenticatingOAuth {
                    Button("Back") {
                        currentStep -= 1
                    }
                    .buttonStyle(.link)
                }
                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 900, maxWidth: 900, minHeight: 560)
        .padding()
    }
    
    // MARK: - Step 1: Welcome
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "flame.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(.orange)
            
            VStack(spacing: 6) {
                Text("GitStreak")
                    .font(.system(size: 28, weight: .bold))
                
                Text("Make your coding habit visible")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            Text("Track your GitHub contributions right on your desktop with a calm, beautiful widget.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 360)
            
            Button("Get Started") {
                currentStep += 1
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 10)
        }
    }
    
    // MARK: - Step 2: Connect
    private var connectStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("Connect to GitHub")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Sign in with 1-click via GitHub to track your contribution activity.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if isAuthenticatingOAuth, let devCode = deviceCodeResponse {
                // Device Flow Pending View
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("ENTER THIS CODE ON GITHUB:")
                            .font(GSTypography.monoBadge)
                            .foregroundColor(.secondary)
                            .tracking(1)
                        
                        Text(devCode.userCode)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.primary.opacity(0.08))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                            )
                        
                        Text("✓ Code copied to clipboard")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    
                    HStack(spacing: 12) {
                        Button("Open GitHub in Browser") {
                            OAuthService.openDeviceLogin(userCode: devCode.userCode, verificationUri: devCode.verificationUri)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        
                        Button("Cancel") {
                            cancelOAuth()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
                    
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Waiting for authorization on GitHub...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .frame(maxWidth: 420)
            } else {
                // 1-Click OAuth Button
                VStack(spacing: 16) {
                    Button(action: startOAuthFlow) {
                        HStack(spacing: 10) {
                            Image(systemName: "person.badge.key.fill")
                                .font(.system(size: 14))
                            Text("Sign in with GitHub")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isLoading)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: 320)
            }
        }
    }
    
    // MARK: - Step 3: Preview
    private var previewStep: some View {
        VStack(spacing: 18) {
            Text("Here's your activity")
                .font(.title2)
                .fontWeight(.bold)
            
            if let data = fetchedData {
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
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
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                .frame(maxWidth: 520)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Select a theme:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ThemeRegistry.allThemes, id: \.id) { theme in
                            ThemeSwatchGridItem(theme: theme, isSelected: selectedThemeID == theme.id)
                                .onTapGesture {
                                    selectedThemeID = theme.id
                                    UserPreferences.shared.selectedThemeID = theme.id
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .frame(maxWidth: 520)
            
            Button("Continue") {
                currentStep += 1
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
    
    // MARK: - Step 4: Done
    private var doneStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(.green)
            
            VStack(spacing: 6) {
                Text("You're all set!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Add the GitStreak widget to your desktop to start tracking.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Right-click your desktop wallpaper", systemImage: "1.circle.fill")
                Label("Select 'Edit Widgets...'", systemImage: "2.circle.fill")
                Label("Search for 'GitStreak' and pick a widget size", systemImage: "3.circle.fill")
                Label("Drag it anywhere on your desktop", systemImage: "4.circle.fill")
            }
            .font(.callout)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            
            Button("Open GitStreak") {
                onComplete()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 10)
        }
    }
    
    // MARK: - OAuth Flow
    private func startOAuthFlow() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let codeResponse = try await OAuthService.shared.requestDeviceCode()
                
                await MainActor.run {
                    self.deviceCodeResponse = codeResponse
                    self.isAuthenticatingOAuth = true
                    self.isLoading = false
                    self.isPollingOAuth = true
                }
                
                OAuthService.openDeviceLogin(userCode: codeResponse.userCode, verificationUri: codeResponse.verificationUri)
                
                let accessToken = try await OAuthService.shared.pollForToken(deviceCode: codeResponse.deviceCode, interval: codeResponse.interval)
                let userInfo = try await OAuthService.shared.fetchAuthenticatedUser(token: accessToken)
                
                let service = ContributionService()
                let data = try await service.fetchContributions(username: userInfo.username, token: accessToken)
                
                try KeychainService.save(token: accessToken, forKey: "github_pat")
                UserPreferences.shared.username = userInfo.username
                SharedDataStore.shared.notifyWidgetToRefresh()
                
                await MainActor.run {
                    self.fetchedData = data
                    self.isAuthenticatingOAuth = false
                    self.isPollingOAuth = false
                    self.currentStep += 1
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.isAuthenticatingOAuth = false
                    self.isPollingOAuth = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func cancelOAuth() {
        isAuthenticatingOAuth = false
        isPollingOAuth = false
        deviceCodeResponse = nil
    }
}
