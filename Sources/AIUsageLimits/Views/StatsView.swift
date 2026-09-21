import SwiftUI
import Charts

struct StatsView: View {
    @Environment(StatsStore.self) private var stats

    var body: some View {
        @Bindable var stats = stats
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                content
                    .padding(16)
            }
        }
        .frame(minWidth: 640, idealWidth: 720, minHeight: 520, idealHeight: 680)
        .onAppear { stats.load(stats.selectedProvider) }
        .onChange(of: stats.selectedProvider) { _, p in stats.load(p) }
    }

    private var header: some View {
        @Bindable var stats = stats
        return HStack(spacing: 12) {
            Picker("", selection: $stats.selectedProvider) {
                ForEach(Provider.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 240)
            Picker("", selection: $stats.period) {
                ForEach(StatsPeriod.allCases) { Text(L("stats.period.\($0.rawValue)")).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 280)
            Spacer()
            status
            Button { stats.load(stats.selectedProvider) } label: { Image(systemName: "arrow.clockwise") }
                .disabled(stats.state(stats.selectedProvider).loading)
                .help(L("panel.refresh"))
        }
        .padding(12)
    }

    @ViewBuilder private var status: some View {
        let st = stats.state(stats.selectedProvider)
        if st.loading {
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                if let p = st.progress, p.total > 0 {
                    Text("\(p.done)/\(p.total)").font(.caption).foregroundStyle(.secondary).monospacedDigit()
                } else {
                    Text(L("stats.indexing")).font(.caption).foregroundStyle(.secondary)
                }
            }
        } else if let at = st.loadedAt {
            Text(String(format: L("panel.updated"), Formatters.time(at, locale: L10n.locale)))
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var content: some View {
        let provider = stats.selectedProvider
        let st = stats.state(provider)
        if provider == .cursor, stats.cursorHistoryMode == nil {
            cursorHistoryChoice
        } else if let error = st.error {
            Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
        } else if st.loadedAt == nil {
            Text(L("stats.indexing")).foregroundStyle(.secondary)
        } else {
            let report = stats.report(for: provider)
            VStack(alignment: .leading, spacing: 18) {
                tiles(report, provider: provider)
                if report.byDay.count > 1 { dailyChart(report) }
                modelTable(report)
                if !report.byProject.isEmpty { projectTable(report, provider: provider) }
                footnote(provider: provider, report: report)
            }
        }
    }

    // MARK: Cursor first-run choice

    private var cursorHistoryChoice: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("stats.cursor.choiceTitle")).font(.headline)
            Text(L("stats.cursor.choiceBody")).font(.callout).foregroundStyle(.secondary)
            HStack {
                Button(L("stats.cursor.loadAll")) { choose(.all) }.buttonStyle(.borderedProminent)
                Button(L("stats.cursor.loadCycle")) { choose(.currentCycle) }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.05)))
    }

    private func choose(_ mode: CursorStatsSource.HistoryMode) {
        stats.cursorHistoryMode = mode
        stats.load(.cursor)
    }

    // MARK: Sections

    private func tiles(_ r: StatsReport, provider: Provider) -> some View {
        let costTitle = provider == .cursor ? L("stats.cost.reported") : L("stats.cost.api")
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
            tile(costTitle, Formatters.usdPrecise(r.totals.costUSD), accent: true)
            tile(L("stats.tokens.total"), Formatters.compact(r.totals.total))
            tile(L("stats.calls"), Formatters.compact(r.totals.calls))
            tile(provider == .cursor ? L("stats.conversations") : L("stats.sessions"), Formatters.compact(r.sessions))
            tile(L("stats.tokens.input"), Formatters.compact(r.totals.input))
            tile(L("stats.tokens.output"), Formatters.compact(r.totals.output))
            tile(L("stats.tokens.cacheWrite"), Formatters.compact(r.totals.cacheWrite))
            tile(L("stats.tokens.cacheRead"), Formatters.compact(r.totals.cacheRead))
        }
    }

    private func tile(_ title: String, _ value: String, accent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            Text(value).font(.title3.weight(.semibold).monospacedDigit()).foregroundStyle(accent ? Color.accentColor : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.05)))
    }

    private func dailyChart(_ r: StatsReport) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L("stats.daily")).font(.headline)
            Chart(r.byDay) { day in
                BarMark(x: .value("day", day.day, unit: .day), y: .value("usd", day.costUSD))
                    .foregroundStyle(Color.accentColor)
            }
            .chartYAxis { AxisMarks(position: .leading) { v in
                AxisGridLine(); AxisValueLabel { if let d = v.as(Double.self) { Text(Formatters.usdPrecise(d)) } }
            } }
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 8)) { _ in AxisGridLine(); AxisValueLabel(format: .dateTime.day().month(.abbreviated)) } }
            .frame(height: 160)
        }
    }

    private func modelTable(_ r: StatsReport) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L("stats.byModel")).font(.headline)
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 4) {
                GridRow {
                    Text(L("stats.col.model")).gridColumnAlignment(.leading)
                    Text(L("stats.calls")).gridColumnAlignment(.trailing)
                    Text(L("stats.tokens.input")).gridColumnAlignment(.trailing)
                    Text(L("stats.tokens.output")).gridColumnAlignment(.trailing)
                    Text(L("stats.tokens.cacheWrite")).gridColumnAlignment(.trailing)
                    Text(L("stats.tokens.cacheRead")).gridColumnAlignment(.trailing)
                    Text(L("stats.col.cost")).gridColumnAlignment(.trailing)
                }
                .font(.caption).foregroundStyle(.secondary)
                Divider()
                ForEach(r.byModel) { m in
                    GridRow {
                        Text(m.model).lineLimit(1)
                        Text(Formatters.compact(m.totals.calls))
                        Text(Formatters.compact(m.totals.input))
                        Text(Formatters.compact(m.totals.output))
                        Text(Formatters.compact(m.totals.cacheWrite))
                        Text(Formatters.compact(m.totals.cacheRead))
                        Text(m.totals.unpricedTokens > 0 && m.totals.costUSD == 0 ? "—" : Formatters.usdPrecise(m.totals.costUSD))
                    }
                    .font(.callout.monospacedDigit())
                }
            }
        }
    }

    private func projectTable(_ r: StatsReport, provider: Provider) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(provider == .cursor ? L("stats.byKind") : L("stats.byProject")).font(.headline)
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 4) {
                ForEach(r.byProject.prefix(10)) { p in
                    GridRow {
                        Text(provider == .cursor ? p.project : (p.project as NSString).lastPathComponent)
                            .lineLimit(1).help(p.project).gridColumnAlignment(.leading)
                        Text(Formatters.compact(p.totals.calls)).gridColumnAlignment(.trailing)
                        Text(Formatters.compact(p.totals.total)).gridColumnAlignment(.trailing)
                        Text(Formatters.usdPrecise(p.totals.costUSD)).gridColumnAlignment(.trailing)
                    }
                    .font(.callout.monospacedDigit())
                }
            }
        }
    }

    private func footnote(provider: Provider, report r: StatsReport) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if provider == .claude { Text(L("stats.note.claude")) }
            if provider == .codex { Text(L("stats.note.codex")) }
            if provider == .cursor { Text(L("stats.note.cursor")) }
            if r.totals.unpricedTokens > 0 {
                Text(String(format: L("stats.note.unpriced"), Formatters.compact(r.totals.unpricedTokens)))
            }
            if provider == .claude, r.toolCalls > 0 {
                Text(String(format: L("stats.note.toolCalls"), Formatters.compact(r.toolCalls)))
            }
            if let first = r.firstDate, let last = r.lastDate {
                Text(String(format: L("stats.note.range"),
                            Formatters.shortDate(first, locale: L10n.locale), Formatters.shortDate(last, locale: L10n.locale)))
            }
        }
        .font(.caption).foregroundStyle(.secondary)
    }
}
