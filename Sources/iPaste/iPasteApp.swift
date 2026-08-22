import AppKit
import SwiftUI
import UserNotifications

@main
struct iPasteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var app = AppState.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(app)
                .environmentObject(app.store)
                .environmentObject(app.preferences)
        } label: {
            Image(systemName: "doc.on.clipboard")
        }
        .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        MainActor.assumeIsolated {
            UNUserNotificationCenter.current().delegate = self
            // No Dock icon and no main window: this app lives in the menu bar.
            NSApp.setActivationPolicy(.accessory)
            // Capture starts here, not from the scene: the scene is only built the
            // first time the menu is drawn, and the clipboard must be watched from
            // the first second.
            AppState.shared.bootstrap()
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                if let clipID = response.notification.request.content.userInfo["clipID"] as? String {
                    AppState.shared.acknowledgeReminder(clipID: clipID)
                }
                NSApp.activate(ignoringOtherApps: true)
                AppState.shared.showQuickSearch()
            }
        }
        completionHandler()
    }

    func applicationWillTerminate(_ notification: Notification) {
        MainActor.assumeIsolated {
            AppState.shared.store.save()
            HotKeyCenter.shared.unregisterAll()
        }
    }
}
