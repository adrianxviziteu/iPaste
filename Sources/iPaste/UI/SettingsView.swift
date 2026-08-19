import SwiftUI

/// The settings surface for behavior that should remain discoverable instead
/// of being hidden among the status-item's quick actions.
struct SettingsView: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var preferences: Preferences
    @State private var launchesAtLogin = LoginItem.isEnabled

    private var retentionEnabled: Binding<Bool> {
        Binding(
            get: { preferences.historyRetentionDays > 0 },
            set: { preferences.historyRetentionDays = $0 ? max(preferences.historyRetentionDays, 7) : 0 }
        )
    }

    private var retentionDays: Binding<Int> {
        Binding(
            get: { max(preferences.historyRetentionDays, 1) },
            set: { preferences.historyRetentionDays = max(1, min($0, 3650)) }
        )
    }

    var body: some View {
        Form {
            Section {
                Picker("Shelf", selection: $preferences.shelfMode) {
                    ForEach(ShelfMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }

                Picker("When picking a clip", selection: $preferences.clickActivation) {
                    ForEach(ClipActivation.allCases) { action in
                        Text(action.label).tag(action)
                    }
                }
            } header: {
                Text("Behavior")
            }

            Section {
                Toggle("Automatically delete old clips", isOn: retentionEnabled)
                if preferences.historyRetentionDays > 0 {
                    Stepper(value: retentionDays, in: 1...3650) {
                        HStack {
                            Text("Delete after")
                            Spacer()
                            Text("\(preferences.historyRetentionDays) days")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text("Pinned clips are kept until you delete them manually.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("History")
            }

            Section {
                Toggle("Launch iPaste at login", isOn: Binding(
                    get: { launchesAtLogin },
                    set: { enabled in
                        LoginItem.setEnabled(enabled)
                        launchesAtLogin = LoginItem.isEnabled
                    }
                ))
            } header: {
                Text("Startup")
            }

            Section {
                Toggle("Smart Auto-Filter", isOn: $preferences.smartFiltersEnabled)
                Text("Adds local filters for email, phone numbers, JSON, commands, tokens, and addresses.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Organization")
            }

            Section {
                Toggle("Sync history with iCloud", isOn: $preferences.iCloudSyncEnabled)
                ICloudSyncStatusView(service: app.iCloudSync)
            } header: {
                Text("iCloud Sync")
            }

            Section {
                Toggle("Don't save sensitive content", isOn: $preferences.sensitiveContentProtection)

                if preferences.ignoredApplications.isEmpty {
                    Text("No ignored applications")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(preferences.ignoredApplications.keys.sorted(), id: \.self) { bundleID in
                        HStack {
                            Text(preferences.ignoredApplications[bundleID] ?? bundleID)
                            Spacer()
                            Button("Remove") {
                                preferences.unignoreApplication(bundleID: bundleID)
                            }
                            .buttonStyle(.link)
                        }
                    }
                }
                Text("Passwords, private keys, access tokens, valid card numbers, and clips from ignored applications are not saved.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Privacy")
            }

            Section {
                HStack(spacing: 12) {
                    Button("Color Picker…") { app.pickColor() }
                    Button("Capture Selected Text") { app.captureSelectedText() }
                    Button("Quick Note…") { app.showQuickNotes() }
                }
            } header: {
                Text("Tools")
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 520, minHeight: 510)
        .padding(.vertical, 8)
    }
}

private struct ICloudSyncStatusView: View {
    @ObservedObject var service: ICloudSyncService

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: statusSymbol)
                .foregroundStyle(statusColor)
            Text(service.status.label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var statusSymbol: String {
        switch service.status {
        case .off:         return "icloud"
        case .connecting:  return "arrow.triangle.2.circlepath.icloud"
        case .ready:       return "checkmark.icloud"
        case .unavailable: return "exclamationmark.icloud"
        case .failed:      return "xmark.icloud"
        }
    }

    private var statusColor: Color {
        switch service.status {
        case .ready:                   return .green
        case .unavailable, .failed:    return .orange
        case .off, .connecting:        return .secondary
        }
    }
}
