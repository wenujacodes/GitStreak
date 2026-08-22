import SwiftUI
import GitStreakKit

struct DashboardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var contributionData: ContributionData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedThemeID = UserPreferences.shared.selectedThemeID
    
    private var appBgColor: Color {
        colorScheme == .dark ? Color(red: 18/255, green: 19/255, blue: 19/255) : Color(nsColor: .windowBackgroundColor)
    }
    
    private var cardBgColor: Color {
        colorScheme == .dark ? Color(red: 24/255, green: 25/255, blue: 25/255) : Color(nsColor: .controlBackgroundColor)
    }
    
    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }
    
    @Environment(\.openSettings) private var openSettings
    
    var body: some View {
        VStack(spacing: 0) {
            // Command Header
            HStack(alignment: .center, spacing: 14) {
                if let data = contributionData {
                    AvatarView(avatarURL: data.user.avatarURL, size: 36)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(data.user.displayName ?? data.user.username)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("@\(data.user.username)")
                                .font(GSTypography.monoCaption)
                                .foregroundColor(.secondary)
                        }
                        
                        TimelineView(.periodic(from: .now, by: 1)) { _ in
                            Text("Updated \(relativeTimeString(from: data.fetchedAt))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "person.fill").foregroundColor(.secondary))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(UserPreferences.shared.username ?? "GitStreak")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Connecting...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // CONFIG / Settings Button
                    Button(action: {
                        if #available(macOS 14.0, *) {
                            openSettings()
                        } else {
                            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                        }
                    }) {
                        Text("CONFIG")
                            .font(GSTypography.monoBadge)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(DevHeaderButtonStyle())
                    
                    // REFRESH Button
                    Button(action: { Task { await refreshData() } }) {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .controlSize(.small)
                                    .frame(width: 50)
                            } else {
                                Text("REFRESH")
                                    .font(GSTypography.monoBadge)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(DevHeaderButtonStyle())
                    .disabled(isLoading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(appBgColor)
            
            ScrollView {
                VStack(spacing: 20) {
                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(GSTypography.monoCaption)
                                .foregroundColor(.primary)
                            Spacer()
                            Button("Dismiss") { errorMessage = nil }
                                .buttonStyle(.plain)
                                .font(GSTypography.monoCaption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color.orange.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(6)
                    }
                    
                    if let data = contributionData {
                        // Hero Streak Banner
                        HStack(alignment: .center, spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.orange)
                                    Text("CURRENT STREAK")
                                        .font(GSTypography.monoCaption)
                                        .foregroundColor(.secondary)
                                        .tracking(1)
                                }
                                
                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Text("\(data.currentStreak)")
                                        .font(GSTypography.monoLarge)
                                        .foregroundColor(.primary)
                                    Text("DAYS")
                                        .font(GSTypography.monoCaption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("PERSONAL BEST")
                                    .font(GSTypography.monoBadge)
                                    .foregroundColor(.secondary)
                                    .tracking(0.5)
                                Text("\(data.longestStreak) DAYS")
                                    .font(GSTypography.monoTitle)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.08), colorScheme == .dark ? Color.white.opacity(0.02) : Color.orange.opacity(0.02)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                        )
                        
                        // Heatmap Viewport Section (Full 53 Weeks Default)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("ACTIVITY TIMELINE (PAST YEAR)")
                                    .font(GSTypography.monoCaption)
                                    .foregroundColor(.secondary)
                                    .tracking(0.8)
                                
                                Spacer()
                            }
                            
                            HStack(alignment: .top, spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(" ").font(.system(size: 8))
                                    Text("M").font(GSTypography.monoBadge).foregroundColor(.secondary)
                                    Text(" ").font(.system(size: 8))
                                    Text("W").font(GSTypography.monoBadge).foregroundColor(.secondary)
                                    Text(" ").font(.system(size: 8))
                                    Text("F").font(GSTypography.monoBadge).foregroundColor(.secondary)
                                    Text(" ").font(.system(size: 8))
                                }
                                
                                Spacer(minLength: 0)
                                
                                ContributionGridView(
                                    weeks: data.weeks,
                                    theme: ThemeRegistry.theme(for: selectedThemeID),
                                    maxWeeks: 53,
                                    cellSize: 11.5,
                                    cellSpacing: 2.8,
                                    showTooltips: true
                                )
                                
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                            
                            // Less / More Color Legend
                            HStack {
                                Spacer()
                                
                                HStack(spacing: 5) {
                                    Text("Less")
                                        .font(GSTypography.monoBadge)
                                        .foregroundColor(.secondary)
                                    
                                    let currentTheme = ThemeRegistry.theme(for: selectedThemeID)
                                    let colors = currentTheme.allColors(for: colorScheme)
                                    ForEach(colors.indices, id: \.self) { idx in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(colors[idx])
                                            .frame(width: 10, height: 10)
                                    }
                                    
                                    Text("More")
                                        .font(GSTypography.monoBadge)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(cardBgColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(borderColor, lineWidth: 1)
                        )
                        
                        // Dev Metric Cards
                        HStack(spacing: 12) {
                            StatCardView(
                                title: "Current Streak",
                                value: "\(data.currentStreak)d",
                                icon: "flame.fill",
                                iconColor: .orange,
                                subtitle: data.currentStreak > 0 ? "Active today" : "No commits yet"
                            )
                            
                            StatCardView(
                                title: "Longest Streak",
                                value: "\(data.longestStreak)d",
                                icon: "trophy.fill",
                                iconColor: .yellow,
                                subtitle: "All-time streak"
                            )
                            
                            StatCardView(
                                title: "Contributions",
                                value: "\(data.totalContributions)",
                                icon: "square.grid.3x3.fill",
                                iconColor: .green,
                                subtitle: "Total past year"
                            )
                        }
                    } else if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Fetching commit timeline...")
                                .font(GSTypography.monoCaption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 220)
                    }
                    
                    // Theme Selector Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("WIDGET THEME")
                                .font(GSTypography.monoCaption)
                                .foregroundColor(.secondary)
                                .tracking(0.8)
                            Spacer()
                        }
                        
                        ThemePickerView(selectedThemeID: $selectedThemeID) { newThemeID in
                            UserPreferences.shared.selectedThemeID = newThemeID
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(cardBgColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(borderColor, lineWidth: 1)
                    )
                }
                .padding(20)
            }
        }
        .frame(minWidth: 900, maxWidth: 900, minHeight: 700, maxHeight: 700)
        .background(appBgColor)
        .onAppear {
            loadInitialData()
        }
    }
    
    private func relativeTimeString(from date: Date) -> String {
        let elapsed = max(0, Int(Date().timeIntervalSince(date)))
        if elapsed < 60 {
            return "\(elapsed)s ago"
        }
        let minutes = elapsed / 60
        if minutes < 60 {
            return "\(minutes)m ago"
        }
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)h ago"
        }
        let days = hours / 24
        return "\(days)d ago"
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
            let data = try await SharedDataStore.shared.refreshData(force: true)
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

struct DevHeaderButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(configuration.isPressed ? 0.12 : 0.06)
                          : Color.black.opacity(configuration.isPressed ? 0.12 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08), lineWidth: 1)
            )
            .contentShape(Rectangle())
    }
}
