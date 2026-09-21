import Foundation
import Observation

@MainActor
@Observable
final class StatsStore {
    struct State {
        var records: [UsageRecord] = []
        var loading = false
        var progress: (done: Int, total: Int)?
        var error: String?
        var loadedAt: Date?
    }

    var selectedProvider: Provider = .claude
    var period: StatsPeriod = .month
    private(set) var states: [Provider: State] = [:]
    private var reportCache: [String: StatsReport] = [:]

    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var cursorHistoryMode: CursorStatsSource.HistoryMode? {
        get { defaults.string(forKey: "cursorHistoryMode").flatMap(CursorStatsSource.HistoryMode.init(rawValue:)) }
        set { defaults.set(newValue?.rawValue, forKey: "cursorHistoryMode") }
    }

    func state(_ p: Provider) -> State { states[p] ?? State() }

    func report(for provider: Provider) -> StatsReport {
        let key = "\(provider.rawValue)|\(period.rawValue)|\(state(provider).loadedAt?.timeIntervalSince1970 ?? 0)"
        if let cached = reportCache[key] { return cached }
        let r = StatsAggregator.report(state(provider).records, period: period) { Pricing.cost($0, provider: provider) }
        reportCache[key] = r
        return r
    }

    /// Loads (or refreshes) one provider. Local scans run off the main thread; Cursor goes to the network.
    func load(_ provider: Provider) {
        guard !state(provider).loading else { return }
        if provider == .cursor, cursorHistoryMode == nil { return } // wait for the user's history choice
        states[provider, default: State()].loading = true
        states[provider]?.error = nil
        states[provider]?.progress = nil
        Task { [weak self] in
            do {
                let records = try await self?.fetch(provider) ?? []
                self?.states[provider, default: State()].records = records
                self?.states[provider]?.loadedAt = Date()
            } catch {
                self?.states[provider]?.error = (error as? ProviderError).map(Self.describe) ?? error.localizedDescription
            }
            self?.states[provider]?.loading = false
            self?.states[provider]?.progress = nil
        }
    }

    private func fetch(_ provider: Provider) async throws -> [UsageRecord] {
        let report: @Sendable (Int, Int) -> Void = { [weak self] done, total in
            Task { @MainActor in self?.states[provider]?.progress = (done, total) }
        }
        switch provider {
        case .claude:
            return await Task.detached(priority: .userInitiated) { ClaudeStatsSource.load(progress: report) }.value
        case .codex:
            return await Task.detached(priority: .userInitiated) { CodexStatsSource.load(progress: report) }.value
        case .cursor:
            let mode = cursorHistoryMode ?? .currentCycle
            let cycleStart = mode == .currentCycle ? await CursorProvider.billingCycleStart() : nil
            return try await CursorStatsSource.refresh(mode: mode, cycleStart: cycleStart, progress: report)
        }
    }

    private static func describe(_ e: ProviderError) -> String {
        switch e {
        case .notLoggedIn: L("error.notLoggedIn")
        case .tokenExpired: L("error.tokenExpired")
        case .rateLimited: L("error.rateLimited")
        case .network: L("error.network")
        case .badResponse: L("error.badResponse")
        }
    }
}
