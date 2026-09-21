import Foundation
import ServiceManagement

enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func set(_ enabled: Bool) {
        // Only meaningful for a real .app bundle; the bare binary has no bundle identifier.
        guard Bundle.main.bundleIdentifier != nil else { return }
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("LaunchAtLogin: \(error)")
        }
    }
}
