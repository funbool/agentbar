import AppKit
import CryptoKit
import Foundation
import Observation

/// A published GitHub release that is newer than the running app.
struct AppRelease: Equatable, Sendable {
    let version: String
    let tag: String
    let notes: String
    let pageURL: URL
    let zipURL: URL
    let sha256URL: URL?
}

enum UpdateError: Error, LocalizedError {
    case noAsset, badArchive, checksumMismatch, installFailed(String), network(String)

    var errorDescription: String? {
        switch self {
        case .noAsset: L("update.error.noAsset")
        case .badArchive: L("update.error.badArchive")
        case .checksumMismatch: L("update.error.checksum")
        case .installFailed(let m): String(format: L("update.error.install"), m)
        case .network(let m): m
        }
    }
}

/// Lightweight over-the-air updates from GitHub Releases: check, download, verify SHA-256, swap the bundle, relaunch.
@MainActor
@Observable
final class Updater {
    static let repo = "funbool/agentbar"
    static let assetName = "AgentBar.zip"
    static let checkInterval: TimeInterval = 24 * 3600

    enum Phase: Equatable { case idle, checking, downloading(Double), installing, failed(String) }

    private(set) var available: AppRelease?
    private(set) var phase: Phase = .idle
    private(set) var lastCheck: Date?
    private let defaults: UserDefaults
    private var timer: Timer?

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    var automaticChecks: Bool {
        get { defaults.object(forKey: "updateChecks") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "updateChecks"); scheduleChecks() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        lastCheck = defaults.object(forKey: "updateLastCheck") as? Date
    }

    // MARK: Scheduling

