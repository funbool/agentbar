import Foundation

enum Provider: String, CaseIterable, Codable, Identifiable, Sendable {
    case claude, codex, cursor

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claude: "Claude"
        case .codex: "Codex"
        case .cursor: "Cursor"
        }
    }

    /// Name of the client the user should open to re-authenticate.
    var clientName: String {
        switch self {
        case .claude: "Claude Code"
        case .codex: "Codex"
        case .cursor: "Cursor"
        }
    }
}

/// How usage compares with the even-pace mark.
enum PaceState: Sendable {
    /// Using the limit slower than the clock — it will outlast the window.
    case ahead
    /// Within the tolerance band around the pace mark.
    case onPace
    /// Burning the limit faster than the clock — it will run out before the reset.
    case behind
}

/// One rate-limit window (e.g. Claude 5h, Codex weekly, a Cursor included pool).
struct UsageWindow: Equatable, Identifiable, Sendable {
    enum Kind: String, Sendable {
        case fiveHour, weekly, weeklyOpus, weeklySonnet
        /// Weekly window scoped to one model (e.g. "Fable"); `label` carries the model name.
        case weeklyScoped
        /// Cursor: included pool for Cursor's own models (Auto / Composer / Grok).
        case cursorModels
        /// Cursor: included pool for third-party (API) models.
        case apiModels
        /// Cursor: on-demand spending on top of the plan.
        case onDemand
        /// Cursor: Grok Bot weekly included usage.
        case grok
    }

    let kind: Kind
    /// Model/feature name for kinds whose title depends on data (weeklyScoped).
    let label: String?
    /// 0...100
    let usedPercent: Double
    let resetsAt: Date?
    /// Length of the whole window; with `resetsAt` it gives the window's start.
    let windowSeconds: TimeInterval?
    /// Extra text such as "$12.30 / $20.00".
    let detail: String?

    var id: String { label.map { "\(kind.rawValue)-\($0)" } ?? kind.rawValue }

    init(
        kind: Kind,
        label: String? = nil,
        usedPercent: Double,
        resetsAt: Date? = nil,
        windowSeconds: TimeInterval? = nil,
        detail: String? = nil
    ) {
        self.kind = kind
        self.label = label
        self.usedPercent = min(max(usedPercent, 0), 100)
        self.resetsAt = resetsAt
        self.windowSeconds = windowSeconds
        self.detail = detail
    }

    /// Share of the window already elapsed, 0...100 — the "even pace" mark: spending exactly this much
    /// of the limit makes it last until the reset. Nil when the window's span is unknown.
    func pacePercent(now: Date = Date()) -> Double? {
        guard let resetsAt, let windowSeconds, windowSeconds > 0 else { return nil }
        let start = resetsAt.addingTimeInterval(-windowSeconds)
        let elapsed = now.timeIntervalSince(start) / windowSeconds
        return min(max(elapsed * 100, 0), 100)
    }

    /// Usage compared with the even pace. Nil when there is no pace to compare against.
    func paceState(now: Date = Date(), tolerance: Double = UsageWindow.paceTolerance) -> PaceState? {
        guard let pace = pacePercent(now: now) else { return nil }
        // Right after a reset the pace sits near zero and any usage would read as "behind";
        // that is noise rather than a signal, so the comparison starts once the window is under way.
        guard pace >= UsageWindow.paceGracePercent else { return nil }
        if usedPercent > pace + tolerance { return .behind }
        if usedPercent < pace - tolerance { return .ahead }
        return .onPace
    }

    /// Half-width of the "on pace" band, in percentage points.
    static let paceTolerance: Double = 1
    /// Pace colouring only kicks in once this share of the window has elapsed.
    static let paceGracePercent: Double = 5

    /// Localized row title.
    var title: String {
        let base = L("window.\(kind.rawValue)")
        return label.map { String(format: base, $0) } ?? base
    }
}

enum ProviderError: Error, Equatable, Sendable {
    case notLoggedIn
    case tokenExpired
    case rateLimited
    case network(String)
    case badResponse(String)
}

struct ProviderSnapshot: Equatable, Sendable {
    let provider: Provider
    let windows: [UsageWindow]
    let plan: String?
    /// Secondary header text, e.g. money spent this cycle.
    let summary: String?
    let fetchedAt: Date

    init(provider: Provider, windows: [UsageWindow], plan: String? = nil, summary: String? = nil, fetchedAt: Date = Date()) {
        self.provider = provider
        self.windows = windows
        self.plan = plan
        self.summary = summary
        self.fetchedAt = fetchedAt
    }
}
