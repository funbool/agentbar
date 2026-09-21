import SwiftUI

struct SettingsView: View {
    @Environment(UsageStore.self) private var store
    @Environment(Updater.self) private var updater
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var notificationsDenied = false
    let notifier: Notifier

    var body: some View {
        TabView {
            general.tabItem { Label(L("settings.tab.general"), systemImage: "gearshape") }
            notifications.tabItem { Label(L("settings.tab.notifications"), systemImage: "bell") }
        }
        .frame(width: 560, height: 520)
        .background(WindowAccessor { DockPresence.track($0) })
        .navigationTitle(L("settings.title"))
        .task { notificationsDenied = await notifier.authorizationDenied() }
    }

    private var general: some View {
        @Bindable var settings = store.settings
        return Form {
            Section(L("settings.refresh")) {
                Picker(L("settings.refresh"), selection: $settings.refreshInterval) {
                    ForEach(RefreshInterval.allCases) { interval in
                        Text(intervalLabel(interval)).tag(interval)
                    }
                }
                .labelsHidden()
                .onChange(of: settings.refreshInterval) { store.applySchedule() }
            }

            Section(L("settings.providers")) {
                ForEach(Provider.allCases) { provider in
                    Toggle(provider.displayName, isOn: Binding(
                        get: { settings.isEnabled(provider) },
                        set: { settings.setEnabled(provider, $0) }))
                }
            }

            Section {
                Picker(L("settings.language"), selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(L("settings.language.\(lang.rawValue)")).tag(lang)
                    }
                }
                .onChange(of: settings.language) { _, lang in L10n.language = lang }
                Toggle(L("settings.launchAtLogin"), isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, on in
                        settings.launchAtLoginWanted = on
                        LaunchAtLogin.set(on)
                        launchAtLogin = LaunchAtLogin.isEnabled
                    }
            }

            Section(L("settings.updates")) {
                updatesSection
            }
        }
        .formStyle(.grouped)
    }

    private var updatesSection: some View {
        @Bindable var updater = updater
        return Group {
            HStack {
                Text(String(format: L("settings.updates.version"), updater.currentVersion))
                Spacer()
                if updater.phase == .checking {
                    ProgressView().controlSize(.small)
                } else {
                    Button(L("settings.updates.check")) { Task { await updater.check() } }
                        .disabled(updater.phase.isBusy)
                }
            }
            Toggle(L("settings.updates.auto"), isOn: $updater.automaticChecks)
            if let rel = updater.available {
                HStack {
                    Text(String(format: L("update.available"), rel.version)).foregroundStyle(Color.accentColor)
                    Spacer()
                    Button(L("update.install")) { Task { await updater.installAvailable() } }
                        .buttonStyle(.borderedProminent).controlSize(.small).disabled(updater.phase.isBusy)
                }
            } else if let last = updater.lastCheck, updater.phase == .idle {
                Text(String(format: L("settings.updates.upToDate"), Formatters.dateTime(last, locale: L10n.locale)))
                    .font(.caption).foregroundStyle(.secondary)
            }
            if case .failed(let msg) = updater.phase {
                Text(msg).font(.caption).foregroundStyle(.orange)
            }
        }
    }

    private var notifications: some View {
        @Bindable var settings = store.settings
        return Form {
            Section(L("settings.notifications")) {
                Toggle(L("settings.notifications.enabled"), isOn: $settings.notificationsEnabled)
                    .onChange(of: settings.notificationsEnabled) { _, on in
                        if on { notifier.requestAuthorization() }
                        Task { notificationsDenied = await notifier.authorizationDenied() }
                    }
                Picker(L("settings.notifications.threshold"), selection: $settings.notificationThreshold) {
                    ForEach(Settings.notificationThresholds, id: \.self) { Text("\($0)%").tag($0) }
                }
                .disabled(!settings.notificationsEnabled)
                if notificationsDenied && settings.notificationsEnabled {
                    Text(L("settings.notifications.denied")).font(.caption).foregroundStyle(.orange)
                }
                if settings.refreshInterval == .off && settings.notificationsEnabled {
                    Text(L("settings.notifications.hint")).font(.caption).foregroundStyle(.secondary)
                }
            }

            Section(L("settings.notifications.perLimit")) {
                Text(L("settings.notifications.perLimitHint")).font(.caption).foregroundStyle(.secondary)
                ForEach(store.visibleProviders) { provider in
                    Text(provider.displayName).font(.headline).padding(.top, 4)
                    ForEach(knownWindows(for: provider)) { window in
                        ruleRow(provider: provider, window: window, settings: settings)
                    }
                }
            }
            .disabled(!settings.notificationsEnabled)
        }
        .formStyle(.grouped)
    }

    /// Windows the user can configure: whatever the last fetch returned, plus the always-present ones
    /// so the list is complete before the first refresh.
    private func knownWindows(for provider: Provider) -> [UsageWindow] {
        let staticKinds: [UsageWindow.Kind] = switch provider {
        case .claude, .codex: [.fiveHour, .weekly]
        case .cursor: [.cursorModels, .apiModels, .onDemand, .grok]
        }
        var windows = store.snapshots[provider]?.windows ?? []
        for kind in staticKinds where !windows.contains(where: { $0.kind == kind }) {
            windows.append(UsageWindow(kind: kind, usedPercent: 0))
        }
        return windows
    }

    private func ruleRow(provider: Provider, window: UsageWindow, settings: Settings) -> some View {
        let rule = settings.rule(for: provider, window)
        return HStack {
            Toggle(window.title, isOn: Binding(
                get: { rule.enabled },
                set: { settings.setRule(NotificationRule(enabled: $0, threshold: rule.threshold), for: provider, window) }))
            Spacer()
            Picker("", selection: Binding(
                get: { rule.threshold ?? 0 },
                set: { settings.setRule(NotificationRule(enabled: rule.enabled, threshold: $0 == 0 ? nil : $0), for: provider, window) })) {
                Text(String(format: L("settings.notifications.defaultThreshold"), settings.notificationThreshold)).tag(0)
                ForEach(Settings.notificationThresholds, id: \.self) { Text("\($0)%").tag($0) }
            }
            .labelsHidden()
            .fixedSize()
            .disabled(!rule.enabled)
        }
    }

    private func intervalLabel(_ interval: RefreshInterval) -> String {
        interval == .off ? L("settings.refresh.off") : String(format: L("settings.refresh.every"), interval.rawValue)
    }
}
