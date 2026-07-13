import Combine
import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginController: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var errorMessage: String?

    var isInstalledInApplications: Bool {
        Bundle.main.bundleURL.path.hasPrefix("/Applications/")
    }

    init() {
        refreshStatus()
    }

    func setEnabled(_ enabled: Bool) {
        errorMessage = nil
        guard !enabled || isInstalledInApplications else {
            errorMessage = "请先将 Show Codex IQ 拖入“应用程序”文件夹。"
            isEnabled = false
            return
        }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            refreshStatus()
        } catch {
            refreshStatus()
            errorMessage = "无法更改开机启动设置：\(error.localizedDescription)"
        }
    }

    func refreshStatus() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}
