import Foundation

/// Cursor has no local token logs; usage events come from the dashboard API and are cached on disk.
/// Events carry no stable id, so the cache is keyed by a content hash and refreshes re-fetch a small overlap.
enum CursorStatsSource {
    static let eventsURL = URL(string: "https://cursor.com/api/dashboard/get-filtered-usage-events")!
    static let cacheName = "cursor-events-cache.json"
    static let pageSize = 200
    /// Re-fetch this much before the newest cached event so late-arriving rows are not missed.
    static let overlap: TimeInterval = 6 * 3600

    enum HistoryMode: String, Codable { case all, currentCycle }

    struct Cache: Codable {
        var mode: HistoryMode?
        var records: [UsageRecord] = []
        var keys: [String] = []
        var lastFetch: Date?
    }

    static func loadCache() -> Cache {
        let url = FileScanCache.directory.appendingPathComponent(cacheName)
        guard let data = try? Data(contentsOf: url), let c = try? JSONDecoder().decode(Cache.self, from: data) else {
            return Cache()
        }
        return c
    }

    static func save(_ cache: Cache) {
        let url = FileScanCache.directory.appendingPathComponent(cacheName)
        if let data = try? JSONEncoder().encode(cache) { try? data.write(to: url, options: .atomic) }
    }

    /// Fetches new events since the newest cached one (or the whole chosen range on first run) and merges them.
    static func refresh(mode: HistoryMode, cycleStart: Date?, progress: ((Int, Int) -> Void)? = nil) async throws -> [UsageRecord] {
        guard let creds = CursorProvider.loadCredentials() else { throw ProviderError.notLoggedIn }
        var cache = loadCache()
        if cache.mode != mode { cache = Cache(mode: mode) }

        var since: Date?
        if let newest = cache.records.map(\.timestamp).max() {
            since = newest.addingTimeInterval(-overlap)
        } else if mode == .currentCycle {
            since = cycleStart
        }

        var seen = Set(cache.keys)
        var page = 1
        var fetched = 0
        var expected: Int?
        while true {
            let (events, total) = try await fetchPage(creds: creds, page: page, since: since)
            expected = total
            for e in events {
                let key = e.key
                if seen.insert(key).inserted {
                    cache.records.append(e.record)
                    cache.keys.append(key)
                }
            }
            fetched += events.count
            progress?(fetched, total ?? fetched)
            if events.count < pageSize || (total != nil && fetched >= total!) { break }
            page += 1
            if page > 500 { break } // safety valve
        }
        _ = expected
        cache.lastFetch = Date()
        cache.records.sort { $0.timestamp < $1.timestamp }
        save(cache)
        return cache.records
    }

    struct Event {
        let record: UsageRecord
        let key: String
    }

    private static func fetchPage(creds: CursorProvider.Credentials, page: Int, since: Date?) async throws -> ([Event], Int?) {
        var body: [String: Any] = ["page": page, "pageSize": pageSize]
        if let since { body["startDate"] = String(Int(since.timeIntervalSince1970 * 1000)) }
        body["endDate"] = String(Int(Date().timeIntervalSince1970 * 1000))
        let data = try await HTTP.json(eventsURL, method: "POST", headers: [
            "Cookie": creds.cookieHeader,
            "Origin": "https://cursor.com",
            "Referer": "https://cursor.com/dashboard",
        ], body: try JSONSerialization.data(withJSONObject: body))
        return try parsePage(data)
    }

    static func parsePage(_ data: Data) throws -> ([Event], Int?) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ProviderError.badResponse("Cursor events: not a JSON object")
        }
        let total = (json["totalUsageEventsCount"] as? NSNumber)?.intValue
        let rows = json["usageEventsDisplay"] as? [[String: Any]] ?? []
        return (rows.compactMap(parseEvent), total)
    }

    /// "USAGE_EVENT_KIND_INCLUDED_IN_ULTRA" -> "Included in Ultra".
    static func prettyKind(_ raw: String) -> String {
        let trimmed = raw.replacingOccurrences(of: "USAGE_EVENT_KIND_", with: "")
        let words = trimmed.lowercased().split(separator: "_").map(String.init)
        return words.enumerated().map { $0.offset == 0 ? $0.element.capitalized : $0.element }.joined(separator: " ")
    }

    static func parseEvent(_ e: [String: Any]) -> Event? {
        let tsRaw = e["timestamp"]
        let ms: Double? = (tsRaw as? NSNumber)?.doubleValue ?? (tsRaw as? String).flatMap(Double.init)
        guard let ms else { return nil }
        let ts = Date(timeIntervalSince1970: ms / 1000)
        let usage = e["tokenUsage"] as? [String: Any] ?? [:]
        func int(_ k: String) -> Int { (usage[k] as? NSNumber)?.intValue ?? 0 }
        var r = UsageRecord(timestamp: ts, model: (e["model"] as? String) ?? "unknown")
        r.inputTokens = int("inputTokens")
        r.outputTokens = int("outputTokens")
        r.cacheWriteTokens = int("cacheWriteTokens")
        r.cacheReadTokens = int("cacheReadTokens")
        // Notional cost of the call at model prices (what the plan's included usage is measured in).
        if let cents = (usage["totalCents"] as? NSNumber)?.doubleValue {
            r.reportedCostUSD = cents / 100
        } else if let cents = (e["chargedCents"] as? NSNumber)?.doubleValue {
            r.reportedCostUSD = cents / 100
        } else {
            r.reportedCostUSD = 0
        }
        r.project = (e["kind"] as? String).map(prettyKind)
        r.session = e["conversationId"] as? String
        let key = "\(Int(ms))|\(r.model)|\(r.inputTokens)|\(r.outputTokens)|\(r.cacheWriteTokens)|\(r.cacheReadTokens)|\(r.reportedCostUSD ?? 0)"
        return Event(record: r, key: key)
    }
}
