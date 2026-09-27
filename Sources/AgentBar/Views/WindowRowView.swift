import SwiftUI

struct WindowRowView: View {
    let window: UsageWindow
    let provider: Provider
    let settings: Settings
    let now: Date
    private var threshold: Int { settings.effectiveThreshold(for: provider, window) }
    /// The even-pace mark, only in pace mode.
    private var pace: Double? { settings.barColorMode == .pace ? window.pacePercent(now: now) : nil }
    private var notifies: Bool { settings.notificationsEnabled && settings.rule(for: provider, window).enabled }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(window.title)
                    .font(.callout)
                if notifies {
                    // Passive indicator only: notifications are configured in Settings.
                    Image(systemName: "bell.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.accentColor)
                        .help(String(format: L("panel.rule.current"), Formatters.percent(window.usedPercent), threshold))
                }
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
                    if let pace {
                        // Where usage would sit if the limit were spent evenly across the window.
                        Capsule()
                            .fill(Color.primary.opacity(0.65))
                            .frame(width: 2, height: 12)
                            .offset(x: min(max(geo.size.width * pace / 100 - 1, 0), geo.size.width - 2))
                    }
                }
            }
            .frame(height: 6)
            .help(paceHelp)
            Text(resetText)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var barColor: Color {
        // Pace mode falls back to thresholds for windows whose span is unknown or that just reset.
        if settings.barColorMode == .pace, let state = window.paceState(now: now) {
            switch state {
            case .ahead: return .green
            case .onPace: return .yellow
            case .behind: return .red
            }
        }
        if window.usedPercent >= Double(threshold) { return .red }
        if window.usedPercent >= 60 { return .yellow }
        return .green
    }

    private var paceHelp: String {
        guard let pace else { return "" }
        return String(format: L("window.pace"), Formatters.percent(pace))
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
