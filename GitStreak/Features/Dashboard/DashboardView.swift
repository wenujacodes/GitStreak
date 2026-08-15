import SwiftUI
import GitStreakKit

struct DashboardView: View {
    @State private var contributionData: ContributionData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedThemeID = UserPreferences.shared.selectedThemeID
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(alignment: .center, spacing: 14) {
                if let data = contributionData {
                    AvatarView(avatarURL: data.user.avatarURL, size: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(data.user.displayName ?? data.user.username)
                                .font(.headline)
                            Text("@\(data.user.username)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Updated \(data.fetchedAt, style: .relative) ago")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Circle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.secondary)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(UserPreferences.shared.username ?? "GitStreak")
                            .font(.headline)
                        Text("Loading...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: { Task { await refreshData() } }) {
                    HStack(spacing: 4) {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(isLoading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.callout)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Dismiss") {
                                errorMessage = nil
                            }
                            .buttonStyle(.link)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    if let data = contributionData {
                        // Activity Grid Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Activity History")
                                    .font(.headline)
                                Spacer()
                                Text("Last 13 weeks")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Spacer()
                                ContributionGridView(
                                    weeks: data.weeks,
                                    theme: ThemeRegistry.theme(for: selectedThemeID),
                                    maxWeeks: 13,
                                    cellSize: 14,
                                    cellSpacing: 4
                                )
                                Spacer()
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 12)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(10)
                        }
                        
                        // Stats Row
                        HStack(spacing: 16) {
                            StatCardView(
                                title: "Current Streak",
                                value: "\(data.currentStreak) days",
                                icon: "flame.fill",
                                iconColor: .orange
                            )
                            
                            StatCardView(
                                title: "Longest Streak",
                                value: "\(data.longestStreak) days",
                                icon: "trophy.fill",
                                iconColor: .yellow
                            )
                            
                            StatCardView(
                                title: "Total Contributions",
                                value: "\(data.totalContributions)",
                                icon: "square.grid.3x3.fill",
                                iconColor: .green
                            )
                        }
                    } else if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading your contribution data...")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    }
                    
                    Divider()
                    
                    // Theme Selector Section
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Widget Theme")
                                .font(.headline)
                            Text("Choose a color palette for your desktop widget.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ThemePickerView(selectedThemeID: $selectedThemeID) { newThemeID in
                            UserPreferences.shared.selectedThemeID = newThemeID
                            SharedDataStore.shared.notifyWidgetToRefresh()
                        }
                    }
                }
                .padding(24)
            }
        }
        .frame(minWidth: 680, minHeight: 520)
        .onAppear {
            loadInitialData()
        }
    }
    
    private func loadInitialData() {
        if let cached = SharedDataStore.shared.getCachedData() {
            self.contributionData = cached
        } else {
            Task {
                await refreshData()
            }
        }
    }
    
    private func refreshData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let data = try await SharedDataStore.shared.refreshData()
            await MainActor.run {
                self.contributionData = data
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
