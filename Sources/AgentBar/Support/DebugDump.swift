import Foundation

/// `AgentBar --dump` fetches every provider once, prints the result and exits.
/// Handy for verifying endpoints without touching the UI.
enum DebugDump {
    static let allProviders: [any UsageProvider] = [ClaudeProvider(), CodexProvider(), CursorProvider()]

    static func runIfRequested() {
        let args = CommandLine.arguments
        guard args.contains("--dump") || args.contains("--raw") || args.contains("--stats") || args.contains("--cursor-events") || args.contains("--update") else { return }
        if args.contains("--stats") { dumpStats(); exit(0) }
        if args.contains("--update") {
            // Headless end-to-end update: check → download → verify → swap → relaunch.
            let sem = DispatchSemaphore(value: 0)
            Task { @MainActor in
                let updater = Updater()
                print("current \(updater.currentVersion)")
                await updater.check()
                if case .failed(let m) = updater.phase { print("check failed: \(m)") }
                guard let rel = updater.available else { print("no update available"); sem.signal(); return }
                print("available \(rel.version) \(rel.zipURL)")
                await updater.installAvailable()
                if case .failed(let m) = updater.phase { print("install failed: \(m)") }
                sem.signal()
            }
            sem.wait(); exit(0)
        }
        if args.contains("--cursor-events") {
            let sem = DispatchSemaphore(value: 0)
            Task {
                let start = Date()
                do {
                    let records = try await CursorStatsSource.refresh(mode: .all, cycleStart: nil) { d, t in if d % 1000 == 0 { print("  \(d)/\(t)") } }
                    print("[cursor] \(records.count) events in \(String(format: "%.1f", Date().timeIntervalSince(start)))s")
                    for period in StatsPeriod.allCases {
                        let r = StatsAggregator.report(records, period: period) { Pricing.cost($0, provider: .cursor) }
                        print("  \(period.rawValue): $\(String(format: "%.2f", r.totals.costUSD)) tokens=\(r.totals.total) calls=\(r.totals.calls) conv=\(r.sessions)")
                        if period == .all { for m in r.byModel.prefix(6) { print("    \(m.model): $\(String(format: "%.2f", m.totals.costUSD)) calls=\(m.totals.calls)") }; for p in r.byProject { print("    kind \(p.project): $\(String(format: "%.2f", p.totals.costUSD))") } }
                    }
                } catch { print("ERROR \(error)") }
                sem.signal()
            }
            sem.wait(); exit(0)
        }
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            if args.contains("--raw") {
                await dumpRaw()
                semaphore.signal()
                return
            }
            for provider in allProviders {
                do {
                    let snap = try await provider.fetch()
                    print("[\(provider.id.rawValue)] plan=\(snap.plan ?? "-")")
                    for w in snap.windows {
                        let reset = w.resetsAt.map { ISO8601DateFormatter().string(from: $0) } ?? "-"
                        print("  \(w.kind.rawValue): \(Formatters.percent(w.usedPercent)) resets=\(reset) \(w.detail ?? "")")
                    }
                } catch {
                    print("[\(provider.id.rawValue)] ERROR: \(error)")
                }
            }
            semaphore.signal()
        }
        semaphore.wait()
        exit(0)
    }

    /// Scans local logs and prints aggregated stats with timing (first run indexes everything, later runs hit the cache).
    private static func dumpStats() {
        for (name, provider, load) in [
            ("claude", Provider.claude, ClaudeStatsSource.load(progress:)),
            ("codex", Provider.codex, CodexStatsSource.load(progress:)),
        ] {
            let start = Date()
            let records = load { done, total in if done % 500 == 0 || done == total { print("  \(name) \(done)/\(total)") } }
            let elapsed = Date().timeIntervalSince(start)
            print("[\(name)] \(records.count) records in \(String(format: "%.1f", elapsed))s")
            for period in StatsPeriod.allCases {
                let r = StatsAggregator.report(records, period: period) { Pricing.cost($0, provider: provider) }
                print("  \(period.rawValue): $\(String(format: "%.2f", r.totals.costUSD)) tokens=\(r.totals.total) calls=\(r.totals.calls) sessions=\(r.sessions) unpriced=\(r.totals.unpricedTokens)")
                if period == .all { for m in r.byModel { print("    \(m.model): $\(String(format: "%.2f", m.totals.costUSD)) in=\(m.totals.input) out=\(m.totals.output) cw=\(m.totals.cacheWrite) cr=\(m.totals.cacheRead)") } }
            }
        }
    }

    /// Prints the raw JSON bodies of every endpoint (for inspecting new fields).
    private static func dumpRaw() async {
        func show(_ label: String, _ body: () async throws -> Data) async {
            do {
                let data = try await body()
                let obj = try JSONSerialization.jsonObject(with: data)
                let pretty = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
                print("--- \(label)\n" + (String(data: pretty, encoding: .utf8) ?? ""))
            } catch {
                print("--- \(label) ERROR: \(error)")
            }
        }
        await show("claude") { try await ClaudeProvider.rawUsage() }
        await show("codex") { try await CodexProvider.rawUsage() }
        await show("cursor usage-summary") { try await CursorProvider.rawUsageSummary() }
        await show("cursor sand-usage-status") { try await CursorProvider.rawSandUsage() }
        await show("cursor usage-events (page 1, 3 rows)") {
            guard let creds = CursorProvider.loadCredentials() else { throw ProviderError.notLoggedIn }
            let body = try JSONSerialization.data(withJSONObject: ["page": 1, "pageSize": 3])
            return try await HTTP.json(CursorStatsSource.eventsURL, method: "POST", headers: [
                "Cookie": creds.cookieHeader, "Origin": "https://cursor.com", "Referer": "https://cursor.com/dashboard",
            ], body: body)
        }
    }
}
