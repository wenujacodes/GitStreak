import Foundation
import UserNotifications
import GitStreakKit

/// Sends streak notifications (at risk, extended, new record, …) after each background refresh.
/// The decisions are made by `StreakNotificationPlanner`; this class only talks to macOS.
final class StreakNotifier: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = StreakNotifier()

    static let atRiskCategory = "com.gitstreak.category.atRisk"
    static let snoozeAction = "com.gitstreak.action.snooze"
    static let snoozeIdentifier = "com.gitstreak.notification.snooze"
    private static let stateKey = "streakNotificationState"
    private static let lock = NSLock()

    private var center: UNUserNotificationCenter { .current() }

    /// Call once at launch, before any notification can be clicked.
    func setUp() {
        center.delegate = self
        let snooze = UNNotificationAction(identifier: Self.snoozeAction, title: "Remind Me in 1 Hour")
        let category = UNNotificationCategory(identifier: Self.atRiskCategory, actions: [snooze], intentIdentifiers: [])
        center.setNotificationCategories([category])
    }

    /// Asks macOS for permission. macOS only shows the prompt once; later calls return the saved answer.
    @discardableResult
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - After each refresh

    func process(_ data: ContributionData) async {
        let settings = StreakNotificationPreferences.load()
        let plan: StreakNotificationPlan = Self.lock.withLock {
            let plan = StreakNotificationPlanner.plan(days: data.allDays, previous: Self.loadState(), settings: settings)
            Self.saveState(plan.state)
            return plan
        }

        if plan.contributedToday {
            let reminders = [StreakNotificationKind.atRisk.identifier, StreakNotificationKind.lastCall.identifier, Self.snoozeIdentifier]
            center.removePendingNotificationRequests(withIdentifiers: reminders + [StreakNotificationKind.streakLost.identifier])
            center.removeDeliveredNotifications(withIdentifiers: reminders)
        }
        if plan.streakAlive {
            center.removePendingNotificationRequests(withIdentifiers: [StreakNotificationKind.streakLost.identifier])
        }

        guard !plan.notifications.isEmpty, await isAllowed() else { return }
        for note in plan.notifications {
            await send(note)
        }
    }

    func sendTest() async {
        guard await requestAuthorization() else { return }
        await send(StreakNotification(
            kind: .atRisk,
            title: "🔥 Your 13-day streak is at risk",
            body: "This is a test. Real reminders look like this.",
            deliverAt: nil))
    }

    /// Forget what was sent, e.g. after signing out, so the next account starts fresh.
    static func resetState() {
        lock.withLock { UserDefaults.standard.removeObject(forKey: stateKey) }
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func isAllowed() async -> Bool {
        let status = await authorizationStatus()
        return status == .authorized || status == .provisional
    }

    private func send(_ note: StreakNotification) async {
        let content = UNMutableNotificationContent()
        content.title = note.title
        content.body = note.body
        content.sound = .default
        if note.kind == .atRisk || note.kind == .lastCall {
            content.categoryIdentifier = Self.atRiskCategory
        }

        var trigger: UNNotificationTrigger?
        if let date = note.deliverAt {
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        }
        let request = UNNotificationRequest(identifier: note.kind.identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    // MARK: - State

    private static func loadState() -> StreakNotificationState? {
        guard let data = UserDefaults.standard.data(forKey: stateKey) else { return nil }
        return try? JSONDecoder().decode(StreakNotificationState.self, from: data)
    }

    private static func saveState(_ state: StreakNotificationState) {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: stateKey)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Show banners even while GitStreak is the active app.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        guard response.actionIdentifier == Self.snoozeAction else { return }
        let original = response.notification.request.content
        await snooze(title: original.title, body: original.body)
    }

    /// Reminds again in an hour, but never after midnight (the day is over by then).
    private func snooze(title: String, body: String) async {
        let now = Date()
        guard let midnight = Calendar.current.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime) else { return }
        let delay = min(60 * 60, midnight.timeIntervalSince(now) - 5 * 60)
        guard delay >= 60 else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = Self.atRiskCategory
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: Self.snoozeIdentifier, content: content, trigger: trigger))
    }
}

/// The notification switches from Settings, stored in the app's own defaults.
enum StreakNotificationPreferences {
    enum Key {
        static let enabled = "notifications.enabled"
        static let atRisk = "notifications.atRisk"
        static let atRiskMinutes = "notifications.atRiskMinutes"
        static let lastCall = "notifications.lastCall"
        static let extended = "notifications.extended"
        static let record = "notifications.record"
        static let milestones = "notifications.milestones"
        static let streakLost = "notifications.streakLost"
        static let weeklyRecap = "notifications.weeklyRecap"
    }

    static func load(from defaults: UserDefaults = .standard) -> StreakNotificationSettings {
        var s = StreakNotificationSettings()
        func flag(_ key: String, _ fallback: Bool) -> Bool {
            defaults.object(forKey: key) == nil ? fallback : defaults.bool(forKey: key)
        }
        s.enabled = flag(Key.enabled, s.enabled)
        s.atRisk = flag(Key.atRisk, s.atRisk)
        s.lastCall = flag(Key.lastCall, s.lastCall)
        s.extended = flag(Key.extended, s.extended)
        s.record = flag(Key.record, s.record)
        s.milestones = flag(Key.milestones, s.milestones)
        s.streakLost = flag(Key.streakLost, s.streakLost)
        s.weeklyRecap = flag(Key.weeklyRecap, s.weeklyRecap)
        if defaults.object(forKey: Key.atRiskMinutes) != nil {
            s.atRiskMinutes = min(max(defaults.integer(forKey: Key.atRiskMinutes), 0), 23 * 60 + 59)
        }
        return s
    }
}
