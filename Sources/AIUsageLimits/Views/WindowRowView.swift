import SwiftUI

struct WindowRowView: View {
    let window: UsageWindow
    let threshold: Int
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(L(window.kind.titleKey))
                    .font(.callout)
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

    private var barColor: Color {
        if window.usedPercent >= Double(threshold) { return .red }
        if window.usedPercent >= 60 { return .yellow }
        return .green
    }

    private var resetText: String {
        guard let reset = window.resetsAt else { return " " }
        switch window.kind {
        case .monthly, .onDemand:
            return String(format: L("window.resetsOn"), Formatters.shortDate(reset, locale: L10n.locale))
        default:
            if let remaining = Formatters.remaining(until: reset, now: now) {
                return String(format: L("window.resetsIn"), remaining)
            }
            return L("window.ready")
        }
    }
}
