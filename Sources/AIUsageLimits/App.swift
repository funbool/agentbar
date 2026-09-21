import SwiftUI

@main
struct AIUsageLimitsApp: App {
    @State private var store: UsageStore
    private let settings: Settings
    private let notifier: Notifier

    init() {
        DebugDump.runIfRequested()
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
    }

    var body: some Scene {
        MenuBarExtra("AI Usage Limits", systemImage: "gauge.with.dots.needle.33percent") {
            PanelView()
                .environment(store)
                .id(settings.language) // re-render all localized text when the language changes
        }
        .menuBarExtraStyle(.window)

        Window(L("settings.title"), id: "settings") {
            SettingsView(notifier: notifier)
                .environment(store)
                .id(settings.language)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
