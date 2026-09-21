import SwiftUI

@main
struct AIUsageLimitsApp: App {
    var body: some Scene {
        MenuBarExtra("AI Usage Limits", systemImage: "gauge.with.dots.needle.33percent") {
            Text("Hello")
                .padding()
        }
        .menuBarExtraStyle(.window)
    }
}
