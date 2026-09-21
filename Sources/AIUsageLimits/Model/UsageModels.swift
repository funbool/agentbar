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

/// One rate-limit window (e.g. Claude 5h, Codex weekly, Cursor monthly plan).
struct UsageWindow: Equatable, Identifiable, Sendable {
    enum Kind: String, Sendable {
        case fiveHour, weekly, weeklyOpus, weeklySonnet
        /// Weekly window scoped to one model (e.g. "Fable"); `label` carries the model name.
        case weeklyScoped
        case monthly, onDemand
        /// Cursor: Auto + Composer share of the included plan.
        case autoComposer
        /// Cursor: named (API) models share of the included plan.
        case apiModels
        /// Cursor: Grok Bot weekly included usage.
        case grok
    }

    let kind: Kind
    /// Model/feature name for kinds whose title depends on data (weeklyScoped).
    let label: String?
    /// 0...100
    let usedPercent: Double
    let resetsAt: Date?
    /// Extra text such as "$12.30 / $20.00".
    let detail: String?

    var id: String { label.map { "\(kind.rawValue)-\($0)" } ?? kind.rawValue }

    init(kind: Kind, label: String? = nil, usedPercent: Double, resetsAt: Date? = nil, detail: String? = nil) {
        self.kind = kind
        self.label = label
        self.usedPercent = min(max(usedPercent, 0), 100)
        self.resetsAt = resetsAt
        self.detail = detail
    }

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
    let fetchedAt: Date

    init(provider: Provider, windows: [UsageWindow], plan: String? = nil, fetchedAt: Date = Date()) {
        self.provider = provider
        self.windows = windows
        self.plan = plan
        self.fetchedAt = fetchedAt
    }
}
