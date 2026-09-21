import SwiftUI

struct PanelView: View {
    @Environment(UsageStore.self) private var store
    @Environment(\.openWindow) private var openWindow
    @State private var now = Date()

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
            Divider()
            footer
        }
        .padding(14)
        .frame(width: 320)
        .onAppear {
            now = Date()
            Task { await store.refreshAll() }
        }
        .onReceive(clock) { now = $0 }
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
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
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
