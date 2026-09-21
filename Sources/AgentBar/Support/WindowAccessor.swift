import AppKit
import SwiftUI

/// Hands the hosting NSWindow to SwiftUI code (to close the menu bar panel, observe window close, etc.).
struct WindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { if let w = view.window { onWindow(w) } }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { if let w = nsView.window { onWindow(w) } }
    }
}

/// Shows the app in the Dock while at least one regular window (stats, settings) is visible;
/// hides it again when the last one closes so the app stays a menu bar utility.
@MainActor
enum DockPresence {
    private static var tracked: [NSWindow] = []
    private static var observer: NSObjectProtocol?

    static func track(_ window: NSWindow) {
        if !tracked.contains(where: { $0 === window }) {
            tracked.append(window)
        }
        if observer == nil {
            // One global observer: any window closing triggers a re-check after AppKit finished hiding it.
            observer = NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification, object: nil, queue: .main
            ) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { Task { @MainActor in update() } }
            }
        }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    private static func update() {
        tracked.removeAll { !$0.isVisible }
        guard tracked.isEmpty, NSApp.activationPolicy() != .accessory else { return }
        NSApp.setActivationPolicy(.accessory)
        // macOS keeps the Dock tile until the app stops being frontmost; hand focus to the next app.
        NSApp.hide(nil)
    }
}
