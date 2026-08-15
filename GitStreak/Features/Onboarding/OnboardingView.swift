import SwiftUI
import GitStreakKit

struct OnboardingView: View {
    let onComplete: () -> Void
    
    @State private var currentStep = 0
    @State private var username = ""
    @State private var token = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var fetchedData: ContributionData? = nil
    @State private var selectedThemeID = UserPreferences.shared.selectedThemeID
    
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
                if currentStep > 0 && currentStep < 3 {
                    Button("Back") {
                        currentStep -= 1
                    }
                    .buttonStyle(.link)
                }
                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 540, minHeight: 440)
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
                
                Text("Enter your GitHub username and a Personal Access Token.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Username")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("e.g. torvalds", text: $username)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Personal Access Token (PAT)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    SecureField("ghp_...", text: $token)
                        .textFieldStyle(.roundedBorder)
                }
                
                Text("Create a classic token with **no scopes** needed at [github.com/settings/tokens](https://github.com/settings/tokens)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .frame(maxWidth: 340)
            
            Button(action: connectAccount) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Connect Account")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(username.trimmingCharacters(in: .whitespaces).isEmpty || token.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
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
                        maxWeeks: 13,
                        cellSize: 12,
                        cellSpacing: 3
                    )
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                .frame(maxWidth: 440)
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
            .frame(maxWidth: 440)
            
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
    
    private func connectAccount() {
        let cleanUsername = username.trimmingCharacters(in: .whitespaces)
        let cleanToken = token.trimmingCharacters(in: .whitespaces)
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let service = ContributionService()
                let data = try await service.fetchContributions(username: cleanUsername, token: cleanToken)
                
                try KeychainService.save(token: cleanToken, forKey: "github_pat")
                UserPreferences.shared.username = cleanUsername
                SharedDataStore.shared.notifyWidgetToRefresh()
                
                await MainActor.run {
                    self.fetchedData = data
                    self.isLoading = false
                    self.currentStep += 1
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
