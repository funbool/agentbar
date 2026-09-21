import XCTest
@testable import AgentBar

/// Every localization must have exactly the English key set with matching format specifiers.
final class LocalizationTests: XCTestCase {
    private func strings(_ code: String) throws -> [String: String] {
        let url = try XCTUnwrap(AppResources.bundle.url(forResource: "Localizable", withExtension: "strings", subdirectory: "\(code).lproj"))
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String])
    }

    private func specifiers(_ s: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: "%(?:\\d\\$)?[@d]")
        return regex.matches(in: s, range: NSRange(s.startIndex..., in: s)).map { String(s[Range($0.range, in: s)!]) }.sorted()
    }

    func testAllLanguagesMatchEnglish() throws {
        let en = try strings("en")
        XCTAssertGreaterThan(en.count, 90)
        for code in AppLanguage.supportedCodes where code != "en" {
            let table = try strings(code)
            XCTAssertEqual(Set(table.keys), Set(en.keys), "key set differs for \(code)")
            for (key, value) in en {
                XCTAssertEqual(specifiers(table[key] ?? ""), specifiers(value), "format specifiers differ for \(code)/\(key)")
            }
        }
    }

    func testEveryLanguageResolvesToItsOwnBundle() {
        for lang in AppLanguage.allCases where lang != .system {
            L10n.language = lang
            XCTAssertEqual(L10n.resolvedCode, lang.rawValue)
            XCTAssertNotEqual(L("panel.refresh"), "panel.refresh", "missing table for \(lang.rawValue)")
        }
        L10n.language = .system
    }
}
