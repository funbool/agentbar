import Foundation

/// Runtime-switchable localization: strings live in en.lproj/ru.lproj inside the SwiftPM resource bundle.
enum L10n {
    nonisolated(unsafe) static var language: AppLanguage = .system

    static func string(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }

    static var locale: Locale {
        language.localeCode.map { Locale(identifier: $0) } ?? .current
    }

    /// Resolved `.lproj` code: the explicit choice, or the best match for the system languages.
    static var resolvedCode: String {
        if let code = language.localeCode { return code }
        return Bundle.preferredLocalizations(from: AppLanguage.supportedCodes, forPreferences: Locale.preferredLanguages).first ?? "en"
    }

    private static var bundle: Bundle {
        if let path = AppResources.bundle.path(forResource: resolvedCode, ofType: "lproj"), let b = Bundle(path: path) {
            return b
        }
        return AppResources.bundle
    }
}

/// Locates the SwiftPM resource bundle without relying on the generated `Bundle.module` accessor, whose search
/// paths differ between toolchains (Xcode 16 looks in the .app root, Xcode 26 in Contents/Resources).
enum AppResources {
    nonisolated(unsafe) static let bundle: Bundle = {
        let name = "AgentBar_AgentBar.bundle"
        let candidates = [
            Bundle.main.resourceURL?.appendingPathComponent(name),
            Bundle.main.bundleURL.appendingPathComponent(name),
        ]
        for url in candidates.compactMap({ $0 }) {
            if let b = Bundle(url: url) { return b }
        }
        return Bundle.module // `swift run` / tests: resolved via the build directory
    }()
}

func L(_ key: String) -> String { L10n.string(key) }
