import Foundation

/// `AIUsageLimits --dump` fetches every provider once, prints the result and exits.
/// Handy for verifying endpoints without touching the UI.
enum DebugDump {
    static let allProviders: [any UsageProvider] = [ClaudeProvider(), CodexProvider(), CursorProvider()]

    static func runIfRequested() {
        let args = CommandLine.arguments
        guard args.contains("--dump") || args.contains("--raw") else { return }
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
    }
}
