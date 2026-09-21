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
        return try Self.parse(try await Self.rawUsage(creds), plan: creds.subscriptionType)
    }

    static func rawUsage(_ creds: Credentials? = nil) async throws -> Data {
        guard let creds = creds ?? loadCredentials() else { throw ProviderError.notLoggedIn }
        return try await HTTP.json(usageURL, headers: [
            "Authorization": "Bearer \(creds.accessToken)",
            "anthropic-beta": betaHeader,
            "User-Agent": "claude-code/\(claudeCodeVersion())",
        ])
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
        windows += scopedWeeklyWindows(json["limits"] as? [[String: Any]], existing: windows)
        guard !windows.isEmpty else { throw ProviderError.badResponse("Claude usage: no windows in response") }
        return ProviderSnapshot(provider: .claude, windows: windows, plan: plan.map(Self.planLabel))
    }

    /// Newer response shape: `limits[]` entries with `kind == "weekly_scoped"` name the model they apply to
    /// (`scope.model.display_name`, e.g. "Fable"). Flat `seven_day_opus/sonnet` windows take precedence when present.
    static func scopedWeeklyWindows(_ limits: [[String: Any]]?, existing: [UsageWindow]) -> [UsageWindow] {
        guard let limits else { return [] }
        let covered: Set<String> = Set(existing.compactMap {
            switch $0.kind {
            case .weeklyOpus: "opus"
            case .weeklySonnet: "sonnet"
            default: nil
            }
        })
        var seen: Set<String> = []
        return limits.compactMap { entry in
            guard entry["kind"] as? String == "weekly_scoped",
                  let pct = (entry["percent"] as? NSNumber)?.doubleValue,
                  let scope = entry["scope"] as? [String: Any],
                  let model = scope["model"] as? [String: Any],
                  let name = (model["display_name"] as? String)?.trimmingCharacters(in: .whitespaces), !name.isEmpty
            else { return nil }
            let key = name.lowercased()
            guard key != "all models", !covered.contains(key), seen.insert(key).inserted else { return nil }
            return UsageWindow(kind: .weeklyScoped, label: name, usedPercent: pct,
                               resetsAt: Formatters.isoDate(entry["resets_at"] as? String))
        }
    }

    private static func planLabel(_ raw: String) -> String {
        raw.prefix(1).uppercased() + raw.dropFirst()
    }
}
