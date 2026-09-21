import XCTest
@testable import AgentBar

private func fixture(_ name: String) throws -> Data {
    let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
    return try Data(contentsOf: url)
}

final class ClaudeProviderTests: XCTestCase {
    func testParsesWindows() throws {
        let snap = try ClaudeProvider.parse(try fixture("claude_usage"), plan: ClaudeProvider.planLabel("max"))
        XCTAssertEqual(snap.provider, .claude)
        XCTAssertEqual(snap.plan, "Max")
        XCTAssertEqual(snap.windows.map(\.kind), [.fiveHour, .weekly, .weeklyOpus, .weeklyScoped])
        XCTAssertEqual(snap.windows[3].label, "Fable")
        XCTAssertEqual(snap.windows[3].usedPercent, 53)
        XCTAssertEqual(snap.windows[3].id, "weeklyScoped-Fable")
        XCTAssertEqual(snap.windows[0].usedPercent, 34.2)
        XCTAssertEqual(snap.windows[1].usedPercent, 61)
        XCTAssertEqual(snap.windows[0].resetsAt, Formatters.isoDate("2026-09-22T05:00:00Z"))
    }

    func testParsesCredentials() throws {
        let creds = try XCTUnwrap(ClaudeProvider.parseCredentials(try fixture("claude_credentials")))
        XCTAssertEqual(creds.accessToken, "sk-ant-oat01-test")
        XCTAssertEqual(creds.subscriptionType, "max")
        XCTAssertNil(ClaudeProvider.parseCredentials(Data("{}".utf8)))
    }

    func testEmptyResponseThrows() {
        XCTAssertThrowsError(try ClaudeProvider.parse(Data("{}".utf8), plan: nil))
    }

    func testPlanFromProfilePrefersRateLimitTier() {
        let max20 = #"{"account":{"has_claude_max":true,"has_claude_pro":false},"organization":{"organization_type":"claude_max","rate_limit_tier":"default_claude_max_20x"}}"#
        XCTAssertEqual(ClaudeProvider.parsePlan(Data(max20.utf8)), "Max 20x")
        let max5 = #"{"organization":{"rate_limit_tier":"default_claude_max_5x"}}"#
        XCTAssertEqual(ClaudeProvider.parsePlan(Data(max5.utf8)), "Max 5x")
        let pro = #"{"account":{"has_claude_max":false,"has_claude_pro":true},"organization":{"organization_type":"claude_pro","rate_limit_tier":"default_claude_ai"}}"#
        XCTAssertEqual(ClaudeProvider.parsePlan(Data(pro.utf8)), "Pro")
        let team = #"{"organization":{"organization_type":"claude_team"}}"#
        XCTAssertEqual(ClaudeProvider.parsePlan(Data(team.utf8)), "Team")
        XCTAssertNil(ClaudeProvider.parsePlan(Data("{}".utf8)))
    }
}

final class CodexProviderTests: XCTestCase {
    func testParsesWindows() throws {
        let snap = try CodexProvider.parse(try fixture("codex_usage"))
        XCTAssertEqual(snap.plan, "Plus")
        XCTAssertEqual(snap.windows.map(\.kind), [.fiveHour, .weekly])
        XCTAssertEqual(snap.windows[0].usedPercent, 27)
        XCTAssertEqual(snap.windows[1].usedPercent, 58.5)
        XCTAssertEqual(snap.windows[0].resetsAt, Date(timeIntervalSince1970: 1790000000))
    }

    func testParsesCredentials() throws {
        let creds = try XCTUnwrap(CodexProvider.parseCredentials(try fixture("codex_auth")))
        XCTAssertEqual(creds.accessToken, "access-test")
        XCTAssertEqual(creds.accountId, "acct_123")
    }

    func testAccountIdFallsBackToIdToken() throws {
        let claims = #"{"https://api.openai.com/auth":{"chatgpt_account_id":"acct_from_jwt"}}"#
        let payload = Data(claims.utf8).base64EncodedString().replacingOccurrences(of: "=", with: "")
        let json = #"{"tokens":{"access_token":"a","id_token":"h.\#(payload).s"}}"#
        let creds = try XCTUnwrap(CodexProvider.parseCredentials(Data(json.utf8)))
        XCTAssertEqual(creds.accountId, "acct_from_jwt")
    }
}

final class CursorProviderTests: XCTestCase {
    func testParsesPlanAndOnDemand() throws {
        let snap = try CursorProvider.parse(try fixture("cursor_usage_summary"), sand: try fixture("cursor_sand_usage"))
        XCTAssertEqual(snap.plan, "Pro")
        XCTAssertEqual(snap.windows.map(\.kind), [.cursorModels, .apiModels, .onDemand, .grok])
        XCTAssertEqual(snap.summary, "$12.34 spent")
        XCTAssertEqual(snap.windows[0].usedPercent, 20.1)
        XCTAssertEqual(snap.windows[0].resetsAt, Formatters.isoDate("2026-10-01T00:00:00Z"))
        XCTAssertEqual(snap.windows[1].usedPercent, 41.6)
        XCTAssertEqual(snap.windows[2].usedPercent, 7, accuracy: 0.001)
        XCTAssertEqual(snap.windows[2].detail, "$3.50 / $50")
        XCTAssertEqual(snap.windows[3].usedPercent, 12.5)
        // No nextResetTimestampUtc → period start + 7 days.
        XCTAssertEqual(snap.windows[3].resetsAt, Formatters.isoDate("2026-09-24T00:00:00Z"))
    }

    func testGrokSkippedWithoutIncludedLimit() {
        let json = #"{"usagePercent":0,"hasNonZeroIncludedLimit":false}"#
        XCTAssertNil(CursorProvider.grokWindow(Data(json.utf8)))
    }

    func testOnDemandSkippedWhenDisabled() throws {
        let json = #"{"individualUsage":{"plan":{"used":100,"limit":1000,"autoPercentUsed":3,"apiPercentUsed":4},"onDemand":{"enabled":false}}}"#
        let snap = try CursorProvider.parse(Data(json.utf8))
        XCTAssertEqual(snap.windows.map(\.kind), [.cursorModels, .apiModels])
        XCTAssertEqual(snap.windows[0].usedPercent, 3)
    }

    func testCredentialsFromJWT() throws {
        let payload = Data(#"{"sub":"auth0|user_01ABC"}"#.utf8).base64EncodedString().replacingOccurrences(of: "=", with: "")
        let creds = try XCTUnwrap(CursorProvider.credentials(fromAccessToken: "h.\(payload).s"))
        XCTAssertEqual(creds.userId, "user_01ABC")
        XCTAssertEqual(creds.cookieHeader, "WorkosCursorSessionToken=user_01ABC%3A%3Ah.\(payload).s")
    }
}
