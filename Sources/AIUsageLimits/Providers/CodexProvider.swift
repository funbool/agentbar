import Foundation

struct CodexProvider: UsageProvider {
    let id: Provider = .codex

    static let usageURL = URL(string: "https://chatgpt.com/backend-api/wham/usage")!

    struct Credentials: Equatable {
        let accessToken: String
        let accountId: String?
    }

    func fetch() async throws -> ProviderSnapshot {
        guard let creds = Self.loadCredentials() else { throw ProviderError.notLoggedIn }
        var headers = ["Authorization": "Bearer \(creds.accessToken)", "User-Agent": "AIUsageLimits"]
        if let accountId = creds.accountId { headers["ChatGPT-Account-Id"] = accountId }
        let data = try await HTTP.json(Self.usageURL, headers: headers)
        return try Self.parse(data)
    }

    // MARK: - Credentials

    static func authFilePath(environment: [String: String] = ProcessInfo.processInfo.environment) -> String {
        let home = environment["CODEX_HOME"].flatMap { $0.isEmpty ? nil : $0 } ?? NSHomeDirectory() + "/.codex"
        return home + "/auth.json"
    }

    static func loadCredentials() -> Credentials? {
        guard let data = FileManager.default.contents(atPath: authFilePath()) else { return nil }
        return parseCredentials(data)
    }

    static func parseCredentials(_ data: Data) -> Credentials? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokens = json["tokens"] as? [String: Any],
              let token = tokens["access_token"] as? String, !token.isEmpty
        else { return nil }
        var accountId = tokens["account_id"] as? String
        if accountId == nil, let idToken = tokens["id_token"] as? String,
           let auth = JWT.payload(idToken)?["https://api.openai.com/auth"] as? [String: Any]
        {
            accountId = auth["chatgpt_account_id"] as? String
        }
        return Credentials(accessToken: token, accountId: accountId)
    }

    // MARK: - Parsing

    static func parse(_ data: Data) throws -> ProviderSnapshot {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ProviderError.badResponse("Codex usage: not a JSON object")
        }
        let rateLimit = json["rate_limit"] as? [String: Any] ?? [:]
        var windows: [UsageWindow] = []
        for (key, fallbackKind) in [("primary_window", UsageWindow.Kind.fiveHour), ("secondary_window", .weekly)] {
            guard let w = rateLimit[key] as? [String: Any],
                  let pct = (w["used_percent"] as? NSNumber)?.doubleValue
            else { continue }
            let seconds = (w["limit_window_seconds"] as? NSNumber)?.doubleValue
            let kind: UsageWindow.Kind = seconds.map { $0 > 24 * 3600 ? .weekly : .fiveHour } ?? fallbackKind
            let reset = (w["reset_at"] as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue) }
            windows.append(UsageWindow(kind: kind, usedPercent: pct, resetsAt: reset))
        }
        guard !windows.isEmpty else { throw ProviderError.badResponse("Codex usage: no rate_limit windows") }
        let plan = (json["plan_type"] as? String).map { $0.prefix(1).uppercased() + $0.dropFirst() }
        return ProviderSnapshot(provider: .codex, windows: windows, plan: plan)
    }
}
