import SwiftUI
import UserNotifications
import GitStreakKit

/// Settings tab for streak notifications.
struct NotificationSettingsView: View {
    private typealias Key = StreakNotificationPreferences.Key

    @AppStorage(Key.enabled) private var enabled = true
    @AppStorage(Key.atRisk) private var atRisk = true
    @AppStorage(Key.atRiskMinutes) private var atRiskMinutes = 18 * 60
    @AppStorage(Key.lastCall) private var lastCall = true
    @AppStorage(Key.extended) private var extended = true
    @AppStorage(Key.record) private var record = true
    @AppStorage(Key.milestones) private var milestones = true
    @AppStorage(Key.streakLost) private var streakLost = true
    @AppStorage(Key.weeklyRecap) private var weeklyRecap = true

    @State private var status: UNAuthorizationStatus = .notDetermined

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Streak notifications", isOn: $enabled)
                    .toggleStyle(.switch)
                    .font(.subheadline.weight(.semibold))
                    .onChange(of: enabled) { _, isOn in
                        if isOn { Task { await askPermission() } }
                    }
                Text("GitStreak reminds you to keep your contribution streak going. Only contributions pushed to GitHub count.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if status == .denied {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                    Text("Notifications are turned off for GitStreak in System Settings.")
                        .font(.caption)
                    Button("Open Settings…", action: openSystemSettings)
                        .buttonStyle(.link)
                        .font(.caption)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    option("Streak at risk", "When you haven't contributed yet today.", $atRisk)
                    Spacer()
                    DatePicker("", selection: reminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .frame(width: 90)
                        .disabled(!enabled || !atRisk)
                }
                option("Last call", "At 11 PM if there's still nothing today.", $lastCall)
                option("Streak extended", "After your first contribution of the day.", $extended)
                option("New personal record", "The day you beat your longest streak.", $record)
                option("Milestones", "At 7, 30, 50, 100, 365 days and more.", $milestones)
                option("Streak lost", "The next morning, so you can start again.", $streakLost)
                option("Weekly recap", "Sunday at 8 PM: your week in numbers.", $weeklyRecap)
            }
            .disabled(!enabled)
            .opacity(enabled ? 1 : 0.5)

            Spacer()

            HStack {
                Text("GitHub can take a few minutes to show a new contribution, so notifications may arrive a little after you push.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button("Send Test Notification") {
                    Task {
                        await StreakNotifier.shared.sendTest()
                        await refreshStatus()
                    }
                }
                .buttonStyle(ModernSecondaryButtonStyle())
            }
        }
        .padding(16)
        .task { await refreshStatus() }
    }

    private func option(_ title: String, _ detail: String, _ isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.callout)
                Text(detail).font(.caption2).foregroundColor(.secondary)
            }
        }
        .toggleStyle(.checkbox)
    }

    /// The reminder time as a Date for the picker; stored as minutes after midnight.
    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: atRiskMinutes / 60, minute: atRiskMinutes % 60, second: 0, of: Date()) ?? Date()
            },
            set: { date in
                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                atRiskMinutes = (c.hour ?? 18) * 60 + (c.minute ?? 0)
            }
        )
    }

    private func askPermission() async {
        await StreakNotifier.shared.requestAuthorization()
        await refreshStatus()
    }

    private func refreshStatus() async {
        status = await StreakNotifier.shared.authorizationStatus()
    }

    private func openSystemSettings() {
        let id = Bundle.main.bundleIdentifier ?? "com.gitstreak.GitStreak"
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(id)") {
            NSWorkspace.shared.open(url)
        }
    }
}
