import SwiftUI

@main
struct AgentBarApp: App {
    @State private var store: UsageStore
    @State private var stats = StatsStore()
    @State private var updater = Updater()
    private let settings: Settings
    private let notifier: Notifier

    init() {
        DebugDump.runIfRequested()
        LegacyMigration.run()
        let settings = Settings()
        let notifier = Notifier()
        L10n.language = settings.language
        self.settings = settings
        self.notifier = notifier
        let store = UsageStore(settings: settings, notifier: notifier)
        _store = State(initialValue: store)

        // Re-register on every launch so the login item follows the bundle if it is moved (build/ -> /Applications).
        if settings.launchAtLoginWanted { LaunchAtLogin.set(true) }
        store.applySchedule()
        Task { await store.refreshAll() }
        updater.scheduleChecks()
    }

    var body: some Scene {
        MenuBarExtra("AgentBar", systemImage: "gauge.with.dots.needle.33percent") {
            PanelView()
                .environment(store)
                .environment(stats)
                .environment(updater)
                .id(settings.language) // re-render all localized text when the language changes
        }
        .menuBarExtraStyle(.window)

        Window(L("settings.title"), id: "settings") {
            SettingsView(notifier: notifier)
                .environment(store)
                .environment(updater)
                .id(settings.language)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Window(L("stats.title"), id: "stats") {
            StatsView()
                .environment(stats)
                .id(settings.language)
        }
        .defaultPosition(.center)
    }
}
