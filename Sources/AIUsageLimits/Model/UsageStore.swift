import Foundation
import Observation

@MainActor
@Observable
final class UsageStore {
    private(set) var snapshots: [Provider: ProviderSnapshot] = [:]
    private(set) var errors: [Provider: ProviderError] = [:]
    private(set) var isRefreshing = false
    private(set) var lastRefresh: Date?

    let settings: Settings
    private let notifier: Notifier
    private let providers: [any UsageProvider]
    private var timer: Timer?
    private var inFlight: Task<Void, Never>?

    init(settings: Settings, notifier: Notifier, providers: [any UsageProvider] = DebugDump.allProviders) {
        self.settings = settings
        self.notifier = notifier
        self.providers = providers
    }

    var visibleProviders: [Provider] {
        Provider.allCases.filter { settings.isEnabled($0) }
    }

    /// Refreshes every enabled provider concurrently; one failing provider never hides the others.
    func refreshAll() async {
        if let inFlight { await inFlight.value; return }
        let task = Task { await self.performRefresh() }
        inFlight = task
        await task.value
        inFlight = nil
    }

    private func performRefresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        let active = providers.filter { settings.isEnabled($0.id) }
        let results = await withTaskGroup(of: (Provider, Result<ProviderSnapshot, ProviderError>).self) { group in
            for provider in active {
                group.addTask {
                    do {
                        return (provider.id, .success(try await provider.fetch()))
                    } catch let error as ProviderError {
                        return (provider.id, .failure(error))
                    } catch {
                        return (provider.id, .failure(.network(error.localizedDescription)))
                    }
                }
            }
            var collected: [(Provider, Result<ProviderSnapshot, ProviderError>)] = []
            for await r in group { collected.append(r) }
            return collected
        }
        for (provider, result) in results {
            switch result {
            case .success(let snap):
                snapshots[provider] = snap
                errors[provider] = nil
            case .failure(let error):
                errors[provider] = error
            }
        }
        lastRefresh = Date()
        if settings.notificationsEnabled {
            let fresh = results.compactMap { try? $0.1.get() }
            notifier.check(snapshots: fresh, threshold: settings.notificationThreshold)
        }
    }

    // MARK: - Scheduling

    func applySchedule() {
        timer?.invalidate()
        timer = nil
        let minutes = settings.refreshInterval.rawValue
        guard minutes > 0 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60), repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refreshAll() }
        }
        timer?.tolerance = 30
    }
}
