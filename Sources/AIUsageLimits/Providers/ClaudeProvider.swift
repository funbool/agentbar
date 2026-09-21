import Foundation

struct ClaudeProvider: UsageProvider {
    let id: Provider = .claude

    static let keychainService = "Claude Code-credentials"
    static let usageURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private static let betaHeader = "oauth-2025-04-20"

    struct Credentials: Equatable {
        let accessToken: String
        let subscriptionType: String?
    }

    func fetch() async throws -> ProviderSnapshot {
        guard let creds = Self.loadCredentials() else { throw ProviderError.notLoggedIn }
        let data = try await HTTP.json(Self.usageURL, headers: [
            "Authorization": "Bearer \(creds.accessToken)",
            "anthropic-beta": Self.betaHeader,
            "User-Agent": "claude-code/\(Self.claudeCodeVersion())",
        ])
        return try Self.parse(data, plan: creds.subscriptionType)
    }

    // MARK: - Credentials

    static func loadCredentials() -> Credentials? {
        // macOS Claude Code stores credentials in Keychain; a JSON file is the fallback (Linux/CI-style setups).
        let raw = KeychainReader.genericPassword(service: keychainService)
            ?? (try? String(contentsOfFile: NSHomeDirectory() + "/.claude/.credentials.json", encoding: .utf8))
        guard let raw, let data = raw.data(using: .utf8) else { return nil }
        return parseCredentials(data)
    }

    static func parseCredentials(_ data: Data) -> Credentials? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = json["claudeAiOauth"] as? [String: Any],
              let token = oauth["accessToken"] as? String, !token.isEmpty
        else { return nil }
        return Credentials(accessToken: token, subscriptionType: oauth["subscriptionType"] as? String)
    }

    private static func claudeCodeVersion() -> String {
        // Cheap detection without spawning `claude`: the updater leaves the last installed version here.
        let path = NSHomeDirectory() + "/.claude/.last-update-result.json"
        if let data = FileManager.default.contents(atPath: path),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let version = json["version_to"] as? String
        {
            return version
        }
        return "2.1.0"
    }

    // MARK: - Parsing

    static func parse(_ data: Data, plan: String?) throws -> ProviderSnapshot {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ProviderError.badResponse("Claude usage: not a JSON object")
        }
        var windows: [UsageWindow] = []
        func add(_ key: String, _ kind: UsageWindow.Kind) {
            guard let w = json[key] as? [String: Any] else { return }
            let pct = (w["utilization"] as? NSNumber)?.doubleValue
            guard let pct else { return }
            windows.append(UsageWindow(kind: kind, usedPercent: pct, resetsAt: Formatters.isoDate(w["resets_at"] as? String)))
        }
        add("five_hour", .fiveHour)
        add("seven_day", .weekly)
        add("seven_day_opus", .weeklyOpus)
        add("seven_day_sonnet", .weeklySonnet)
        guard !windows.isEmpty else { throw ProviderError.badResponse("Claude usage: no windows in response") }
        return ProviderSnapshot(provider: .claude, windows: windows, plan: plan.map(Self.planLabel))
    }

    private static func planLabel(_ raw: String) -> String {
        raw.prefix(1).uppercased() + raw.dropFirst()
    }
}
