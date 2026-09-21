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

/// Shows the app in the Dock while at least one regular window (stats, settings) is open;
/// hides it again when the last one closes so the app stays a menu bar utility.
@MainActor
enum DockPresence {
    private static var openWindows = Set<ObjectIdentifier>()
    private static var observers: [ObjectIdentifier: NSObjectProtocol] = [:]

    static func track(_ window: NSWindow) {
        let id = ObjectIdentifier(window)
        guard !openWindows.contains(id) else { return }
        openWindows.insert(id)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        observers[id] = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification, object: window, queue: .main
        ) { _ in
            Task { @MainActor in
                openWindows.remove(id)
                if let o = observers.removeValue(forKey: id) { NotificationCenter.default.removeObserver(o) }
                if openWindows.isEmpty { NSApp.setActivationPolicy(.accessory) }
            }
        }
    }
}
