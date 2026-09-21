import Foundation

struct ClaudeProvider: UsageProvider {
    let id: Provider = .claude

    static let keychainService = "Claude Code-credentials"
    static let usageURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    static let profileURL = URL(string: "https://api.anthropic.com/api/oauth/profile")!
    private static let betaHeader = "oauth-2025-04-20"

    struct Credentials: Equatable {
        let accessToken: String
        let subscriptionType: String?
    }

    func fetch() async throws -> ProviderSnapshot {
        guard let creds = Self.loadCredentials() else { throw ProviderError.notLoggedIn }
        let usage = try await Self.rawUsage(creds)
        // The Keychain's `subscriptionType` is written at login and goes stale after a plan change;
        // the profile endpoint is authoritative, so prefer it (cached for an hour).
        let plan = await Self.cachedPlan(creds) ?? creds.subscriptionType.map(Self.planLabel)
        return try Self.parse(usage, plan: plan)
    }

    // MARK: - Plan

    private static let planCache = PlanCache()

    private static func cachedPlan(_ creds: Credentials) async -> String? {
        if let cached = await planCache.value(for: creds.accessToken) { return cached }
        guard let data = try? await rawProfile(creds), let plan = parsePlan(data) else { return nil }
        await planCache.store(plan, for: creds.accessToken)
        return plan
    }

    /// "Max 20x" / "Max 5x" / "Max" / "Pro" / "Team" / "Enterprise" from `/api/oauth/profile`.
    static func parsePlan(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        let org = json["organization"] as? [String: Any] ?? [:]
        let account = json["account"] as? [String: Any] ?? [:]
        if let tier = org["rate_limit_tier"] as? String {
            // e.g. default_claude_max_20x -> "Max 20x"
            if let range = tier.range(of: "claude_max_") {
                let multiplier = tier[range.upperBound...]
                return multiplier.isEmpty ? "Max" : "Max \(multiplier)"
            }
        }
        switch org["organization_type"] as? String {
        case "claude_max": return "Max"
        case "claude_pro": return "Pro"
        case "claude_team": return "Team"
        case "claude_enterprise": return "Enterprise"
        default: break
        }
        if account["has_claude_max"] as? Bool == true { return "Max" }
        if account["has_claude_pro"] as? Bool == true { return "Pro" }
        return nil
    }

    static func rawUsage(_ creds: Credentials? = nil) async throws -> Data {
        guard let creds = creds ?? loadCredentials() else { throw ProviderError.notLoggedIn }
        return try await HTTP.json(usageURL, headers: [
            "Authorization": "Bearer \(creds.accessToken)",
            "anthropic-beta": betaHeader,
            "User-Agent": "claude-code/\(claudeCodeVersion())",
        ])
    }

    static func rawProfile(_ creds: Credentials? = nil) async throws -> Data {
        guard let creds = creds ?? loadCredentials() else { throw ProviderError.notLoggedIn }
        return try await HTTP.json(profileURL, headers: [
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
        try parseUsage(data, plan: plan)
    }

    private static func parseUsage(_ data: Data, plan: String?) throws -> ProviderSnapshot {
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
        return ProviderSnapshot(provider: .claude, windows: windows, plan: plan)
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

    static func planLabel(_ raw: String) -> String {
        raw.prefix(1).uppercased() + raw.dropFirst()
    }
}

/// One-hour cache of the plan label keyed by access token (a new token means a possible account change).
actor PlanCache {
    private var token: String?
    private var plan: String?
    private var fetchedAt: Date?

    func value(for token: String) -> String? {
        guard self.token == token, let plan, let fetchedAt, Date().timeIntervalSince(fetchedAt) < 3600 else { return nil }
        return plan
    }

    func store(_ plan: String, for token: String) {
        self.token = token
        self.plan = plan
        self.fetchedAt = Date()
    }
}
