import Foundation
import UserNotifications

/// Fires one local notification per rate-limit window per reset cycle once usage crosses the threshold.
@MainActor
final class Notifier {
    private let defaults: UserDefaults
    private let sentKey = "notifier.sent"
    /// Notifications need a real .app bundle; running the bare binary (tests, --dump) would crash UNUserNotificationCenter.
    private let available = Bundle.main.bundleIdentifier != nil

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func requestAuthorization() {
        guard available else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func authorizationDenied() async -> Bool {
        guard available else { return false }
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .denied
    }

    /// Pure decision logic, separated for testing: which windows need a notification right now.
    nonisolated static func dueWindows(
        snapshots: [ProviderSnapshot],
        threshold: Int,
        alreadySent: Set<String>
    ) -> [(ProviderSnapshot, UsageWindow, key: String)] {
        var due: [(ProviderSnapshot, UsageWindow, key: String)] = []
        for snap in snapshots {
            for window in snap.windows where window.usedPercent >= Double(threshold) {
                let key = dedupeKey(snap.provider, window)
                if !alreadySent.contains(key) { due.append((snap, window, key: key)) }
            }
        }
        return due
    }

    nonisolated static func dedupeKey(_ provider: Provider, _ window: UsageWindow) -> String {
        let reset = window.resetsAt.map { String(Int($0.timeIntervalSince1970)) } ?? "none"
        return "\(provider.rawValue)|\(window.id)|\(reset)"
    }

    func check(snapshots: [ProviderSnapshot], threshold: Int) {
        var sent = Set(defaults.stringArray(forKey: sentKey) ?? [])
        let due = Self.dueWindows(snapshots: snapshots, threshold: threshold, alreadySent: sent)
        guard !due.isEmpty else { return }
        for (snap, window, key) in due {
            sent.insert(key)
            post(provider: snap.provider, window: window)
        }
        // Keep only keys for windows still present so the list doesn't grow forever.
        let live = Set(snapshots.flatMap { s in s.windows.map { Self.dedupeKey(s.provider, $0) } })
        defaults.set(Array(sent.intersection(live).union(due.map(\.key))), forKey: sentKey)
    }

    private func post(provider: Provider, window: UsageWindow) {
        guard available else { return }
        let content = UNMutableNotificationContent()
        content.title = String(
            format: L("notification.title"),
            provider.displayName, window.title, Formatters.percent(window.usedPercent))
        if let reset = window.resetsAt, let remaining = Formatters.remaining(until: reset) {
            content.body = String(format: L("notification.body"), remaining)
        } else {
            content.body = L("notification.bodyNoReset")
        }
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
