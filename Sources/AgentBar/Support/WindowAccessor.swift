import AppKit
import SwiftUI

/// Hands the hosting NSWindow to SwiftUI code (to close the menu bar panel, observe window close, etc.).
struct WindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow) -> Void

    final class Coordinator {
        weak var delivered: NSWindow?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { deliver(from: view, context.coordinator) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { deliver(from: nsView, context.coordinator) }
    }

    /// SwiftUI re-runs `updateNSView` on every state change — hovering a chart fires it continuously — so the
    /// callback must only run when the hosting window actually changes.
    private func deliver(from view: NSView, _ coordinator: Coordinator) {
        guard let window = view.window, coordinator.delivered !== window else { return }
        coordinator.delivered = window
        onWindow(window)
    }
}

/// Shows the app in the Dock while at least one regular window (stats, settings) is visible;
/// hides it again when the last one closes so the app stays a menu bar utility.
@MainActor
enum DockPresence {
    private static var tracked: [NSWindow] = []
    private static var observer: NSObjectProtocol?

    static func track(_ window: NSWindow) {
        // Repeatedly flipping the activation policy breaks the menu bar item, so a window is only ever
        // taken on once and the policy is changed only when it actually differs.
        guard !tracked.contains(where: { $0 === window }) else { return }
        tracked.append(window)
        if observer == nil {
            // One global observer: any window closing triggers a re-check after AppKit finished hiding it.
            observer = NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification, object: nil, queue: .main
            ) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { Task { @MainActor in update() } }
            }
        }
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private static func update() {
        tracked.removeAll { !$0.isVisible }
        guard tracked.isEmpty, NSApp.activationPolicy() != .accessory else { return }
        NSApp.setActivationPolicy(.accessory)
        // The Dock keeps the tile until the app stops being frontmost, so hand focus to the next app.
        // Never `hide(nil)` here: that hides the status item's window along with everything else.
        NSApp.deactivate()
    }
}
