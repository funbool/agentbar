import SwiftUI

@main
struct AIUsageLimitsApp: App {
    init() { DebugDump.runIfRequested() }

    var body: some Scene {
        MenuBarExtra("AI Usage Limits", systemImage: "gauge.with.dots.needle.33percent") {
            Text("Hello")
                .padding()
        }
        .menuBarExtraStyle(.window)
    }
}
