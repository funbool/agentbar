import XCTest
@testable import AgentBar

final class UpdaterTests: XCTestCase {
    func testVersionComparison() {
        XCTAssertTrue(Updater.isNewer("0.2.0", than: "0.1.9"))
        XCTAssertTrue(Updater.isNewer("1.2.10", than: "1.2.9"))
        XCTAssertTrue(Updater.isNewer("1.0", than: "0.9.9"))
        XCTAssertFalse(Updater.isNewer("0.1.0", than: "0.1.0"))
        XCTAssertFalse(Updater.isNewer("0.1.0", than: "0.1.1"))
        XCTAssertTrue(Updater.isNewer("0.1.0", than: "0.0.0"))
    }

    func testParsesRelease() throws {
        let json = """
        {"tag_name":"v0.2.0","html_url":"https://github.com/funbool/agentbar/releases/tag/v0.2.0","body":"notes","draft":false,"prerelease":false,
         "assets":[{"name":"AgentBar.zip","browser_download_url":"https://github.com/funbool/agentbar/releases/download/v0.2.0/AgentBar.zip"},
                   {"name":"AgentBar.zip.sha256","browser_download_url":"https://github.com/funbool/agentbar/releases/download/v0.2.0/AgentBar.zip.sha256"}]}
        """
        let r = try XCTUnwrap(Updater.parseRelease(Data(json.utf8)))
        XCTAssertEqual(r.version, "0.2.0")
        XCTAssertEqual(r.zipURL.lastPathComponent, "AgentBar.zip")
        XCTAssertEqual(r.sha256URL?.lastPathComponent, "AgentBar.zip.sha256")
    }

    func testPrereleaseIgnoredAndMissingAssetThrows() throws {
        let pre = #"{"tag_name":"v9.0.0","html_url":"https://x","prerelease":true,"assets":[]}"#
        XCTAssertNil(try Updater.parseRelease(Data(pre.utf8)))
        let noAsset = #"{"tag_name":"v9.0.0","html_url":"https://x","assets":[]}"#
        XCTAssertThrowsError(try Updater.parseRelease(Data(noAsset.utf8)))
    }

    func testChecksumVerification() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("hello".utf8).write(to: file)
        let sha = "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
        XCTAssertNoThrow(try Updater.verify(file, expectedSHA256: "\(sha)  AgentBar.zip\n"))
        XCTAssertThrowsError(try Updater.verify(file, expectedSHA256: "deadbeef"))
    }
}
