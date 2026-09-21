import Foundation

/// Runtime-switchable localization: strings live in en.lproj/ru.lproj inside the SwiftPM resource bundle.
enum L10n {
    nonisolated(unsafe) static var language: AppLanguage = .system

    static func string(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }

    static var locale: Locale {
        switch language {
        case .system: .current
        case .en: Locale(identifier: "en")
        case .ru: Locale(identifier: "ru")
        }
    }

    private static var bundle: Bundle {
        let code: String
        switch language {
        case .system:
            let preferred = Bundle.preferredLocalizations(from: ["en", "ru"], forPreferences: Locale.preferredLanguages)
            code = preferred.first ?? "en"
        case .en: code = "en"
        case .ru: code = "ru"
        }
        if let path = AppResources.bundle.path(forResource: code, ofType: "lproj"), let b = Bundle(path: path) {
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
