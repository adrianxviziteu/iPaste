import Foundation

/// When the top shelf appears.
enum ShelfMode: String, CaseIterable, Identifiable {
    /// Stays on screen permanently.
    case always
    /// Drops down when the cursor reaches the top edge, retracts when it leaves.
    case onHover
    /// Never appears on its own — only by hand, with ⌃⌘S.
    case never

    var id: String { rawValue }

    var label: String {
        switch self {
        case .always:  return "Always open"
        case .onHover: return "On hover"
        case .never:   return "Never"
        }
    }
}

/// What clicking a clip does.
enum ClipActivation: String, CaseIterable, Identifiable {
    /// Put it on the clipboard and stop there. The user decides where it lands.
    case copy
    /// Paste it straight into whatever app was in front.
    case paste

    var id: String { rawValue }

    var label: String {
        switch self {
        case .copy:  return "Copy to clipboard"
        case .paste: return "Paste into the app"
        }
    }
}

/// The user's settings, stored in UserDefaults.
@MainActor
final class Preferences: ObservableObject {
    @Published var shelfMode: ShelfMode {
        didSet { defaults.set(shelfMode.rawValue, forKey: Key.shelfMode) }
    }

    /// How long to wait after the cursor leaves the shelf before retracting it.
    /// With no delay, the shelf vanishes as the cursor crosses between cards.
    @Published var hideDelay: TimeInterval {
        didSet { defaults.set(hideDelay, forKey: Key.hideDelay) }
    }

    /// Copying is the default deliberately: pasting types into whatever happens
    /// to hold focus, and nothing on screen says where that is until it lands.
    @Published var clickActivation: ClipActivation {
        didSet { defaults.set(clickActivation.rawValue, forKey: Key.clickActivation) }
    }

    /// Number of days to keep unpinned clips. Zero means that history never
    /// expires automatically. Pinned clips are always retained.
    @Published var historyRetentionDays: Int {
        didSet {
            historyRetentionDays = max(0, min(historyRetentionDays, 3650))
            defaults.set(historyRetentionDays, forKey: Key.historyRetentionDays)
        }
    }

    /// The first-run guide is shown once; after that, only from the menu.
    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Key.onboardingDone) }
    }

    /// Applications whose clipboard contents should never enter the history.
    /// The value is keyed by bundle ID and stores the last known display name.
    @Published var ignoredApplications: [String: String] {
        didSet { saveIgnoredApplications() }
    }

    /// Adds local semantic filters such as Email, JSON and Commands.
    @Published var smartFiltersEnabled: Bool {
        didSet { defaults.set(smartFiltersEnabled, forKey: Key.smartFiltersEnabled) }
    }

    /// Sensitive text is detected before persistence and never enters history.
    @Published var sensitiveContentProtection: Bool {
        didSet { defaults.set(sensitiveContentProtection, forKey: Key.sensitiveContentProtection) }
    }

    @Published var iCloudSyncEnabled: Bool {
        didSet { defaults.set(iCloudSyncEnabled, forKey: Key.iCloudSyncEnabled) }
    }

    private let defaults: UserDefaults

    private enum Key {
        static let shelfMode = "shelfMode"
        static let hideDelay = "shelfHideDelay"
        static let onboardingDone = "hasCompletedOnboarding"
        static let clickActivation = "clickActivation"
        static let historyRetentionDays = "historyRetentionDays"
        static let ignoredApplications = "ignoredApplications"
        static let smartFiltersEnabled = "smartFiltersEnabled"
        static let sensitiveContentProtection = "sensitiveContentProtection"
        static let iCloudSyncEnabled = "iCloudSyncEnabled"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let raw = defaults.string(forKey: Key.shelfMode)
        self.shelfMode = raw.flatMap(ShelfMode.init(rawValue:)) ?? .onHover
        let delay = defaults.double(forKey: Key.hideDelay)
        self.hideDelay = delay > 0 ? delay : 0.45
        self.hasCompletedOnboarding = defaults.bool(forKey: Key.onboardingDone)
        let activation = defaults.string(forKey: Key.clickActivation)
        self.clickActivation = activation.flatMap(ClipActivation.init(rawValue:)) ?? .copy
        let retention = defaults.integer(forKey: Key.historyRetentionDays)
        self.historyRetentionDays = max(0, min(retention, 3650))
        self.ignoredApplications = Self.loadIgnoredApplications(from: defaults)
        self.smartFiltersEnabled = defaults.object(forKey: Key.smartFiltersEnabled) as? Bool ?? true
        self.sensitiveContentProtection = defaults.object(forKey: Key.sensitiveContentProtection) as? Bool ?? true
        self.iCloudSyncEnabled = defaults.bool(forKey: Key.iCloudSyncEnabled)
    }

    func ignores(bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return ignoredApplications[bundleID] != nil
    }

    func ignoreApplication(bundleID: String, name: String?) {
        guard !bundleID.isEmpty, bundleID != Bundle.main.bundleIdentifier else { return }
        ignoredApplications[bundleID] = name ?? bundleID
    }

    func unignoreApplication(bundleID: String) {
        ignoredApplications.removeValue(forKey: bundleID)
    }

    private func saveIgnoredApplications() {
        defaults.set(ignoredApplications, forKey: Key.ignoredApplications)
    }

    private static func loadIgnoredApplications(from defaults: UserDefaults) -> [String: String] {
        if let saved = defaults.dictionary(forKey: Key.ignoredApplications) as? [String: String] {
            return saved
        }

        // These are deliberately conservative: they are password/key managers,
        // not general-purpose browsers or editors that would hide normal work.
        return [
            "com.1password.1Password": "1Password",
            "com.agilebits.onepassword4": "1Password",
            "com.bitwarden.desktop": "Bitwarden",
            "com.lastpass.LastPass": "LastPass",
            "com.dashlane.Dashlane": "Dashlane",
            "com.sinew.Enpass-Desktop": "Enpass"
        ]
    }
}
