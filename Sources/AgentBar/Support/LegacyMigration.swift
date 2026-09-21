import Foundation

/// One-time carry-over of preferences saved under the app's previous bundle identifier.
enum LegacyMigration {
    static let legacyDomain = "dev.vlad.ai-usage-limits"

    static func run(defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: "legacyMigrated") else { return }
        defaults.set(true, forKey: "legacyMigrated")
        guard let legacy = UserDefaults(suiteName: legacyDomain) else { return }
        for (key, value) in legacy.persistentDomain(forName: legacyDomain) ?? [:] where defaults.object(forKey: key) == nil {
            defaults.set(value, forKey: key)
        }
    }
}
