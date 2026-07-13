import SwiftUI
import ShowCodexIQCore

@main
struct ShowCodexIQApp: App {
    var body: some Scene {
        MenuBarExtra {
            VStack(spacing: 10) {
                Text("Show Codex IQ")
                    .font(.headline)
                Text("应用正在初始化…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(width: 300)
        } label: {
            Text("Codex IQ ···")
        }
        .menuBarExtraStyle(.window)

        Settings {
            Text("设置将在后续步骤中完成。")
                .padding(24)
        }
    }
}
