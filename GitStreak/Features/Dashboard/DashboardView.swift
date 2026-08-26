import SwiftUI
import Combine
import WidgetKit
import GitStreakKit

struct DashboardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var contributionData: ContributionData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedThemeID = UserPreferences.shared.selectedThemeID
    @State private var isFastPolling = false
    @State private var selectedYear: Int? = nil
    private let autoRefreshTimer = Timer.publish(every: 900, on: .main, in: .common).autoconnect()

    private var appBgColor: Color {
        colorScheme == .dark ? Color(hex: "#131313") : Color(nsColor: .windowBackgroundColor)
    }

    private var cardBgColor: Color {
        colorScheme == .dark ? Color(hex: "#1A1A1A") : Color(nsColor: .controlBackgroundColor)
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }

    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 0) {

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

                    Button(action: {
                        if #available(macOS 14.0, *) {
                            openSettings()
                        } else {
                            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                        }
                    }) {
                        Text("Config")
                            .font(GSTypography.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(DevHeaderButtonStyle())

                    Button(action: { triggerSmartRefresh() }) {
                        Group {
                            if isLoading || isFastPolling {
                                ProgressView()
                                    .controlSize(.small)
                                    .frame(width: 50)
                            } else {
                                Text("Refresh")
                                    .font(GSTypography.body)
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
                                .font(GSTypography.caption)
                                .foregroundColor(.primary)
                            Spacer()
                            Button("Dismiss") { errorMessage = nil }
                                .buttonStyle(.plain)
                                .font(GSTypography.caption)
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

                        HStack(alignment: .center, spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.orange)
                                    Text("Current Streak")
                                        .font(GSTypography.caption)
                                        .foregroundColor(.secondary)
                                }

                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Text("\(data.currentStreak)")
                                        .font(GSTypography.largeTitle)
                                        .foregroundColor(.primary)
                                    Text("days")
                                        .font(GSTypography.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Personal Best")
                                    .font(GSTypography.caption)
                                    .foregroundColor(.secondary)
                                Text("\(data.longestStreak) days")
                                    .font(GSTypography.title)
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

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Text("Activity Timeline")
                                    .font(GSTypography.caption)
                                    .foregroundColor(.secondary)

                                if let yr = selectedYear {
                                    Text("(\(String(yr)))")
                                        .font(GSTypography.caption)
                                        .foregroundColor(.orange)
                                        .bold()
                                } else {
                                    Text("(Past Year)")
                                        .font(GSTypography.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }

                            HStack(alignment: .top, spacing: 14) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(alignment: .top, spacing: 8) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Spacer().frame(height: 14)
                                            Text(" ").font(.system(size: 8))
                                            Text("M").font(GSTypography.monoBadge).foregroundColor(.secondary)
                                            Text(" ").font(.system(size: 8))
                                            Text("W").font(GSTypography.monoBadge).foregroundColor(.secondary)
                                            Text(" ").font(.system(size: 8))
                                            Text("F").font(GSTypography.monoBadge).foregroundColor(.secondary)
                                            Text(" ").font(.system(size: 8))
                                        }

                                        Spacer(minLength: 0)

                                        ScrollView(.horizontal, showsIndicators: false) {
                                            ContributionGridView(
                                                weeks: data.weeks,
                                                theme: ThemeRegistry.theme(for: selectedThemeID),
                                                maxWeeks: 53,
                                                cellSize: 13.5,
                                                columnSpacing: 3.5,
                                                rowSpacing: 3.0,
                                                cornerRadius: 1.5,
                                                showMonthHeaders: true,
                                                showTooltips: true
                                            )
                                            .padding(.vertical, 8)
                                        }
                                        .defaultScrollAnchor(.trailing)
                                    }

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

                                Divider()
                                    .frame(height: 140)
                                    .opacity(0.15)

                                VStack(alignment: .leading, spacing: 4) {
                                    YearPillButton(
                                        title: "Past Year",
                                        isSelected: selectedYear == nil
                                    ) {
                                        selectYear(nil)
                                    }

                                    ForEach(data.availableYears, id: \.self) { yr in
                                        YearPillButton(
                                            title: String(yr),
                                            isSelected: selectedYear == yr
                                        ) {
                                            selectYear(yr)
                                        }
                                    }
                                }
                                .frame(width: 85, alignment: .topLeading)
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

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Widget Theme")
                                .font(GSTypography.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }

                        ThemePickerView(selectedThemeID: $selectedThemeID) { newThemeID in
                            UserPreferences.shared.selectedThemeID = newThemeID
                            WidgetCenter.shared.reloadAllTimelines()
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
        .onReceive(autoRefreshTimer) { _ in
            checkAndAutoRefresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            checkAndAutoRefresh()
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

            if Date().timeIntervalSince(cached.fetchedAt) >= 5 {
                Task {
                    await refreshData(silent: true)
                }
            }
        } else {
            Task {
                await refreshData(silent: false)
            }
        }
    }

    private func checkAndAutoRefresh() {
        if contributionData == nil {
            Task { await refreshData(silent: false, force: false) }
        } else {
            Task { await refreshData(silent: true, force: false) }
        }
    }

    private func triggerSmartRefresh() {
        Task {
            await refreshData(silent: false, force: true)
        }
    }

    private func selectYear(_ year: Int?) {
        self.selectedYear = year
        Task {
            await refreshData(year: year, silent: false, force: false)
        }
    }

    @MainActor
    private func refreshData(year: Int? = nil, silent: Bool = false, force: Bool = true) async {
        guard !isLoading else { return }
        if !silent {
            isLoading = true
        }

        do {
            let targetYear = year ?? selectedYear
            let data = try await SharedDataStore.shared.refreshData(year: targetYear, force: force)
            self.contributionData = data
            self.errorMessage = nil
            self.isLoading = false
        } catch {
            if !silent {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
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

struct YearPillButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundColor(
                    isSelected
                    ? .orange
                    : (isHovered ? .primary : .secondary)
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            isSelected
                            ? Color.orange.opacity(0.12)
                            : (isHovered ? (colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)) : Color.clear)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            isSelected
                            ? Color.orange.opacity(0.8)
                            : (colorScheme == .dark ? Color.white.opacity(isHovered ? 0.15 : 0.0) : Color.black.opacity(isHovered ? 0.12 : 0.0)),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
}
