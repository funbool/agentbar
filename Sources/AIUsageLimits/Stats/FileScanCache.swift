import Foundation

/// Per-file cache for JSONL scans: a file is re-parsed only when its size or mtime changes.
struct FileScanCache: Codable {
    struct Entry: Codable {
        var size: Int
        var mtime: TimeInterval
        var records: [UsageRecord]
    }
    var entries: [String: Entry] = [:]

    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("AIUsageLimits", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func load(name: String) -> FileScanCache {
        let url = directory.appendingPathComponent(name)
        guard let data = try? Data(contentsOf: url),
              let cache = try? JSONDecoder().decode(FileScanCache.self, from: data) else { return FileScanCache() }
        return cache
    }

    func save(name: String) {
        let url = Self.directory.appendingPathComponent(name)
        if let data = try? JSONEncoder().encode(self) { try? data.write(to: url, options: .atomic) }
    }

    /// Scans `files`, parsing only new/changed ones, and returns all records.
    /// `progress` receives (done, total) on the caller's thread.
    mutating func scan(
        files: [URL],
        parse: (URL) -> [UsageRecord],
        progress: ((Int, Int) -> Void)? = nil
    ) -> [UsageRecord] {
        var result: [UsageRecord] = []
        var seen = Set<String>()
        let fm = FileManager.default
        for (i, url) in files.enumerated() {
            let path = url.path
            seen.insert(path)
            let attrs = try? fm.attributesOfItem(atPath: path)
            let size = (attrs?[.size] as? NSNumber)?.intValue ?? 0
            let mtime = (attrs?[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
            if let e = entries[path], e.size == size, e.mtime == mtime {
                result += e.records
            } else {
                let records = parse(url)
                entries[path] = Entry(size: size, mtime: mtime, records: records)
                result += records
            }
            progress?(i + 1, files.count)
        }
        entries = entries.filter { seen.contains($0.key) }
        return result
    }

    static func jsonlFiles(under root: URL) -> [URL] {
        guard let e = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey],
                                                     options: [.skipsHiddenFiles]) else { return [] }
        var out: [URL] = []
        for case let url as URL in e where url.pathExtension == "jsonl" { out.append(url) }
        return out.sorted { $0.path < $1.path }
    }
}
