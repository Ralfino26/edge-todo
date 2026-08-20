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
                if SMAppService.mainApp.status == .enabled {
                    try? SMAppService.mainApp.unregister()
                }
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Edge Todo: launch at login failed: \(error.localizedDescription)")
        }
    }

    /// Enable once on first run so the app comes back after reboot.
    /// Also refreshes registration so the login item tracks the current app path.
    static func enableOnFirstLaunchIfNeeded() {
        if !UserDefaults.standard.bool(forKey: didConfigureKey) {
            UserDefaults.standard.set(true, forKey: didConfigureKey)
            setEnabled(true)
            return
        }
        if isEnabled {
            setEnabled(true)
        }
    }
}
