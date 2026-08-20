import Foundation
import ServiceManagement

enum LaunchAtLogin {
    private static let didConfigureKey = "didConfigureLaunchAtLogin"

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Edge Todo: launch at login failed: \(error.localizedDescription)")
        }
    }

    /// Enable once on first run so the app comes back after reboot.
    static func enableOnFirstLaunchIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: didConfigureKey) else { return }
        UserDefaults.standard.set(true, forKey: didConfigureKey)
        setEnabled(true)
    }
}
