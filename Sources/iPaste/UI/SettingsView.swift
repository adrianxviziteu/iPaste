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

                let sources = Dictionary(grouping: app.store.clips, by: { $0.sourceBundleID ?? "" })
                if !sources.isEmpty {
                    Divider()
                    Text("Per-app deletion")
                        .font(.caption.weight(.semibold))
                    ForEach(sources.keys.filter { !$0.isEmpty }.sorted(), id: \.self) { bundleID in
                        let name = sources[bundleID]?.first?.sourceAppName ?? bundleID
                        Picker(name, selection: Binding(
                            get: { preferences.retentionDaysByApplication[bundleID] ?? 0 },
                            set: { preferences.setRetention(days: $0 == 0 ? nil : $0, for: bundleID) }
                        )) {
                            Text("Global").tag(0)
                            Text("1 day").tag(1)
                            Text("7 days").tag(7)
                            Text("30 days").tag(30)
                        }
                    }
                }
            } header: {
                Text("Privacy")
            }

            Section {
                let summary = app.store.usageSummary
                Text("\(summary.totalClips) clips · \(summary.totalUses) pastes/copies")
                ForEach(summary.sources) { source in
                    HStack {
                        Text(source.name)
                        Spacer()
                        Text("\(source.clipCount) saved · \(source.uses) used")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
                Text("These statistics stay on this Mac and are never sent anywhere.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Private activity")
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
        .frame(minWidth: 520, minHeight: 450)
        .padding(.vertical, 8)
    }
}
