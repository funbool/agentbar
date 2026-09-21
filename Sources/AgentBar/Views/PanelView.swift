import SwiftUI

struct PanelView: View {
    @Environment(UsageStore.self) private var store
    @Environment(StatsStore.self) private var stats
    @Environment(Updater.self) private var updater
    @Environment(\.openWindow) private var openWindow
    @State private var now = Date()
    @State private var panelWindow: NSWindow?

    private let clock = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            let providers = store.visibleProviders
            if providers.isEmpty {
                Text(L("panel.noProviders"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(providers) { provider in
                ProviderSectionView(
                    provider: provider,
                    snapshot: store.snapshots[provider],
                    error: store.errors[provider],
                    settings: store.settings,
                    now: now)
                if provider != providers.last { Divider() }
            }
            if updater.available != nil {
                Divider()
                updateRow
            }
            Divider()
            footer
        }
        .padding(14)
        .frame(width: 320)
        .background(WindowAccessor { panelWindow = $0 })
        .onAppear {
            now = Date()
            Task { await store.refreshAll() }
        }
        .onReceive(clock) { now = $0 }
    }

    /// Opens a regular window and dismisses the menu bar panel so it doesn't linger over it.
    private func open(_ id: String) {
        panelWindow?.close()
        openWindow(id: id)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Shown only when a newer release exists: one click downloads, verifies and relaunches.
    private var updateRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.down.circle.fill").foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: L("update.available"), updater.available?.version ?? "")).font(.callout.weight(.medium))
                switch updater.phase {
                case .downloading(let p):
                    ProgressView(value: p).controlSize(.small)
                case .installing:
                    Text(L("update.installing")).font(.caption).foregroundStyle(.secondary)
                case .failed(let msg):
                    Text(msg).font(.caption).foregroundStyle(.orange).lineLimit(2)
                default:
                    if let url = updater.available?.pageURL {
                        Link(L("update.notes"), destination: url).font(.caption)
                    }
                }
            }
            Spacer()
            Button(L("update.install")) { Task { await updater.installAvailable() } }
                .buttonStyle(.borderedProminent).controlSize(.small)
                .disabled(updater.phase.isBusy)
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            if store.isRefreshing {
                ProgressView().controlSize(.small)
            } else if let last = store.lastRefresh {
                Text(String(format: L("panel.updated"), Formatters.time(last, locale: L10n.locale)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button { Task { await store.refreshAll() } } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help(L("panel.refresh"))
            .disabled(store.isRefreshing)
            Button {
                if let first = store.visibleProviders.first { stats.selectedProvider = first }
                open("stats")
            } label: {
                Image(systemName: "chart.bar.xaxis")
            }
            .help(L("panel.stats"))
            Button {
                open("settings")
            } label: {
                Image(systemName: "gearshape")
            }
            .help(L("panel.settings"))
            Button { NSApp.terminate(nil) } label: {
                Image(systemName: "power")
            }
            .help(L("panel.quit"))
        }
        .buttonStyle(.borderless)
    }
}
