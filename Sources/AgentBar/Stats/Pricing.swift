import Foundation

/// Public API list prices, USD per 1M tokens.
struct ModelPrice: Sendable {
    let input: Double
    let output: Double
    /// Multiplier on `input` for cache writes (Claude 5-minute TTL). Nil = cache writes are free (OpenAI).
    let cacheWrite5m: Double?
    /// Multiplier on `input` for cache writes with 1-hour TTL (Claude).
    let cacheWrite1h: Double?
    /// Absolute price per 1M cached-input tokens.
    let cacheRead: Double

    func cost(_ r: UsageRecord) -> Double {
        let write1h = Double(min(r.cacheWrite1hTokens, r.cacheWriteTokens))
        let write5m = Double(r.cacheWriteTokens) - write1h
        var usd = Double(r.inputTokens) * input + Double(r.outputTokens) * output + Double(r.cacheReadTokens) * cacheRead
        if let m = cacheWrite5m { usd += write5m * input * m }
        if let m = cacheWrite1h { usd += write1h * input * m }
        return usd / 1_000_000
    }
}

enum Pricing {
    /// Ordered longest-prefix-first so e.g. "claude-opus-4-8" isn't matched by "claude-opus-4".
    private static let claude: [(prefix: String, price: ModelPrice)] = [
        ("claude-fable-5-1", ModelPrice(input: 10, output: 50, cacheWrite5m: 1.25, cacheWrite1h: 2, cacheRead: 0.25)),
        ("claude-mythos-5-1", ModelPrice(input: 10, output: 50, cacheWrite5m: 1.25, cacheWrite1h: 2, cacheRead: 0.25)),
        ("claude-fable-5", ModelPrice(input: 10, output: 50, cacheWrite5m: 1.25, cacheWrite1h: 2, cacheRead: 1)),
        ("claude-opus-5", ModelPrice(input: 5, output: 25, cacheWrite5m: 1.25, cacheWrite1h: 2, cacheRead: 0.5)),
        ("claude-opus-4-8", ModelPrice(input: 5, output: 25, cacheWrite5m: 1.25, cacheWrite1h: 2, cacheRead: 0.5)),
        ("claude-opus-4-7", ModelPrice(input: 5, output: 25, cacheWrite5m: 1.25, cacheWrite1h: 2, cacheRead: 0.5)),
        ("claude-opus-4-6", ModelPrice(input: 5, output: 25, cacheWrite5m: 1.25, cacheWrite1h: 2, cacheRead: 0.5)),
        ("claude-opus-4-5", ModelPrice(input: 5, output: 25, cacheWrite5m: 1.25, cacheWrite1h: 2, cacheRead: 0.5)),
        ("claude-opus-4", ModelPrice(input: 15, output: 75, cacheWrite5m: 1.25, cacheWrite1h: 2, cacheRead: 1.5)),
        ("claude-sonnet-5", ModelPrice(input: 2, output: 10, cacheWrite5m: 1.25, cacheWrite1h: 2, cacheRead: 0.2)),
        ("claude-sonnet-4", ModelPrice(input: 3, output: 15, cacheWrite5m: 1.25, cacheWrite1h: 2, cacheRead: 0.3)),
        ("claude-haiku-4-5", ModelPrice(input: 1, output: 5, cacheWrite5m: 1.25, cacheWrite1h: 2, cacheRead: 0.1)),
        ("claude-haiku-4", ModelPrice(input: 1, output: 5, cacheWrite5m: 1.25, cacheWrite1h: 2, cacheRead: 0.1)),
        ("claude-3-5-haiku", ModelPrice(input: 0.8, output: 4, cacheWrite5m: 1.25, cacheWrite1h: 2, cacheRead: 0.08)),
    ]

    private static let openai: [(prefix: String, price: ModelPrice)] = [
        ("gpt-6-astra", ModelPrice(input: 10, output: 50, cacheWrite5m: nil, cacheWrite1h: nil, cacheRead: 1)),
        ("gpt-5.6-sol", ModelPrice(input: 4, output: 20, cacheWrite5m: nil, cacheWrite1h: nil, cacheRead: 0.4)),
        ("gpt-5.6-terra", ModelPrice(input: 2, output: 12, cacheWrite5m: nil, cacheWrite1h: nil, cacheRead: 0.2)),
        ("gpt-5.6-luna", ModelPrice(input: 0.2, output: 1.2, cacheWrite5m: nil, cacheWrite1h: nil, cacheRead: 0.02)),
        ("gpt-5.5", ModelPrice(input: 5, output: 30, cacheWrite5m: nil, cacheWrite1h: nil, cacheRead: 0.5)),
        ("gpt-5.4", ModelPrice(input: 2.5, output: 15, cacheWrite5m: nil, cacheWrite1h: nil, cacheRead: 0.25)),
        ("gpt-5.3-codex", ModelPrice(input: 1.75, output: 14, cacheWrite5m: nil, cacheWrite1h: nil, cacheRead: 0.175)),
        ("gpt-5.2", ModelPrice(input: 1.75, output: 14, cacheWrite5m: nil, cacheWrite1h: nil, cacheRead: 0.175)),
        ("gpt-5.1", ModelPrice(input: 1.25, output: 10, cacheWrite5m: nil, cacheWrite1h: nil, cacheRead: 0.125)),
        ("gpt-5", ModelPrice(input: 1.25, output: 10, cacheWrite5m: nil, cacheWrite1h: nil, cacheRead: 0.125)),
    ]

    static func price(for model: String, provider: Provider) -> ModelPrice? {
        let table = provider == .claude ? claude : openai
        let m = model.lowercased()
        return table.first { m.hasPrefix($0.prefix) }?.price
    }

    /// Cost for a record: provider-reported when present, otherwise from the list price; nil when unknown.
    static func cost(_ r: UsageRecord, provider: Provider) -> Double? {
        if let reported = r.reportedCostUSD { return reported }
        return price(for: r.model, provider: provider)?.cost(r)
    }
}
