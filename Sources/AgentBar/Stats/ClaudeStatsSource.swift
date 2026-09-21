import Foundation

/// Reads token usage from Claude Code transcripts (`~/.claude/projects/**/*.jsonl`).
enum ClaudeStatsSource {
    static let cacheName = "claude-stats-cache.json"

    static var roots: [URL] {
        var dirs = [URL(fileURLWithPath: NSHomeDirectory() + "/.claude/projects")]
        if let custom = ProcessInfo.processInfo.environment["CLAUDE_CONFIG_DIR"], !custom.isEmpty {
            dirs.append(URL(fileURLWithPath: custom + "/projects"))
        }
        dirs.append(URL(fileURLWithPath: NSHomeDirectory() + "/.config/claude/projects"))
        return dirs.filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    static func load(progress: ((Int, Int) -> Void)? = nil) -> [UsageRecord] {
        var cache = FileScanCache.load(name: cacheName)
        let files = roots.flatMap(FileScanCache.jsonlFiles(under:))
        let records = cache.scan(files: files, parse: parseFile, progress: progress)
        cache.save(name: cacheName)
        return dedupe(records)
    }

    /// The same assistant message can appear in several transcripts (resumed / forked sessions): keep one copy.
    static func dedupe(_ records: [UsageRecord]) -> [UsageRecord] {
        var seen = Set<String>()
        return records.filter { r in
            guard let id = r.id else { return true }
            return seen.insert(id).inserted
        }
    }

    static func parseFile(_ url: URL) -> [UsageRecord] {
        guard let data = FileManager.default.contents(atPath: url.path) else { return [] }
        return parse(data)
    }

    /// Parses transcript lines. One API response is written as several lines (one per content block) that share
    /// `message.id`; early lines may carry a preliminary `output_tokens` (streaming), so every field is the maximum
    /// across the message's lines. Tool calls are summed. `lineCountedTokens` keeps the per-line sum that
    /// Claude Code's own `/stats` reports, for comparison.
    static func parse(_ data: Data) -> [UsageRecord] {
        var byMessage: [String: UsageRecord] = [:]
        var order: [String] = []
        let usageMarker = Data("\"usage\"".utf8)
        func int(_ k: String, in d: [String: Any]) -> Int { (d[k] as? NSNumber)?.intValue ?? 0 }
        for line in data.split(separator: UInt8(ascii: "\n")) {
            guard line.range(of: usageMarker) != nil,
                  let json = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
                  json["type"] as? String == "assistant",
                  let message = json["message"] as? [String: Any],
                  let usage = message["usage"] as? [String: Any],
                  let model = message["model"] as? String, !model.hasPrefix("<"),
                  let ts = Formatters.isoDate(json["timestamp"] as? String)
            else { continue }
            let toolCalls = (message["content"] as? [[String: Any]])?.filter { $0["type"] as? String == "tool_use" }.count ?? 0
            let msgId = (message["id"] as? String) ?? UUID().uuidString
            let key = msgId + "|" + ((json["requestId"] as? String) ?? "")
            let cacheCreation = usage["cache_creation"] as? [String: Any] ?? [:]
            let input = int("input_tokens", in: usage)
            let output = int("output_tokens", in: usage)
            let cacheWrite = int("cache_creation_input_tokens", in: usage)
            let cacheWrite1h = int("ephemeral_1h_input_tokens", in: cacheCreation)
            let cacheRead = int("cache_read_input_tokens", in: usage)
            let lineTokens = input + output + cacheWrite + cacheRead

            if var r = byMessage[key] {
                r.inputTokens = max(r.inputTokens, input)
                r.outputTokens = max(r.outputTokens, output)
                r.cacheWriteTokens = max(r.cacheWriteTokens, cacheWrite)
                r.cacheWrite1hTokens = max(r.cacheWrite1hTokens, cacheWrite1h)
                r.cacheReadTokens = max(r.cacheReadTokens, cacheRead)
                r.toolCalls += toolCalls
                r.lineCountedTokens += lineTokens
                byMessage[key] = r
                continue
            }
            var record = UsageRecord(timestamp: ts, model: model)
            record.inputTokens = input
            record.outputTokens = output
            record.cacheWriteTokens = cacheWrite
            record.cacheWrite1hTokens = cacheWrite1h
            record.cacheReadTokens = cacheRead
            record.project = json["cwd"] as? String
            record.session = json["sessionId"] as? String
            record.toolCalls = toolCalls
            record.lineCountedTokens = lineTokens
            record.id = key
            byMessage[key] = record
            order.append(key)
        }
        return order.compactMap { byMessage[$0] }
    }
}
