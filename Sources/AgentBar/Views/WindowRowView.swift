import SwiftUI

struct WindowRowView: View {
    let window: UsageWindow
    let provider: Provider
    let settings: Settings
    let now: Date
    @State private var showRule = false

    private var threshold: Int { settings.effectiveThreshold(for: provider, window) }
    private var rule: NotificationRule { settings.rule(for: provider, window) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(window.title)
                    .font(.callout)
                Button { showRule.toggle() } label: {
                    Image(systemName: rule.enabled && settings.notificationsEnabled ? "bell.fill" : "bell.slash")
                        .font(.caption2)
                        .foregroundStyle(rule.enabled && settings.notificationsEnabled ? Color.accentColor : Color.secondary.opacity(0.45))
                }
                .buttonStyle(.borderless)
                .help(L("panel.rule.help"))
                .popover(isPresented: $showRule, arrowEdge: .bottom) { rulePopover }
                Spacer()
                if let detail = window.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(Formatters.percent(window.usedPercent))
                    .font(.callout.monospacedDigit().weight(.medium))
                    .frame(minWidth: 40, alignment: .trailing)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.1))
                    Capsule()
                        .fill(barColor)
                        .frame(width: max(4, geo.size.width * window.usedPercent / 100))
                }
            }
            .frame(height: 6)
            Text(resetText)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    /// Quick per-limit notification settings, reachable without opening Settings.
    private var rulePopover: some View {
        @Bindable var settings = settings
        return VStack(alignment: .leading, spacing: 10) {
            Text("\(provider.displayName) · \(window.title)").font(.headline)
            Toggle(L("settings.notifications.enabled"), isOn: $settings.notificationsEnabled)
            Toggle(L("panel.rule.notifyThis"), isOn: Binding(
                get: { rule.enabled },
                set: { settings.setRule(NotificationRule(enabled: $0, threshold: rule.threshold), for: provider, window) }))
                .disabled(!settings.notificationsEnabled)
            HStack {
                Text(L("settings.notifications.threshold"))
                Spacer()
                Picker("", selection: Binding(
                    get: { rule.threshold ?? 0 },
                    set: { settings.setRule(NotificationRule(enabled: rule.enabled, threshold: $0 == 0 ? nil : $0), for: provider, window) })) {
                    Text(String(format: L("settings.notifications.defaultThreshold"), settings.notificationThreshold)).tag(0)
                    ForEach(Settings.notificationThresholds, id: \.self) { Text("\($0)%").tag($0) }
                }
                .labelsHidden().fixedSize()
                .disabled(!settings.notificationsEnabled || !rule.enabled)
            }
            Text(String(format: L("panel.rule.current"), Formatters.percent(window.usedPercent), threshold))
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: 300)
    }

    private var barColor: Color {
        if window.usedPercent >= Double(threshold) { return .red }
        if window.usedPercent >= 60 { return .yellow }
        return .green
    }

    private var resetText: String {
        guard let reset = window.resetsAt else { return " " }
        let absolute = Formatters.dateTime(reset, locale: L10n.locale, now: now)
        if let remaining = Formatters.remaining(until: reset, now: now) {
            return String(format: L("window.resetsIn"), remaining) + " · " + absolute
        }
        return L("window.ready")
    }
}
