import AppKit
import SwiftUI

@main
struct EdgeTodoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Menu bar control surface; the floating edge panel is created in AppDelegate.
        MenuBarExtra("Edge Todo", systemImage: "checklist") {
            Button("Show panel") {
                appDelegate.showPanel()
            }
            Divider()
            Button("Quit Edge Todo") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = TodoStore()
    private var panelController: EdgePanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        panelController = EdgePanelController(store: store)
        panelController?.show()
    }

    func showPanel() {
        panelController?.show()
    }
}
