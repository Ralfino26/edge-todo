import AppKit
import SwiftUI

@main
struct EdgeTodoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // No menu bar icon — edge panel only (background accessory).
        MenuBarExtra(isInserted: .constant(false)) {
            EmptyView()
        } label: {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = TodoStore()
    private var panelController: EdgePanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        LaunchAtLogin.enableOnFirstLaunchIfNeeded()
        panelController = EdgePanelController(store: store)
        panelController?.show()
    }

    func openTodos() {
        panelController?.openAndFocus()
    }
}
