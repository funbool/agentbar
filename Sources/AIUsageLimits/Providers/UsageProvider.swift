import Foundation

protocol UsageProvider: Sendable {
    var id: Provider { get }
    func fetch() async throws -> ProviderSnapshot
}
