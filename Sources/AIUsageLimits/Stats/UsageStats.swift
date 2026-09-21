import Foundation

/// One billable model call (Claude assistant message, Codex turn, Cursor request).
struct UsageRecord: Codable, Equatable, Sendable {
    var timestamp: Date
    var model: String
    var inputTokens: Int = 0
    var outputTokens: Int = 0
    var cacheWriteTokens: Int = 0
    /// Claude only: the share of `cacheWriteTokens` written with the 1-hour TTL (priced 2x instead of 1.25x).
    var cacheWrite1hTokens: Int = 0
    var cacheReadTokens: Int = 0
    /// Cost reported by the provider itself (Cursor). Nil means "estimate from the pricing table".
    var reportedCostUSD: Double? = nil
    /// Project / workspace the call belongs to (Claude cwd, Codex cwd). Nil for Cursor.
    var project: String? = nil
    /// Session identifier for counting sessions; nil when the source has none.
    var session: String? = nil
    /// Number of tool calls in this message (Claude).
    var toolCalls: Int = 0
    /// Provider-side identity (Claude message id + request id) used to drop duplicates across files.
    var id: String? = nil

    var totalTokens: Int { inputTokens + outputTokens + cacheWriteTokens + cacheReadTokens }
}

enum StatsPeriod: String, CaseIterable, Identifiable, Sendable {
    case today, week, month, all
    var id: String { rawValue }

    func contains(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        switch self {
        case .today: calendar.isDate(date, inSameDayAs: now)
        case .week: date >= calendar.date(byAdding: .day, value: -7, to: now)!
        case .month: date >= calendar.date(byAdding: .day, value: -30, to: now)!
        case .all: true
        }
    }
}

struct TokenTotals: Equatable, Sendable {
    var input = 0, output = 0, cacheWrite = 0, cacheRead = 0
    var costUSD = 0.0
    /// Tokens whose model has no known price (excluded from `costUSD`).
    var unpricedTokens = 0
    var calls = 0

    var total: Int { input + output + cacheWrite + cacheRead }

    mutating func add(_ r: UsageRecord, cost: Double?) {
        input += r.inputTokens
        output += r.outputTokens
        cacheWrite += r.cacheWriteTokens
        cacheRead += r.cacheReadTokens
        calls += 1
        if let cost { costUSD += cost } else { unpricedTokens += r.totalTokens }
    }
}

struct ModelStat: Identifiable, Equatable, Sendable {
    let model: String
    let totals: TokenTotals
    var id: String { model }
}

struct DayStat: Identifiable, Equatable, Sendable {
    let day: Date
    let costUSD: Double
    let tokens: Int
    var id: Date { day }
}

struct ProjectStat: Identifiable, Equatable, Sendable {
    let project: String
    let totals: TokenTotals
    var id: String { project }
}

struct StatsReport: Equatable, Sendable {
    let period: StatsPeriod
    let totals: TokenTotals
    let byModel: [ModelStat]
    let byDay: [DayStat]
    let byProject: [ProjectStat]
    let sessions: Int
    let toolCalls: Int
    let firstDate: Date?
    let lastDate: Date?

    static let empty = StatsReport(
        period: .all, totals: TokenTotals(), byModel: [], byDay: [], byProject: [],
        sessions: 0, toolCalls: 0, firstDate: nil, lastDate: nil)
}

enum StatsAggregator {
    static func report(
        _ records: [UsageRecord],
        period: StatsPeriod,
        pricing: (UsageRecord) -> Double?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> StatsReport {
        var totals = TokenTotals()
        var models: [String: TokenTotals] = [:]
        var days: [Date: (Double, Int)] = [:]
        var projects: [String: TokenTotals] = [:]
        var sessions = Set<String>()
        var toolCalls = 0
        var first: Date?, last: Date?

        for r in records where period.contains(r.timestamp, now: now, calendar: calendar) {
            let cost = pricing(r)
            totals.add(r, cost: cost)
            models[r.model, default: TokenTotals()].add(r, cost: cost)
            let day = calendar.startOfDay(for: r.timestamp)
            let d = days[day, default: (0, 0)]
            days[day] = (d.0 + (cost ?? 0), d.1 + r.totalTokens)
            if let p = r.project { projects[p, default: TokenTotals()].add(r, cost: cost) }
            if let s = r.session { sessions.insert(s) }
            toolCalls += r.toolCalls
            first = min(first ?? r.timestamp, r.timestamp)
            last = max(last ?? r.timestamp, r.timestamp)
        }
        return StatsReport(
            period: period,
            totals: totals,
            byModel: models.map { ModelStat(model: $0.key, totals: $0.value) }
                .sorted { ($0.totals.costUSD, $0.totals.total) > ($1.totals.costUSD, $1.totals.total) },
            byDay: days.map { DayStat(day: $0.key, costUSD: $0.value.0, tokens: $0.value.1) }.sorted { $0.day < $1.day },
            byProject: projects.map { ProjectStat(project: $0.key, totals: $0.value) }
                .sorted { ($0.totals.costUSD, $0.totals.total) > ($1.totals.costUSD, $1.totals.total) },
            sessions: sessions.count,
            toolCalls: toolCalls,
            firstDate: first,
            lastDate: last)
    }
}
