import XCTest
@testable import AIUsageLimits

final class ClaudeStatsParserTests: XCTestCase {
    private let lines = """
    {"type":"user","timestamp":"2026-09-21T13:05:50.000Z","sessionId":"s1","message":{"role":"user","content":"hi"}}
    {"type":"assistant","timestamp":"2026-09-21T13:05:57.921Z","sessionId":"s1","requestId":"req_1","cwd":"/Users/x/proj","message":{"id":"msg_1","model":"claude-opus-5","usage":{"input_tokens":2,"cache_creation_input_tokens":26467,"cache_read_input_tokens":38440,"output_tokens":346,"cache_creation":{"ephemeral_1h_input_tokens":26467,"ephemeral_5m_input_tokens":0}},"content":[{"type":"text","text":"a"}]}}
    {"type":"assistant","timestamp":"2026-09-21T13:05:57.921Z","sessionId":"s1","requestId":"req_1","cwd":"/Users/x/proj","message":{"id":"msg_1","model":"claude-opus-5","usage":{"input_tokens":2,"cache_creation_input_tokens":26467,"cache_read_input_tokens":38440,"output_tokens":346},"content":[{"type":"tool_use","name":"Bash"},{"type":"tool_use","name":"Read"}]}}
    {"type":"assistant","timestamp":"2026-09-21T13:06:10.000Z","sessionId":"s1","requestId":"req_2","message":{"id":"msg_2","model":"<synthetic>","usage":{"input_tokens":0,"output_tokens":0},"content":[]}}
    {"type":"assistant","timestamp":"2026-09-21T13:07:00.000Z","sessionId":"s1","requestId":"req_3","message":{"id":"msg_3","model":"claude-haiku-4-5-20251001","usage":{"input_tokens":100,"output_tokens":50},"content":[{"type":"text","text":"b"}]}}
    """

    func testCountsUsageOncePerMessageAndSumsToolCalls() {
        let records = ClaudeStatsSource.parse(Data(lines.utf8))
        XCTAssertEqual(records.count, 2)
        let first = records[0]
        XCTAssertEqual(first.model, "claude-opus-5")
        XCTAssertEqual(first.inputTokens, 2)
        XCTAssertEqual(first.outputTokens, 346)
        XCTAssertEqual(first.cacheWriteTokens, 26467)
        XCTAssertEqual(first.cacheWrite1hTokens, 26467)
        XCTAssertEqual(first.cacheReadTokens, 38440)
        XCTAssertEqual(first.toolCalls, 2)
        XCTAssertEqual(first.project, "/Users/x/proj")
        XCTAssertEqual(first.session, "s1")
        XCTAssertEqual(first.id, "msg_1|req_1")
        XCTAssertEqual(records[1].model, "claude-haiku-4-5-20251001")
    }

    func testDedupeAcrossFiles() {
        let a = ClaudeStatsSource.parse(Data(lines.utf8))
        let merged = ClaudeStatsSource.dedupe(a + a)
        XCTAssertEqual(merged.count, 2)
    }
}

final class CodexStatsParserTests: XCTestCase {
    private let lines = """
    {"timestamp":"2026-07-03T09:26:03.060Z","type":"session_meta","payload":{"id":"sess1","cwd":"/Users/x/repo"}}
    {"timestamp":"2026-07-03T09:26:07.824Z","type":"turn_context","payload":{"turn_id":"t1","cwd":"/Users/x/repo","model":"gpt-5.5"}}
    {"timestamp":"2026-07-03T09:27:05.281Z","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"input_tokens":16132,"cached_input_tokens":10112,"output_tokens":352,"reasoning_output_tokens":294,"total_tokens":16484},"last_token_usage":{"input_tokens":16132,"cached_input_tokens":10112,"output_tokens":352}}}}
    {"timestamp":"2026-07-03T09:27:06.000Z","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"input_tokens":16132,"cached_input_tokens":10112,"output_tokens":352,"total_tokens":16484},"last_token_usage":{"input_tokens":16132,"cached_input_tokens":10112,"output_tokens":352}}}}
    {"timestamp":"2026-07-03T09:28:00.000Z","type":"turn_context","payload":{"turn_id":"t2","model":"gpt-6-astra"}}
    {"timestamp":"2026-07-03T09:29:05.281Z","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"input_tokens":20132,"cached_input_tokens":14112,"output_tokens":852,"total_tokens":21000},"last_token_usage":{"input_tokens":4000,"cached_input_tokens":4000,"output_tokens":500}}}}
    """

    func testDeltasPerTurnAndRepeatedEventsIgnored() {
        let records = CodexStatsSource.parse(Data(lines.utf8))
        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records[0].model, "gpt-5.5")
        XCTAssertEqual(records[0].inputTokens, 16132 - 10112)
        XCTAssertEqual(records[0].cacheReadTokens, 10112)
        XCTAssertEqual(records[0].outputTokens, 352)
        XCTAssertEqual(records[0].session, "sess1")
        XCTAssertEqual(records[0].project, "/Users/x/repo")
        XCTAssertEqual(records[1].model, "gpt-6-astra")
        XCTAssertEqual(records[1].inputTokens, 0)
        XCTAssertEqual(records[1].cacheReadTokens, 4000)
        XCTAssertEqual(records[1].outputTokens, 500)
    }
}

