import AppKit
import SwiftUI

@main
struct CodexToolboxApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(appModel: appDelegate.appModel)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appModel: AppModel

    private var statusItemController: StatusItemController?

    override init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--demo-dashboard") {
            appModel = AppModel(
                usageReader: DemoUsageReader(),
                resetCreditsReader: DemoResetCreditsReader()
            )
        } else {
            appModel = AppModel()
        }
        #else
        appModel = AppModel()
        #endif
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        statusItemController = StatusItemController(appModel: appModel)
        LaunchAtLoginController.reconcileAfterRename(settings: appModel.settings)

        Task {
            await appModel.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func workspaceDidWake(_ notification: Notification) {
        Task {
            await appModel.refreshAllIfNeeded()
        }
    }
}
