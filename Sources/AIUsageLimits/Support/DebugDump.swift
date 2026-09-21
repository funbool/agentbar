import Foundation

/// `AIUsageLimits --dump` fetches every provider once, prints the result and exits.
/// Handy for verifying endpoints without touching the UI.
enum DebugDump {
    static let allProviders: [any UsageProvider] = [ClaudeProvider(), CodexProvider(), CursorProvider()]

    static func runIfRequested() {
        guard CommandLine.arguments.contains("--dump") else { return }
        let semaphore = DispatchSemaphore(value: 0)
        Task {
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
}
