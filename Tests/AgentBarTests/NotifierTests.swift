import XCTest
@testable import AgentBar

final class NotifierLogicTests: XCTestCase {
    private func snap(_ p: Provider, _ windows: [UsageWindow]) -> ProviderSnapshot {
        ProviderSnapshot(provider: p, windows: windows)
    }

    func testOnlyWindowsAtOrAboveThresholdAreDue() {
        let reset = Date(timeIntervalSince1970: 1_800_000_000)
        let s = snap(.claude, [
            UsageWindow(kind: .fiveHour, usedPercent: 79, resetsAt: reset),
            UsageWindow(kind: .weekly, usedPercent: 80, resetsAt: reset),
        ])
        let due = Notifier.dueWindows(snapshots: [s], threshold: { _, _ in 80 }, alreadySent: [])
        XCTAssertEqual(due.map { $0.1.kind }, [.weekly])
        XCTAssertEqual(due.first?.key, "claude|weekly|1800000000")
    }

    func testAlreadySentKeysAreSkippedUntilResetChanges() {
        let reset1 = Date(timeIntervalSince1970: 1_800_000_000)
        let reset2 = Date(timeIntervalSince1970: 1_800_018_000)
        let w1 = UsageWindow(kind: .fiveHour, usedPercent: 95, resetsAt: reset1)
        let sent: Set<String> = [Notifier.dedupeKey(.codex, w1)]
        XCTAssertTrue(Notifier.dueWindows(snapshots: [snap(.codex, [w1])], threshold: { _, _ in 80 }, alreadySent: sent).isEmpty)

        let w2 = UsageWindow(kind: .fiveHour, usedPercent: 95, resetsAt: reset2)
        XCTAssertEqual(Notifier.dueWindows(snapshots: [snap(.codex, [w2])], threshold: { _, _ in 80 }, alreadySent: sent).count, 1)
    }

    func testPerWindowRulesDisableOrOverrideThreshold() {
        let s = snap(.claude, [
            UsageWindow(kind: .fiveHour, usedPercent: 99),
            UsageWindow(kind: .weekly, usedPercent: 55),
            UsageWindow(kind: .weeklyScoped, label: "Fable", usedPercent: 70),
        ])
        let due = Notifier.dueWindows(snapshots: [s], threshold: { _, w in
            switch w.id {
            case "fiveHour": nil          // muted
            case "weekly": 50             // custom threshold
            default: 80                   // global
            }
        }, alreadySent: [])
        XCTAssertEqual(due.map { $0.1.id }, ["weekly"])
    }
}
