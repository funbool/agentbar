import Foundation

enum Formatters {
    static func percent(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    static func usd(_ value: Double) -> String {
        let isWhole = value == value.rounded()
        return isWhole ? "$\(Int(value))" : String(format: "$%.2f", value)
    }

    /// "2h 15m" / "3d 4h" / "45m" / "<1m"; nil when the date is in the past.
    static func remaining(until date: Date, now: Date = Date()) -> String? {
        let seconds = Int(date.timeIntervalSince(now))
        guard seconds > 0 else { return nil }
        let minutes = (seconds + 59) / 60
        let days = minutes / 1440
        let hours = (minutes % 1440) / 60
        let mins = minutes % 60
        if days > 0 { return hours > 0 ? "\(days)d \(hours)h" : "\(days)d" }
        if hours > 0 { return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h" }
        return "\(mins)m"
    }

    static func shortDate(_ date: Date, locale: Locale = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }

    static func time(_ date: Date, locale: Locale = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: date)
    }

    static func isoDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = withFraction.date(from: string) { return d }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: string)
    }
}