    func scheduleChecks() {
        timer?.invalidate()
        timer = nil
        guard automaticChecks, Bundle.main.bundleIdentifier != nil else { return }
        let due = (lastCheck ?? .distantPast).addingTimeInterval(Self.checkInterval)
        let delay = max(15, due.timeIntervalSinceNow)
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.check()
                self?.scheduleChecks()
            }
        }
    }

    // MARK: Check

    func check() async {
        guard phase == .idle || phase.isFailed else { return }
        phase = .checking
        defer { if phase == .checking { phase = .idle } }
        do {
            let release = try await Self.fetchLatest()
            lastCheck = Date()
            defaults.set(lastCheck, forKey: "updateLastCheck")
            available = release.flatMap { Self.isNewer($0.version, than: currentVersion) ? $0 : nil }
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    static func fetchLatest() async throws -> AppRelease? {
        let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
        let resp = try await HTTP.request(url, headers: ["Accept": "application/vnd.github+json", "User-Agent": "AgentBar"])
        if resp.status == 404 { return nil } // no releases yet
        guard (200...299).contains(resp.status) else { throw UpdateError.network("HTTP \(resp.status)") }
        return try parseRelease(resp.data)
    }

    nonisolated static func parseRelease(_ data: Data) throws -> AppRelease? {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String,
              let page = (json["html_url"] as? String).flatMap(URL.init(string:)) else { return nil }
        if (json["draft"] as? Bool) == true || (json["prerelease"] as? Bool) == true { return nil }
        let assets = json["assets"] as? [[String: Any]] ?? []
        func asset(_ name: String) -> URL? {
            assets.first { $0["name"] as? String == name }.flatMap { ($0["browser_download_url"] as? String).flatMap(URL.init(string:)) }
        }
        guard let zip = asset(assetName) else { throw UpdateError.noAsset }
        let version = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        return AppRelease(version: version, tag: tag, notes: (json["body"] as? String) ?? "", pageURL: page,
                          zipURL: zip, sha256URL: asset(assetName + ".sha256"))
    }

    /// Numeric dotted comparison: "1.2.10" > "1.2.9"; missing components count as 0.
    nonisolated static func isNewer(_ candidate: String, than current: String) -> Bool {
        func parts(_ v: String) -> [Int] { v.split(separator: ".").map { Int($0.prefix { $0.isNumber }) ?? 0 } }
        let a = parts(candidate), b = parts(current)
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0, y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }

    // MARK: Install

    func installAvailable() async {
        guard let release = available, phase == .idle || phase.isFailed else { return }
        do {
            phase = .downloading(0)
            let zip = try await download(release.zipURL) { [weak self] p in self?.phase = .downloading(p) }
            if let shaURL = release.sha256URL {
                let expected = try await HTTP.json(shaURL, headers: ["User-Agent": "AgentBar"])
                try Self.verify(zip, expectedSHA256: String(decoding: expected, as: UTF8.self))
            }
            phase = .installing
            let newApp = try await Task.detached { try Self.extract(zip) }.value
            try Self.swapAndRelaunch(newApp: newApp, expectedVersion: release.version)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    private func download(_ url: URL, progress: @escaping @MainActor (Double) -> Void) async throws -> URL {
        let (bytes, response) = try await URLSession.shared.bytes(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw UpdateError.network("download failed")
        }
        let total = Double(http.expectedContentLength)
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("AgentBar-\(UUID().uuidString).zip")
        FileManager.default.createFile(atPath: tmp.path, contents: nil)
        let handle = try FileHandle(forWritingTo: tmp)
        defer { try? handle.close() }
        var buffer = Data(); buffer.reserveCapacity(1 << 20)
        var received = 0.0
        for try await byte in bytes {
            buffer.append(byte)
            if buffer.count >= 1 << 20 {
                try handle.write(contentsOf: buffer); received += Double(buffer.count); buffer.removeAll(keepingCapacity: true)
                if total > 0 { progress(min(received / total, 1)) }
            }
        }
        try handle.write(contentsOf: buffer)
        progress(1)
        return tmp
    }

    nonisolated static func verify(_ file: URL, expectedSHA256: String) throws {
        let expected = expectedSHA256.split(whereSeparator: \.isWhitespace).first.map(String.init)?.lowercased() ?? ""
        let digest = SHA256.hash(data: try Data(contentsOf: file)).map { String(format: "%02x", $0) }.joined()
        guard digest == expected else { throw UpdateError.checksumMismatch }
    }

    /// Unzips with `ditto` (preserves the bundle's signature/resource forks) and returns the extracted .app.
    nonisolated static func extract(_ zip: URL) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("AgentBar-update-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        p.arguments = ["-x", "-k", zip.path, dir.path]
        try p.run(); p.waitUntilExit()
        guard p.terminationStatus == 0 else { throw UpdateError.badArchive }
        let apps = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil))?
            .filter { $0.pathExtension == "app" } ?? []
        guard let app = apps.first else { throw UpdateError.badArchive }
        return app
    }

    /// Replaces the running bundle with the new one and relaunches. The old bundle goes to the Trash.
    static func swapAndRelaunch(newApp: URL, expectedVersion: String) throws {
        let plist = newApp.appendingPathComponent("Contents/Info.plist")
        guard let info = NSDictionary(contentsOf: plist) as? [String: Any],
              info["CFBundleIdentifier"] as? String == Bundle.main.bundleIdentifier,
              info["CFBundleShortVersionString"] as? String == expectedVersion else { throw UpdateError.badArchive }

        let current = Bundle.main.bundleURL
        let fm = FileManager.default
        let staging = current.deletingLastPathComponent().appendingPathComponent(".AgentBar-update.app")
        try? fm.removeItem(at: staging)
        do {
            // Copy next to the destination first so the final move is atomic on the same volume.
            try fm.copyItem(at: newApp, to: staging)
            removeQuarantine(staging)
            var trashed: NSURL?
            try fm.trashItem(at: current, resultingItemURL: &trashed)
            try fm.moveItem(at: staging, to: current)
        } catch {
            try? fm.removeItem(at: staging)
            throw UpdateError.installFailed(error.localizedDescription)
        }

        // Relaunch from a detached shell so the new process starts after this one has exited.
        let script = "sleep 1; open \"\(current.path)\""
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/sh")
        p.arguments = ["-c", script]
        try p.run()
        NSApp.terminate(nil)
    }

    private static func removeQuarantine(_ url: URL) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        p.arguments = ["-dr", "com.apple.quarantine", url.path]
        try? p.run(); p.waitUntilExit()
    }
}

extension Updater.Phase {
    var isFailed: Bool { if case .failed = self { true } else { false } }
    var isBusy: Bool {
        switch self {
        case .checking, .downloading, .installing: true
        case .idle, .failed: false
        }
    }
}
