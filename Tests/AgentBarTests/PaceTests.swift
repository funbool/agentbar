import XCTest
@testable import AgentBar

final class PaceTests: XCTestCase {
    private let reset = Date(timeIntervalSince1970: 1_800_000_000)
    private let fiveHours: TimeInterval = 5 * 3600

    private func window(used: Double, remaining: TimeInterval, seconds: TimeInterval? = 5 * 3600) -> (UsageWindow, Date) {
        let w = UsageWindow(kind: .fiveHour, usedPercent: used, resetsAt: reset, windowSeconds: seconds)
        return (w, reset.addingTimeInterval(-remaining))
    }

    func testPaceIsTheShareOfTheWindowAlreadyElapsed() {
        // 2h15m left of a 5h window -> 55 % elapsed.
        let (w, now) = window(used: 0, remaining: 2 * 3600 + 15 * 60)
        XCTAssertEqual(w.pacePercent(now: now)!, 55, accuracy: 0.001)
    }

    func testPaceIsClampedToTheWindow() {
        let (w, _) = window(used: 0, remaining: 0)
        XCTAssertEqual(w.pacePercent(now: reset)!, 100, accuracy: 0.001)
        XCTAssertEqual(w.pacePercent(now: reset.addingTimeInterval(3600))!, 100, accuracy: 0.001)
        XCTAssertEqual(w.pacePercent(now: reset.addingTimeInterval(-fiveHours - 60))!, 0, accuracy: 0.001)
    }

    func testStateComparesUsageWithThePaceMark() {
        let halfway = reset.addingTimeInterval(-fiveHours / 2) // pace = 50 %
        func state(_ used: Double) -> PaceState? {
            UsageWindow(kind: .fiveHour, usedPercent: used, resetsAt: reset, windowSeconds: fiveHours)
                .paceState(now: halfway)
        }
        XCTAssertEqual(state(40), .ahead)
        XCTAssertEqual(state(48.9), .ahead)
        XCTAssertEqual(state(49.5), .onPace)
        XCTAssertEqual(state(50), .onPace)
        XCTAssertEqual(state(51), .onPace)
        XCTAssertEqual(state(51.1), .behind)
        XCTAssertEqual(state(80), .behind)
    }

    func testNoStateRightAfterAResetOrWithoutAKnownWindow() {
        // 2 % into the window: the mark is too close to zero to judge anything by.
        let justReset = reset.addingTimeInterval(-fiveHours * 0.98)
        let w = UsageWindow(kind: .fiveHour, usedPercent: 8, resetsAt: reset, windowSeconds: fiveHours)
        XCTAssertNotNil(w.pacePercent(now: justReset))
        XCTAssertNil(w.paceState(now: justReset))

        let unknown = UsageWindow(kind: .fiveHour, usedPercent: 50, resetsAt: reset)
        XCTAssertNil(unknown.pacePercent(now: reset.addingTimeInterval(-60)))
        XCTAssertNil(unknown.paceState(now: reset.addingTimeInterval(-60)))

        let noReset = UsageWindow(kind: .fiveHour, usedPercent: 50, windowSeconds: fiveHours)
        XCTAssertNil(noReset.pacePercent(now: reset))
    }
}

final class WindowSpanParsingTests: XCTestCase {
    private func fixture(_ name: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }

    func testClaudeWindowsCarryTheirFixedSpans() throws {
        let snap = try ClaudeProvider.parse(try fixture("claude_usage"), plan: nil)
        let spans = Dictionary(uniqueKeysWithValues: snap.windows.map { ($0.id, $0.windowSeconds) })
        XCTAssertEqual(spans["fiveHour"], 5 * 3600)
        XCTAssertEqual(spans["weekly"], 7 * 86400)
        XCTAssertEqual(spans["weeklyOpus"], 7 * 86400)
        XCTAssertEqual(spans["weeklyScoped-Fable"], 7 * 86400)
    }

    func testCodexWindowsUseTheReportedSpan() throws {
        let snap = try CodexProvider.parse(try fixture("codex_usage"))
        XCTAssertEqual(snap.windows[0].windowSeconds, 18000)
        XCTAssertEqual(snap.windows[1].windowSeconds, 604_800)
    }

    func testCursorWindowsSpanTheBillingCycle() throws {
        let snap = try CursorProvider.parse(try fixture("cursor_usage_summary"), sand: try fixture("cursor_sand_usage"))
        let cycle = Formatters.isoDate("2026-10-01T00:00:00Z")!.timeIntervalSince(Formatters.isoDate("2026-09-01T00:00:00Z")!)
        for window in snap.windows where window.kind != .grok {
            XCTAssertEqual(window.windowSeconds, cycle, "\(window.kind)")
        }
        // No nextResetTimestampUtc in the fixture: the Grok window falls back to a 7-day period.
        XCTAssertEqual(snap.windows.last?.windowSeconds, 7 * 86400)
    }
}
