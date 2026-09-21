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
        if let path = Bundle.module.path(forResource: code, ofType: "lproj"), let b = Bundle(path: path) {
            return b
        }
        return Bundle.module
    }
}

func L(_ key: String) -> String { L10n.string(key) }
