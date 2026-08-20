import AppKit
import SwiftUI

@main
struct EdgeTodoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var openAtLogin = LaunchAtLogin.isEnabled

    var body: some Scene {
        MenuBarExtra("Edge Todo", systemImage: "checklist") {
            Button("Open panel") {
                appDelegate.openTodos()
            }
            Divider()
            Toggle("Open at Login", isOn: Binding(
                get: { openAtLogin },
                set: { newValue in
                    LaunchAtLogin.setEnabled(newValue)
                    openAtLogin = LaunchAtLogin.isEnabled
                }
            ))
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
        LaunchAtLogin.enableOnFirstLaunchIfNeeded()
        panelController = EdgePanelController(store: store)
        panelController?.show()
    }

    func openTodos() {
        panelController?.openAndFocus()
    }
}
