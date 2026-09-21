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
    /// `message.id` and `usage`, so usage is counted once per message id and tool calls are summed across lines.
    static func parse(_ data: Data) -> [UsageRecord] {
        var byMessage: [String: UsageRecord] = [:]
        var order: [String] = []
        let usageMarker = Data("\"usage\"".utf8)
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
            if var existing = byMessage[key] {
                existing.toolCalls += toolCalls
                byMessage[key] = existing
                continue
            }
            func int(_ k: String, in d: [String: Any]) -> Int { (d[k] as? NSNumber)?.intValue ?? 0 }
            let cacheCreation = usage["cache_creation"] as? [String: Any] ?? [:]
            var record = UsageRecord(timestamp: ts, model: model)
            record.inputTokens = int("input_tokens", in: usage)
            record.outputTokens = int("output_tokens", in: usage)
            record.cacheWriteTokens = int("cache_creation_input_tokens", in: usage)
            record.cacheWrite1hTokens = int("ephemeral_1h_input_tokens", in: cacheCreation)
            record.cacheReadTokens = int("cache_read_input_tokens", in: usage)
            record.project = json["cwd"] as? String
            record.session = json["sessionId"] as? String
            record.toolCalls = toolCalls
            record.id = key
            byMessage[key] = record
            order.append(key)
        }
        return order.compactMap { byMessage[$0] }
    }
}
