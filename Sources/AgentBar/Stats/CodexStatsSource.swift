import Foundation

/// Reads token usage from Codex session rollouts (`~/.codex/sessions/**/*.jsonl`).
enum CodexStatsSource {
    static let cacheName = "codex-stats-cache.json"

    static var roots: [URL] {
        let home = ProcessInfo.processInfo.environment["CODEX_HOME"].flatMap { $0.isEmpty ? nil : $0 }
            ?? NSHomeDirectory() + "/.codex"
        return ["sessions", "archived_sessions"]
            .map { URL(fileURLWithPath: home + "/" + $0) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    static func load(progress: ((Int, Int) -> Void)? = nil) -> [UsageRecord] {
        var cache = FileScanCache.load(name: cacheName)
        let files = roots.flatMap(FileScanCache.jsonlFiles(under:))
        let records = cache.scan(files: files, parse: parseFile, progress: progress)
        cache.save(name: cacheName)
        return records
    }

    static func parseFile(_ url: URL) -> [UsageRecord] {
        guard let data = FileManager.default.contents(atPath: url.path) else { return [] }
        return parse(data)
    }

    /// `token_count` events carry cumulative `total_token_usage`; each record is the delta from the previous
    /// event, which is robust against repeated events that only refresh rate limits.
    static func parse(_ data: Data) -> [UsageRecord] {
        var records: [UsageRecord] = []
        var model = "unknown"
        var session: String?
        var cwd: String?
        var previous: [String: Int] = [:]
        let marker = Data("token_count".utf8)
        let contextMarker = Data("turn_context".utf8)
        let metaMarker = Data("session_meta".utf8)

        func int(_ k: String, in d: [String: Any]) -> Int { (d[k] as? NSNumber)?.intValue ?? 0 }

        for line in data.split(separator: UInt8(ascii: "\n")) {
            let interesting = line.range(of: marker) != nil || line.range(of: contextMarker) != nil || line.range(of: metaMarker) != nil
            guard interesting, let json = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
                  let type = json["type"] as? String,
                  let payload = json["payload"] as? [String: Any] else { continue }
            switch type {
            case "session_meta":
                session = (payload["id"] as? String) ?? (payload["session_id"] as? String)
                cwd = payload["cwd"] as? String
                if let m = payload["model"] as? String { model = m }
            case "turn_context":
                if let m = payload["model"] as? String { model = m }
                if let c = payload["cwd"] as? String { cwd = c }
            case "event_msg":
                guard payload["type"] as? String == "token_count",
                      let info = payload["info"] as? [String: Any],
                      let total = info["total_token_usage"] as? [String: Any],
                      let ts = Formatters.isoDate(json["timestamp"] as? String) else { continue }
                let current = [
                    "input": int("input_tokens", in: total),
                    "cached": int("cached_input_tokens", in: total),
                    "output": int("output_tokens", in: total),
                ]
                // A decrease means the counter was reset (new context); fall back to the per-turn figure.
                let reset = current["input"]! < previous["input", default: 0]
                let last = info["last_token_usage"] as? [String: Any] ?? [:]
                let input = reset ? int("input_tokens", in: last) : current["input"]! - previous["input", default: 0]
                let cached = reset ? int("cached_input_tokens", in: last) : current["cached"]! - previous["cached", default: 0]
                let output = reset ? int("output_tokens", in: last) : current["output"]! - previous["output", default: 0]
                previous = current
                guard input + output > 0 else { continue }
                var r = UsageRecord(timestamp: ts, model: model)
                // OpenAI's input_tokens include the cached share; bill the uncached part at the input rate.
                r.inputTokens = max(0, input - cached)
                r.cacheReadTokens = max(0, cached)
                r.outputTokens = max(0, output)
                r.project = cwd
                r.session = session
                records.append(r)
            default:
                continue
            }
        }
        return records
    }
}
