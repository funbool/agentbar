import Foundation
import Observation

enum RefreshInterval: Int, CaseIterable, Identifiable {
    case off = 0, one = 1, five = 5, fifteen = 15, thirty = 30, sixty = 60
    var id: Int { rawValue }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system, en, ru
    var id: String { rawValue }
}

/// User preferences backed by UserDefaults. Observable so views and the store react to changes.
@MainActor
@Observable
final class Settings {
    static let notificationThresholds = [50, 75, 80, 90, 95]

    private let defaults: UserDefaults

    var refreshInterval: RefreshInterval {
        didSet { defaults.set(refreshInterval.rawValue, forKey: "refreshIntervalMinutes") }
    }
    var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }
    var notificationThreshold: Int {
        didSet { defaults.set(notificationThreshold, forKey: "notificationThreshold") }
    }
    var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: "language") }
    }
    private(set) var enabledProviders: Set<Provider> {
        didSet { defaults.set(enabledProviders.map(\.rawValue).sorted(), forKey: "enabledProviders") }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let interval = defaults.object(forKey: "refreshIntervalMinutes") as? Int
        refreshInterval = interval.flatMap(RefreshInterval.init(rawValue:)) ?? .five
        notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        notificationThreshold = defaults.object(forKey: "notificationThreshold") as? Int ?? 80
        language = AppLanguage(rawValue: defaults.string(forKey: "language") ?? "") ?? .system
        if let stored = defaults.stringArray(forKey: "enabledProviders") {
            enabledProviders = Set(stored.compactMap(Provider.init(rawValue:)))
        } else {
            enabledProviders = Set(Provider.allCases)
        }
    }

    func isEnabled(_ provider: Provider) -> Bool { enabledProviders.contains(provider) }

    func setEnabled(_ provider: Provider, _ enabled: Bool) {
        if enabled { enabledProviders.insert(provider) } else { enabledProviders.remove(provider) }
    }

    /// Whether the user wants the app registered as a login item (default: yes).
    var launchAtLoginWanted: Bool {
        get { defaults.object(forKey: "launchAtLoginWanted") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "launchAtLoginWanted") }
    }
}
