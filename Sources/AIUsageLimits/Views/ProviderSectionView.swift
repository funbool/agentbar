import SwiftUI

struct ProviderSectionView: View {
    let provider: Provider
    let snapshot: ProviderSnapshot?
    let error: ProviderError?
    let threshold: Int
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(provider.displayName)
                    .font(.headline)
                if let plan = snapshot?.plan {
                    Text(plan)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            if let error {
                Label(errorText(error), systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            if let snapshot {
                ForEach(snapshot.windows) { window in
                    WindowRowView(window: window, threshold: threshold, now: now)
                }
            } else if error == nil {
                Text(L("panel.never"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func errorText(_ error: ProviderError) -> String {
        switch error {
        case .notLoggedIn: String(format: L("error.notLoggedIn"), provider.clientName)
        case .tokenExpired: String(format: L("error.tokenExpired"), provider.clientName)
        case .rateLimited: L("error.rateLimited")
        case .network: L("error.network")
        case .badResponse: L("error.badResponse")
        }
    }
}
