import AppKit
import ServiceManagement

/// Starting with the user's session, through `SMAppService`.
///
/// A clipboard manager that doesn't start on its own misses everything copied
/// before it is opened by hand — which is exactly when it would have been useful.
@MainActor
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// False when the system can't see the bundle at all — an unsigned build run
    /// straight out of `.build`, for instance. Offering the switch there would
    /// promise something we cannot deliver.
    static var isAvailable: Bool {
        SMAppService.mainApp.status != .notFound
    }

    /// Returns the state the system actually ended up in, which is not always
    /// the one that was asked for: registration can fail, or land in
    /// `requiresApproval` until the user confirms in System Settings.
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("iPaste: launch at login failed — \(error.localizedDescription)")
        }
        return isEnabled
    }

    static var statusDescription: String {
        switch SMAppService.mainApp.status {
        case .enabled:          return "enabled"
        case .notRegistered:    return "disabled"
        case .requiresApproval: return "waiting for approval in System Settings"
        case .notFound:         return "bundle not found"
        @unknown default:       return "unknown"
        }
    }
}

/// Both names refer to the same thing. The onboarding code has referred to it
/// under either name, and an alias costs nothing while that settles.
typealias LaunchAtLogin = LoginItem
