import XCTest
@testable import AIUsageLimits

final class JWTTests: XCTestCase {
    func testDecodesSubject() {
        // header.payload.sig with payload {"sub":"auth0|user_123","exp":1}
        let payload = Data(#"{"sub":"auth0|user_123","exp":1}"#.utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
        let token = "eyJhbGciOiJIUzI1NiJ9.\(payload).sig"
        XCTAssertEqual(JWT.subject(token), "auth0|user_123")
    }

    func testInvalidTokenReturnsNil() {
        XCTAssertNil(JWT.subject("not-a-jwt"))
        XCTAssertNil(JWT.subject("a.!!!.c"))
    }
}

final class FormattersTests: XCTestCase {
    func testRemaining() {
        let now = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(Formatters.remaining(until: now.addingTimeInterval(45 * 60), now: now), "45m")
        XCTAssertEqual(Formatters.remaining(until: now.addingTimeInterval(2 * 3600 + 15 * 60), now: now), "2h 15m")
        XCTAssertEqual(Formatters.remaining(until: now.addingTimeInterval(3 * 86400 + 4 * 3600), now: now), "3d 4h")
        XCTAssertEqual(Formatters.remaining(until: now.addingTimeInterval(2 * 86400), now: now), "2d")
        XCTAssertNil(Formatters.remaining(until: now.addingTimeInterval(-1), now: now))
    }

    func testPercent() {
        XCTAssertEqual(Formatters.percent(33.4), "33%")
        XCTAssertEqual(Formatters.percent(99.6), "100%")
    }

    func testIsoDate() {
        XCTAssertNotNil(Formatters.isoDate("2026-09-22T10:00:00.000Z"))
        XCTAssertNotNil(Formatters.isoDate("2026-09-22T10:00:00Z"))
        XCTAssertNil(Formatters.isoDate("garbage"))
    }

    func testWindowClampsPercent() {
        XCTAssertEqual(UsageWindow(kind: .fiveHour, usedPercent: 140).usedPercent, 100)
        XCTAssertEqual(UsageWindow(kind: .fiveHour, usedPercent: -3).usedPercent, 0)
    }
}

@MainActor
final class SettingsRulesTests: XCTestCase {
    func testRulesRoundTripAndDefaults() {
        let defaults = UserDefaults(suiteName: "test.rules.\(UUID().uuidString)")!
        let settings = Settings(defaults: defaults)
        settings.notificationThreshold = 80
        let weekly = UsageWindow(kind: .weekly, usedPercent: 0)
        let fable = UsageWindow(kind: .weeklyScoped, label: "Fable", usedPercent: 0)

        XCTAssertEqual(settings.rule(for: .claude, weekly), NotificationRule())
        XCTAssertEqual(settings.effectiveThreshold(for: .claude, weekly), 80)

        settings.setRule(NotificationRule(enabled: false, threshold: nil), for: .claude, weekly)
        settings.setRule(NotificationRule(enabled: true, threshold: 95), for: .claude, fable)
        XCTAssertEqual(settings.effectiveThreshold(for: .claude, fable), 95)

        let reloaded = Settings(defaults: defaults)
        XCTAssertFalse(reloaded.rule(for: .claude, weekly).enabled)
        XCTAssertEqual(reloaded.rule(for: .claude, fable).threshold, 95)
        // Resetting to defaults removes the stored entry.
        reloaded.setRule(NotificationRule(), for: .claude, weekly)
        XCTAssertEqual(reloaded.rule(for: .claude, weekly), NotificationRule())
    }
}
