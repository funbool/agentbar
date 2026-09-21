import Foundation

struct CursorProvider: UsageProvider {
    let id: Provider = .cursor

    static let usageSummaryURL = URL(string: "https://cursor.com/api/usage-summary")!

    struct Credentials: Equatable {
        let accessToken: String
        let userId: String

        var cookieHeader: String { "WorkosCursorSessionToken=\(userId)%3A%3A\(accessToken)" }
    }

    func fetch() async throws -> ProviderSnapshot {
        guard let creds = Self.loadCredentials() else { throw ProviderError.notLoggedIn }
        let data = try await HTTP.json(Self.usageSummaryURL, headers: [
            "Cookie": creds.cookieHeader,
            "Origin": "https://cursor.com",
            "Referer": "https://cursor.com/dashboard",
        ])
        return try Self.parse(data)
    }

    // MARK: - Credentials

    static var stateDBPath: String {
        NSHomeDirectory() + "/Library/Application Support/Cursor/User/globalStorage/state.vscdb"
    }

    static func loadCredentials() -> Credentials? {
        guard let token = SQLiteReader.itemTableValue(dbPath: stateDBPath, key: "cursorAuth/accessToken") else {
            return nil
        }
        return credentials(fromAccessToken: token)
    }

    static func credentials(fromAccessToken token: String) -> Credentials? {
        // `sub` looks like "auth0|user_01ABC..."; the cookie needs only the part after the pipe.
        guard let sub = JWT.subject(token),
              let userId = sub.split(separator: "|").last.map(String.init), !userId.isEmpty
        else { return nil }
        return Credentials(accessToken: token, userId: userId)
    }

    // MARK: - Parsing

    static func parse(_ data: Data) throws -> ProviderSnapshot {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ProviderError.badResponse("Cursor usage: not a JSON object")
        }
        let individual = json["individualUsage"] as? [String: Any] ?? [:]
        let cycleEnd = Formatters.isoDate(json["billingCycleEnd"] as? String)
        var windows: [UsageWindow] = []

        if let plan = individual["plan"] as? [String: Any] {
            let usedCents = (plan["used"] as? NSNumber)?.doubleValue ?? 0
            let limitCents = (plan["limit"] as? NSNumber)?.doubleValue ?? 0
            let pct: Double? = (plan["totalPercentUsed"] as? NSNumber)?.doubleValue
                ?? (limitCents > 0 ? usedCents / limitCents * 100 : nil)
            if let pct {
                let detail = limitCents > 0
                    ? "\(Formatters.usd(usedCents / 100)) / \(Formatters.usd(limitCents / 100))"
                    : nil
                windows.append(UsageWindow(kind: .monthly, usedPercent: pct, resetsAt: cycleEnd, detail: detail))
            }
        }
        if let onDemand = individual["onDemand"] as? [String: Any],
           (onDemand["enabled"] as? Bool) == true,
           let limitCents = (onDemand["limit"] as? NSNumber)?.doubleValue, limitCents > 0
        {
            let usedCents = (onDemand["used"] as? NSNumber)?.doubleValue ?? 0
            windows.append(UsageWindow(
                kind: .onDemand,
                usedPercent: usedCents / limitCents * 100,
                resetsAt: cycleEnd,
                detail: "\(Formatters.usd(usedCents / 100)) / \(Formatters.usd(limitCents / 100))"))
        }
        guard !windows.isEmpty else { throw ProviderError.badResponse("Cursor usage: no plan data in response") }
        let plan = (json["membershipType"] as? String).map { $0.prefix(1).uppercased() + $0.dropFirst() }
        return ProviderSnapshot(provider: .cursor, windows: windows, plan: plan)
    }
}