final class PricingAndAggregatorTests: XCTestCase {
    func testClaudeCostWithCacheTiers() {
        var r = UsageRecord(timestamp: Date(), model: "claude-opus-5")
        r.inputTokens = 1_000_000
        r.outputTokens = 1_000_000
        r.cacheWriteTokens = 2_000_000
        r.cacheWrite1hTokens = 1_000_000
        r.cacheReadTokens = 1_000_000
        // 5 + 25 + (1M*5*1.25) + (1M*5*2) + 0.5 = 5 + 25 + 6.25 + 10 + 0.5
        XCTAssertEqual(Pricing.cost(r, provider: .claude)!, 46.75, accuracy: 0.0001)
    }

    func testOpenAICostAndUnknownModel() {
        var r = UsageRecord(timestamp: Date(), model: "gpt-6-astra")
        r.inputTokens = 1_000_000
        r.cacheReadTokens = 1_000_000
        r.outputTokens = 100_000
        XCTAssertEqual(Pricing.cost(r, provider: .codex)!, 10 + 1 + 5, accuracy: 0.0001)
        XCTAssertNil(Pricing.cost(UsageRecord(timestamp: Date(), model: "codex-auto-review"), provider: .codex))
        XCTAssertEqual(Pricing.cost(UsageRecord(timestamp: Date(), model: "x", reportedCostUSD: 1.5), provider: .cursor), 1.5)
    }

    func testAggregatorFiltersPeriodAndGroups() {
        let now = Date(timeIntervalSince1970: 1_790_000_000)
        var a = UsageRecord(timestamp: now.addingTimeInterval(-3600), model: "claude-opus-5", session: "s1", toolCalls: 2)
        a.inputTokens = 1_000_000; a.project = "/p1"
        var b = UsageRecord(timestamp: now.addingTimeInterval(-10 * 86400), model: "claude-sonnet-5", session: "s2")
        b.outputTokens = 1_000_000; b.project = "/p2"
        let c = UsageRecord(timestamp: now.addingTimeInterval(-60), model: "mystery", session: "s1")
        let pricing: (UsageRecord) -> Double? = { Pricing.cost($0, provider: .claude) }

        let week = StatsAggregator.report([a, b, c], period: .week, pricing: pricing, now: now)
        XCTAssertEqual(week.totals.calls, 2)
        XCTAssertEqual(week.totals.costUSD, 5, accuracy: 0.0001)
        XCTAssertEqual(week.sessions, 1)
        XCTAssertEqual(week.toolCalls, 2)
        XCTAssertEqual(week.byModel.map(\.model), ["claude-opus-5", "mystery"])
        XCTAssertEqual(week.byProject.map(\.project), ["/p1"])

        let all = StatsAggregator.report([a, b, c], period: .all, pricing: pricing, now: now)
        XCTAssertEqual(all.totals.costUSD, 15, accuracy: 0.0001)
        XCTAssertEqual(all.sessions, 2)
        XCTAssertEqual(all.byDay.count, 2)
        XCTAssertEqual(all.firstDate, b.timestamp)
    }
}

final class CursorEventsParserTests: XCTestCase {
    func testParsesPage() throws {
        let json = """
        {"totalUsageEventsCount": 5281, "usageEventsDisplay": [
          {"chargedCents": 17.88, "conversationId": "c1", "kind": "USAGE_EVENT_KIND_INCLUDED_IN_ULTRA", "model": "cursor-grok-4.6-high",
           "timestamp": "1789845928053", "tokenUsage": {"cacheReadTokens": 323584, "inputTokens": 3013, "outputTokens": 1832, "totalCents": 17.881}},
          {"kind": "USAGE_EVENT_KIND_USAGE_BASED", "model": "claude-opus-5", "timestamp": 1789845000000, "chargedCents": 5}
        ]}
        """
        let (events, total) = try CursorStatsSource.parsePage(Data(json.utf8))
        XCTAssertEqual(total, 5281)
        XCTAssertEqual(events.count, 2)
        let r = events[0].record
        XCTAssertEqual(r.model, "cursor-grok-4.6-high")
        XCTAssertEqual(r.cacheReadTokens, 323584)
        XCTAssertEqual(r.reportedCostUSD!, 0.17881, accuracy: 0.00001)
        XCTAssertEqual(r.project, "Included in ultra")
        XCTAssertEqual(r.session, "c1")
        XCTAssertEqual(r.timestamp, Date(timeIntervalSince1970: 1789845928.053))
        XCTAssertEqual(events[1].record.reportedCostUSD!, 0.05, accuracy: 0.00001)
        XCTAssertNotEqual(events[0].key, events[1].key)
    }
}
